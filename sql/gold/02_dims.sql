/* =====================================================================
   02_dims.sql                                                (v3)
   RUN IN : wh_gold
   PURPOSE: all dimension loads. Every proc follows one pattern:

       log Running
       BEGIN TRAN
           DELETE all rows
           INSERT the -1 Unknown member   (not for DimDate)
           INSERT ... SELECT from silver
       COMMIT
       log Succeeded  (on error: ROLLBACK, log Failed, re-throw)

   Load order matters only for DimCustomer (needs DimGeography).
   ===================================================================== */


/* ---------------------------------------------------------------------
   DimDate  (no -1 row: Power BI date tables must be contiguous)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimDate
    @RunId     VARCHAR(100) = NULL,
    @StartDate DATE         = '2005-01-01',
    @EndDate   DATE         = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimDate', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimDate;

        WITH digits AS (
            SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)
        ),
        nums AS (       -- 0..99,999 (Fabric has no recursive CTEs)
            SELECT a.n + b.n*10 + c.n*100 + d.n*1000 + e.n*10000 AS n
            FROM digits a CROSS JOIN digits b CROSS JOIN digits c
                 CROSS JOIN digits d CROSS JOIN digits e
        ),
        cal AS (        -- 1900-01-01 was a Monday -> day of week with no DATEFIRST dependency
            SELECT DATEADD(DAY, n, @StartDate) AS d,
                   (DATEDIFF(DAY, CAST('1900-01-01' AS DATE), DATEADD(DAY, n, @StartDate)) % 7) + 1 AS dow
            FROM nums
            WHERE n <= DATEDIFF(DAY, @StartDate, @EndDate)
        )
        INSERT INTO gold.DimDate
            (DateKey, [Date], DayOfMonth, DayName, DayOfWeek, MonthNumber, MonthName,
             MonthYear, YearMonth, Quarter, QuarterName, [Year],
             FiscalQuarter, FiscalYear, IsWeekend)
        SELECT
            CAST(CONVERT(VARCHAR(8), d, 112) AS INT),
            d,
            DAY(d),
            CHOOSE(dow, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
            dow,
            MONTH(d),
            CHOOSE(MONTH(d), 'January','February','March','April','May','June',
                             'July','August','September','October','November','December'),
            LEFT(CHOOSE(MONTH(d), 'January','February','March','April','May','June',
                        'July','August','September','October','November','December'), 3)
                + '-' + CAST(YEAR(d) AS VARCHAR(4)),
            YEAR(d) * 100 + MONTH(d),
            DATEPART(QUARTER, d),
            'Q' + CAST(DATEPART(QUARTER, d) AS VARCHAR(1)),
            YEAR(d),
            ((MONTH(d) + 5) % 12) / 3 + 1,
            YEAR(d) + CASE WHEN MONTH(d) >= 7 THEN 1 ELSE 0 END,
            CAST(CASE WHEN dow IN (6, 7) THEN 1 ELSE 0 END AS BIT)
        FROM cal;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimSalesTerritory
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimSalesTerritory
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimSalesTerritory', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimSalesTerritory;

        INSERT INTO gold.DimSalesTerritory
            (SalesTerritoryKey, TerritoryName, CountryRegionCode, TerritoryGroup, LoadRunId)
        VALUES (-1, 'Unknown', 'UNK', 'Unknown', @RunId);

        INSERT INTO gold.DimSalesTerritory
            (SalesTerritoryKey, TerritoryName, CountryRegionCode, TerritoryGroup, LoadRunId)
        SELECT  t.TerritoryID, t.Name, RTRIM(t.CountryRegionCode), t.[Group], @RunId
        FROM lh_silver.silver.Sales_SalesTerritory t;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimGeography  (grain: City + PostalCode + StateProvince + Country)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimGeography
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimGeography', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimGeography;

        INSERT INTO gold.DimGeography
            (GeographyKey, City, PostalCode, StateProvinceCode, StateProvinceName,
             CountryRegionCode, CountryRegionName, TerritoryName, TerritoryGroup, LoadRunId)
        VALUES (-1, 'Unknown', 'Unknown', 'UNK', 'Unknown', 'UNK', 'Unknown',
                'Unknown', 'Unknown', @RunId);

        INSERT INTO gold.DimGeography
            (GeographyKey, City, PostalCode, StateProvinceCode, StateProvinceName,
             CountryRegionCode, CountryRegionName, TerritoryName, TerritoryGroup, LoadRunId)
        SELECT  ROW_NUMBER() OVER (ORDER BY g.CountryRegionCode, g.StateProvinceCode,
                                            g.City, g.PostalCode),
                g.City, g.PostalCode, g.StateProvinceCode, g.StateProvinceName,
                g.CountryRegionCode, g.CountryRegionName, g.TerritoryName, g.TerritoryGroup,
                @RunId
        FROM (
            SELECT DISTINCT
                    a.City,
                    ISNULL(a.PostalCode, '')        AS PostalCode,
                    RTRIM(sp.StateProvinceCode)     AS StateProvinceCode,
                    sp.Name                         AS StateProvinceName,
                    RTRIM(cr.CountryRegionCode)     AS CountryRegionCode,
                    cr.Name                         AS CountryRegionName,
                    ISNULL(st.Name, 'Unknown')      AS TerritoryName,
                    ISNULL(st.[Group], 'Unknown')   AS TerritoryGroup
            FROM lh_silver.silver.Person_Address a
            JOIN lh_silver.silver.Person_StateProvince sp
              ON a.StateProvinceID = sp.StateProvinceID
            JOIN lh_silver.silver.Person_CountryRegion cr
              ON sp.CountryRegionCode = cr.CountryRegionCode
            LEFT JOIN lh_silver.silver.Sales_SalesTerritory st
              ON sp.TerritoryID = st.TerritoryID
        ) g;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimCurrency
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimCurrency
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimCurrency', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimCurrency;

        INSERT INTO gold.DimCurrency (CurrencyKey, CurrencyCode, CurrencyName, LoadRunId)
        VALUES (-1, 'UNK', 'Unknown', @RunId);

        INSERT INTO gold.DimCurrency (CurrencyKey, CurrencyCode, CurrencyName, LoadRunId)
        SELECT  ROW_NUMBER() OVER (ORDER BY RTRIM(c.CurrencyCode)),
                RTRIM(c.CurrencyCode), c.Name, @RunId
        FROM lh_silver.silver.Sales_Currency c;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimPromotion  (Sales.SpecialOffer)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimPromotion
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimPromotion', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimPromotion;

        INSERT INTO gold.DimPromotion
            (PromotionKey, PromotionName, DiscountPct, PromotionType, PromotionCategory, LoadRunId)
        VALUES (-1, 'Unknown', 0, 'Unknown', 'Unknown', @RunId);

        INSERT INTO gold.DimPromotion
            (PromotionKey, PromotionName, DiscountPct, PromotionType, PromotionCategory,
             StartDate, EndDate, MinQty, MaxQty, LoadRunId)
        SELECT  so.SpecialOfferID, so.Description, so.DiscountPct, so.Type, so.Category,
                CAST(so.StartDate AS DATE), CAST(so.EndDate AS DATE),
                so.MinQty, so.MaxQty, @RunId
        FROM lh_silver.silver.Sales_SpecialOffer so;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimShipMethod  (Purchasing.ShipMethod)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimShipMethod
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimShipMethod', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimShipMethod;

        INSERT INTO gold.DimShipMethod (ShipMethodKey, ShipMethodName, LoadRunId)
        VALUES (-1, 'Unknown', @RunId);

        INSERT INTO gold.DimShipMethod (ShipMethodKey, ShipMethodName, ShipBase, ShipRate, LoadRunId)
        SELECT  sm.ShipMethodID, sm.Name, sm.ShipBase, sm.ShipRate, @RunId
        FROM lh_silver.silver.Purchasing_ShipMethod sm;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimProduct
   ModelName is 'Unknown' until Production_ProductModel is ingested; then
   add  LEFT JOIN lh_silver.silver.Production_ProductModel pm
            ON p.ProductModelID = pm.ProductModelID
   and use ISNULL(pm.Name, 'Unknown').
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimProduct
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimProduct', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimProduct;

        INSERT INTO gold.DimProduct
            (ProductKey, ProductName, ProductNumber, Color, Size, ProductLine, Class, Style,
             ModelName, Subcategory, Category, ProductStatus, LoadRunId)
        VALUES (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown',
                'Unknown', 'Unknown', 'Unknown', 'Unknown', @RunId);

        INSERT INTO gold.DimProduct
            (ProductKey, ProductName, ProductNumber, Color, Size, ProductLine, Class, Style,
             ModelName, Subcategory, Category, StandardCost, ListPrice, IsFinishedGood,
             SellStartDate, SellEndDate, ProductStatus, LoadRunId)
        SELECT  p.ProductID,
                p.Name,
                p.ProductNumber,
                ISNULL(p.Color, 'Unknown'),
                ISNULL(RTRIM(p.Size), 'Unknown'),
                CASE RTRIM(p.ProductLine) WHEN 'R' THEN 'Road' WHEN 'M' THEN 'Mountain'
                                          WHEN 'T' THEN 'Touring' WHEN 'S' THEN 'Standard'
                                          ELSE 'Unknown' END,
                CASE RTRIM(p.Class) WHEN 'H' THEN 'High' WHEN 'M' THEN 'Medium'
                                    WHEN 'L' THEN 'Low' ELSE 'Unknown' END,
                CASE RTRIM(p.Style) WHEN 'W' THEN 'Womens' WHEN 'M' THEN 'Mens'
                                    WHEN 'U' THEN 'Universal' ELSE 'Unknown' END,
                'Unknown',
                ISNULL(ps.Name, 'Unknown'),
                ISNULL(pc.Name, 'Unknown'),
                p.StandardCost,
                p.ListPrice,
                p.FinishedGoodsFlag,
                CAST(p.SellStartDate AS DATE),
                CAST(p.SellEndDate AS DATE),
                CASE WHEN p.SellEndDate IS NULL AND p.DiscontinuedDate IS NULL
                     THEN 'Current' ELSE 'Discontinued' END,
                @RunId
        FROM lh_silver.silver.Production_Product p
        LEFT JOIN lh_silver.silver.Production_ProductSubcategory ps
               ON p.ProductSubcategoryID = ps.ProductSubcategoryID
        LEFT JOIN lh_silver.silver.Production_ProductCategory pc
               ON ps.ProductCategoryID = pc.ProductCategoryID;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimEmployee  (all employees; IsSalesPerson flags sales staff)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimEmployee
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimEmployee', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimEmployee;

        INSERT INTO gold.DimEmployee
            (EmployeeKey, FullName, JobTitle, Department, IsSalesPerson,
             IsCurrentEmployee, TerritoryName, LoadRunId)
        VALUES (-1, 'Online / No Salesperson', 'Unknown', 'Unknown', 0, 0, 'Unknown', @RunId);

        INSERT INTO gold.DimEmployee
            (EmployeeKey, FullName, JobTitle, Department, HireDate, IsSalesPerson,
             IsCurrentEmployee, TerritoryName, LoadRunId)
        SELECT  e.BusinessEntityID,
                CONCAT_WS(' ', p.FirstName, p.MiddleName, p.LastName),
                e.JobTitle,
                ISNULL(dept.DepartmentName, 'Unknown'),
                CAST(e.HireDate AS DATE),
                CASE WHEN sp.BusinessEntityID IS NOT NULL THEN 1 ELSE 0 END,
                e.CurrentFlag,
                CASE WHEN sp.BusinessEntityID IS NULL THEN 'Not Applicable'
                     ELSE ISNULL(st.Name, 'Unassigned') END,
                @RunId
        FROM lh_silver.silver.HumanResources_Employee e
        JOIN lh_silver.silver.Person_Person p
          ON e.BusinessEntityID = p.BusinessEntityID
        LEFT JOIN (     -- current department (latest open history row)
            SELECT  edh.BusinessEntityID, d.Name AS DepartmentName,
                    ROW_NUMBER() OVER (PARTITION BY edh.BusinessEntityID
                                       ORDER BY edh.StartDate DESC) AS rn
            FROM lh_silver.silver.HumanResources_EmployeeDepartmentHistory edh
            JOIN lh_silver.silver.HumanResources_Department d
              ON edh.DepartmentID = d.DepartmentID
            WHERE edh.EndDate IS NULL
        ) dept ON dept.BusinessEntityID = e.BusinessEntityID AND dept.rn = 1
        LEFT JOIN lh_silver.silver.Sales_SalesPerson sp
               ON sp.BusinessEntityID = e.BusinessEntityID
        LEFT JOIN lh_silver.silver.Sales_SalesTerritory st
               ON sp.TerritoryID = st.TerritoryID;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO


/* ---------------------------------------------------------------------
   DimCustomer  (run after DimGeography)
     Individual : CustomerName = person,  ContactName = NULL
     Store      : CustomerName = store,   ContactName = contact person
   One email and one address per customer
   (address priority: Home > Main Office > Primary > other).
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_DimCustomer
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimCustomer', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimCustomer;

        INSERT INTO gold.DimCustomer
            (CustomerKey, AccountNumber, CustomerType, CustomerName, GeographyKey, LoadRunId)
        VALUES (-1, 'Unknown', 'Unknown', 'Unknown', -1, @RunId);

        INSERT INTO gold.DimCustomer
            (CustomerKey, AccountNumber, CustomerType, CustomerName, ContactName,
             EmailAddress, AddressLine1, City, StateProvinceName, CountryRegionName,
             PostalCode, GeographyKey, LoadRunId)
        SELECT  c.CustomerID,
                c.AccountNumber,
                CASE WHEN c.StoreID  IS NOT NULL THEN 'Store'
                     WHEN c.PersonID IS NOT NULL THEN 'Individual'
                     ELSE 'Unknown' END,
                COALESCE(CASE WHEN c.StoreID IS NOT NULL THEN st.Name END,
                         NULLIF(CONCAT_WS(' ', p.FirstName, p.MiddleName, p.LastName), ''),
                         'Unknown'),
                CASE WHEN c.StoreID IS NOT NULL
                     THEN NULLIF(CONCAT_WS(' ', p.FirstName, p.MiddleName, p.LastName), '') END,
                em.EmailAddress,
                adr.AddressLine1,
                adr.City,
                adr.StateProvinceName,
                adr.CountryRegionName,
                adr.PostalCode,
                ISNULL(g.GeographyKey, -1),
                @RunId
        FROM lh_silver.silver.Sales_Customer c
        LEFT JOIN lh_silver.silver.Person_Person p
               ON c.PersonID = p.BusinessEntityID
        LEFT JOIN lh_silver.silver.Sales_Store st
               ON c.StoreID = st.BusinessEntityID
        LEFT JOIN (
            SELECT BusinessEntityID, EmailAddress,
                   ROW_NUMBER() OVER (PARTITION BY BusinessEntityID ORDER BY EmailAddressID) AS rn
            FROM lh_silver.silver.Person_EmailAddress
        ) em ON em.BusinessEntityID = c.PersonID AND em.rn = 1
        LEFT JOIN (
            SELECT  bea.BusinessEntityID,
                    a.AddressLine1,
                    a.City,
                    ISNULL(a.PostalCode, '')     AS PostalCode,
                    RTRIM(sp.StateProvinceCode)  AS StateProvinceCode,
                    sp.Name                      AS StateProvinceName,
                    RTRIM(cr.CountryRegionCode)  AS CountryRegionCode,
                    cr.Name                      AS CountryRegionName,
                    ROW_NUMBER() OVER (
                        PARTITION BY bea.BusinessEntityID
                        ORDER BY CASE at.Name WHEN 'Home' THEN 1 WHEN 'Main Office' THEN 2
                                              WHEN 'Primary' THEN 3 ELSE 4 END,
                                 a.AddressID) AS rn
            FROM lh_silver.silver.Person_BusinessEntityAddress bea
            JOIN lh_silver.silver.Person_Address a       ON bea.AddressID = a.AddressID
            JOIN lh_silver.silver.Person_AddressType at  ON bea.AddressTypeID = at.AddressTypeID
            JOIN lh_silver.silver.Person_StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
            JOIN lh_silver.silver.Person_CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
        ) adr ON adr.BusinessEntityID = COALESCE(c.StoreID, c.PersonID) AND adr.rn = 1
        LEFT JOIN gold.DimGeography g
               ON  g.City              = adr.City
               AND g.PostalCode        = adr.PostalCode
               AND g.StateProvinceCode = adr.StateProvinceCode
               AND g.CountryRegionCode = adr.CountryRegionCode;
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;
GO

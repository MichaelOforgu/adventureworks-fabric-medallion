/* =====================================================================
   03_facts.sql                                               (v3)
   RUN IN : wh_gold  - after all dimensions
   PURPOSE: FactSales (order line), FactSalesOrder (order header),
            FactSalesQuota. Full rebuild each run, same pattern as dims.

   Every dimension key falls back to -1 if the lookup fails, so no fact
   row is ever dropped. Date keys stay NULL when the date is missing.
   ===================================================================== */


/* ---------------------------------------------------------------------
   FactSales  (grain: one row per sales order line)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_FactSales
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.FactSales', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.FactSales;

        INSERT INTO gold.FactSales
            (SalesOrderID, SalesOrderDetailID, SalesOrderNumber,
             OrderDateKey, DueDateKey, ShipDateKey,
             CustomerKey, ProductKey, PromotionKey, SalesTerritoryKey, EmployeeKey,
             ShipMethodKey, CurrencyKey, ShipToGeographyKey, OnlineOrderFlag, SalesChannel,
             OrderQty, UnitPrice, UnitPriceDiscount, DiscountAmount, LineTotal,
             UnitCost, TotalProductCost, GrossMargin, LoadRunId)
        SELECT
            x.SalesOrderID,
            x.SalesOrderDetailID,
            x.SalesOrderNumber,
            CAST(CONVERT(VARCHAR(8), x.OrderDate, 112) AS INT),
            CAST(CONVERT(VARCHAR(8), x.DueDate,   112) AS INT),
            CAST(CONVERT(VARCHAR(8), x.ShipDate,  112) AS INT),
            ISNULL(dc.CustomerKey, -1),
            ISNULL(dp.ProductKey, -1),
            ISNULL(dpr.PromotionKey, -1),
            ISNULL(dt.SalesTerritoryKey, -1),
            ISNULL(de.EmployeeKey, -1),
            ISNULL(dsm.ShipMethodKey, -1),
            ISNULL(dcu.CurrencyKey, -1),
            ISNULL(dg.GeographyKey, -1),
            x.OnlineOrderFlag,
            CASE WHEN x.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Reseller' END,
            x.OrderQty,
            x.UnitPrice,
            x.UnitPriceDiscount,
            x.OrderQty * x.UnitPrice * x.UnitPriceDiscount,
            x.LineTotal,
            x.UnitCost,
            x.OrderQty * x.UnitCost,
            x.LineTotal - x.OrderQty * x.UnitCost,
            @RunId
        FROM (
            SELECT  d.SalesOrderID, d.SalesOrderDetailID, h.SalesOrderNumber,
                    h.OrderDate, h.DueDate, h.ShipDate,
                    h.CustomerID, d.ProductID, d.SpecialOfferID,
                    h.TerritoryID, h.SalesPersonID, h.ShipMethodID,
                    ISNULL(RTRIM(cr.ToCurrencyCode), 'USD')         AS CurrencyCode,
                    a.City                                          AS ShipCity,
                    ISNULL(a.PostalCode, '')                        AS ShipPostalCode,
                    RTRIM(sp.StateProvinceCode)                     AS ShipStateCode,
                    RTRIM(sp.CountryRegionCode)                     AS ShipCountryCode,
                    h.OnlineOrderFlag,
                    d.OrderQty, d.UnitPrice, d.UnitPriceDiscount, d.LineTotal,
                    COALESCE(pch.StandardCost, p.StandardCost, 0)   AS UnitCost,
                    ROW_NUMBER() OVER (PARTITION BY d.SalesOrderDetailID
                                       ORDER BY pch.StartDate DESC) AS rn
            FROM lh_silver.silver.Sales_SalesOrderDetail d
            JOIN lh_silver.silver.Sales_SalesOrderHeader h
              ON h.SalesOrderID = d.SalesOrderID
            LEFT JOIN lh_silver.silver.Sales_CurrencyRate cr
              ON cr.CurrencyRateID = h.CurrencyRateID
            LEFT JOIN lh_silver.silver.Person_Address a
              ON a.AddressID = h.ShipToAddressID
            LEFT JOIN lh_silver.silver.Person_StateProvince sp
              ON sp.StateProvinceID = a.StateProvinceID
            LEFT JOIN lh_silver.silver.Production_Product p
              ON p.ProductID = d.ProductID
            LEFT JOIN lh_silver.silver.Production_ProductCostHistory pch
              ON  pch.ProductID = d.ProductID
              AND h.OrderDate >= pch.StartDate
              AND (pch.EndDate IS NULL OR h.OrderDate < DATEADD(DAY, 1, pch.EndDate))
        ) x
        LEFT JOIN gold.DimCustomer       dc  ON dc.CustomerKey       = x.CustomerID
        LEFT JOIN gold.DimProduct        dp  ON dp.ProductKey        = x.ProductID
        LEFT JOIN gold.DimPromotion      dpr ON dpr.PromotionKey     = x.SpecialOfferID
        LEFT JOIN gold.DimSalesTerritory dt  ON dt.SalesTerritoryKey = x.TerritoryID
        LEFT JOIN gold.DimEmployee       de  ON de.EmployeeKey       = x.SalesPersonID
        LEFT JOIN gold.DimShipMethod     dsm ON dsm.ShipMethodKey    = x.ShipMethodID
        LEFT JOIN gold.DimCurrency       dcu ON dcu.CurrencyCode     = x.CurrencyCode
        LEFT JOIN gold.DimGeography      dg
               ON  dg.City              = x.ShipCity
               AND dg.PostalCode        = x.ShipPostalCode
               AND dg.StateProvinceCode = x.ShipStateCode
               AND dg.CountryRegionCode = x.ShipCountryCode
        WHERE x.rn = 1;
        SET @rows = @@ROWCOUNT;

        -- Grain check: one row per order line (rolls back the load if broken)
        IF EXISTS (SELECT 1 FROM gold.FactSales GROUP BY SalesOrderDetailID HAVING COUNT(*) > 1)
        BEGIN
            THROW 50011, 'gold.FactSales: duplicate SalesOrderDetailID.', 1;
        END;

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
   FactSalesOrder  (grain: one row per sales order header)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_FactSalesOrder
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.FactSalesOrder', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.FactSalesOrder;

        INSERT INTO gold.FactSalesOrder
            (SalesOrderID, SalesOrderNumber, OrderDateKey, DueDateKey, ShipDateKey,
             CustomerKey, SalesTerritoryKey, EmployeeKey, ShipMethodKey, CurrencyKey,
             ShipToGeographyKey, OnlineOrderFlag, SalesChannel, OrderStatusName, OrderLineCount,
             SubTotal, TaxAmt, Freight, TotalDue, DaysToShip, IsLateShipment, LoadRunId)
        SELECT
            h.SalesOrderID,
            h.SalesOrderNumber,
            CAST(CONVERT(VARCHAR(8), h.OrderDate, 112) AS INT),
            CAST(CONVERT(VARCHAR(8), h.DueDate,   112) AS INT),
            CAST(CONVERT(VARCHAR(8), h.ShipDate,  112) AS INT),
            ISNULL(dc.CustomerKey, -1),
            ISNULL(dt.SalesTerritoryKey, -1),
            ISNULL(de.EmployeeKey, -1),
            ISNULL(dsm.ShipMethodKey, -1),
            ISNULL(dcu.CurrencyKey, -1),
            ISNULL(dg.GeographyKey, -1),
            h.OnlineOrderFlag,
            CASE WHEN h.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Reseller' END,
            CASE h.Status WHEN 1 THEN 'In Process' WHEN 2 THEN 'Approved'
                          WHEN 3 THEN 'Backordered' WHEN 4 THEN 'Rejected'
                          WHEN 5 THEN 'Shipped' WHEN 6 THEN 'Cancelled'
                          ELSE 'Unknown' END,
            ISNULL(lc.LineCount, 0),
            h.SubTotal,
            h.TaxAmt,
            h.Freight,
            h.TotalDue,
            DATEDIFF(DAY, h.OrderDate, h.ShipDate),
            CASE WHEN h.ShipDate > h.DueDate THEN 1 ELSE 0 END,
            @RunId
        FROM lh_silver.silver.Sales_SalesOrderHeader h
        LEFT JOIN (
            SELECT SalesOrderID, COUNT(*) AS LineCount
            FROM lh_silver.silver.Sales_SalesOrderDetail
            GROUP BY SalesOrderID
        ) lc ON lc.SalesOrderID = h.SalesOrderID
        LEFT JOIN lh_silver.silver.Sales_CurrencyRate cr
               ON cr.CurrencyRateID = h.CurrencyRateID
        LEFT JOIN lh_silver.silver.Person_Address a
               ON a.AddressID = h.ShipToAddressID
        LEFT JOIN lh_silver.silver.Person_StateProvince sp
               ON sp.StateProvinceID = a.StateProvinceID
        LEFT JOIN gold.DimCustomer       dc  ON dc.CustomerKey       = h.CustomerID
        LEFT JOIN gold.DimSalesTerritory dt  ON dt.SalesTerritoryKey = h.TerritoryID
        LEFT JOIN gold.DimEmployee       de  ON de.EmployeeKey       = h.SalesPersonID
        LEFT JOIN gold.DimShipMethod     dsm ON dsm.ShipMethodKey    = h.ShipMethodID
        LEFT JOIN gold.DimCurrency       dcu ON dcu.CurrencyCode     = ISNULL(RTRIM(cr.ToCurrencyCode), 'USD')
        LEFT JOIN gold.DimGeography      dg
               ON  dg.City              = a.City
               AND dg.PostalCode        = ISNULL(a.PostalCode, '')
               AND dg.StateProvinceCode = RTRIM(sp.StateProvinceCode)
               AND dg.CountryRegionCode = RTRIM(sp.CountryRegionCode);
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
   FactSalesQuota  (grain: salesperson x quota date)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE gold.usp_Load_FactSalesQuota
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.FactSalesQuota', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.FactSalesQuota;

        INSERT INTO gold.FactSalesQuota
            (EmployeeKey, QuotaDateKey, SalesTerritoryKey, SalesQuota, LoadRunId)
        SELECT  ISNULL(de.EmployeeKey, -1),
                CAST(CONVERT(VARCHAR(8), q.QuotaDate, 112) AS INT),
                ISNULL(dt.SalesTerritoryKey, -1),
                q.SalesQuota,
                @RunId
        FROM lh_silver.silver.Sales_SalesPersonQuotaHistory q
        LEFT JOIN lh_silver.silver.Sales_SalesPerson sp
               ON sp.BusinessEntityID = q.BusinessEntityID
        LEFT JOIN gold.DimEmployee de
               ON de.EmployeeKey = q.BusinessEntityID
        LEFT JOIN gold.DimSalesTerritory dt
               ON dt.SalesTerritoryKey = sp.TerritoryID;
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

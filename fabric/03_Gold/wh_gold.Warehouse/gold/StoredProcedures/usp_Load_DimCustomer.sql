/* ---------------------------------------------------------------------
   DimCustomer  (run after DimGeography)
     Individual : CustomerName = person,  ContactName = NULL
     Store      : CustomerName = store,   ContactName = contact person
   One email and one address per customer
   (address priority: Home > Main Office > Primary > other).
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimCustomer
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
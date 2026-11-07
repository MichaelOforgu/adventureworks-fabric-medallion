/* ---------------------------------------------------------------------
   DimGeography  (grain: City + PostalCode + StateProvince + Country)
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimGeography
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
/* ---------------------------------------------------------------------
   DimSalesTerritory
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimSalesTerritory
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
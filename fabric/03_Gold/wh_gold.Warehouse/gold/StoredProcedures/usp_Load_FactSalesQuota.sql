/* ---------------------------------------------------------------------
   FactSalesQuota  (grain: salesperson x quota date)
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_FactSalesQuota
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
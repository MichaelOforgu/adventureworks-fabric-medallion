/* ---------------------------------------------------------------------
   DimCurrency
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimCurrency
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
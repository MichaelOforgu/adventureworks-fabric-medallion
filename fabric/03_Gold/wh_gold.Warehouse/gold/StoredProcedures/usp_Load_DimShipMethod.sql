/* ---------------------------------------------------------------------
   DimShipMethod  (Purchasing.ShipMethod)
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimShipMethod
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
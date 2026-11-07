/* ---------------------------------------------------------------------
   DimPromotion  (Sales.SpecialOffer)
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimPromotion
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
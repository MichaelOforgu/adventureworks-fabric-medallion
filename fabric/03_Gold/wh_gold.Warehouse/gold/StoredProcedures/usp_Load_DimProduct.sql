/* ---------------------------------------------------------------------
   DimProduct
   ModelName is 'Unknown' until Production_ProductModel is ingested; then
   add  LEFT JOIN lh_silver.silver.Production_ProductModel pm
            ON p.ProductModelID = pm.ProductModelID
   and use ISNULL(pm.Name, 'Unknown').
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimProduct
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
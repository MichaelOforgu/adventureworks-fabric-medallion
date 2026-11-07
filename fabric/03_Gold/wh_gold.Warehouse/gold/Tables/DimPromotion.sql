CREATE TABLE [gold].[DimPromotion] (
    [PromotionKey]      INT             NOT NULL,
    [PromotionName]     VARCHAR (510)   NULL,
    [DiscountPct]       DECIMAL (19, 4) NULL,
    [PromotionType]     VARCHAR (100)   NULL,
    [PromotionCategory] VARCHAR (100)   NULL,
    [StartDate]         DATE            NULL,
    [EndDate]           DATE            NULL,
    [MinQty]            INT             NULL,
    [MaxQty]            INT             NULL,
    [LoadRunId]         VARCHAR (100)   NULL
);


GO
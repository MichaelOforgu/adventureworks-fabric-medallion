CREATE TABLE [gold].[DimProduct] (
    [ProductKey]     INT             NOT NULL,
    [ProductName]    VARCHAR (100)   NULL,
    [ProductNumber]  VARCHAR (50)    NULL,
    [Color]          VARCHAR (30)    NULL,
    [Size]           VARCHAR (10)    NULL,
    [ProductLine]    VARCHAR (20)    NULL,
    [Class]          VARCHAR (20)    NULL,
    [Style]          VARCHAR (20)    NULL,
    [ModelName]      VARCHAR (100)   NULL,
    [Subcategory]    VARCHAR (100)   NULL,
    [Category]       VARCHAR (100)   NULL,
    [StandardCost]   DECIMAL (19, 4) NULL,
    [ListPrice]      DECIMAL (19, 4) NULL,
    [IsFinishedGood] BIT             NULL,
    [SellStartDate]  DATE            NULL,
    [SellEndDate]    DATE            NULL,
    [ProductStatus]  VARCHAR (20)    NULL,
    [LoadRunId]      VARCHAR (100)   NULL
);


GO
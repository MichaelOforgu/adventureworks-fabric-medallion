CREATE TABLE [gold].[DimSalesTerritory] (
    [SalesTerritoryKey] INT           NOT NULL,
    [TerritoryName]     VARCHAR (100) NULL,
    [CountryRegionCode] VARCHAR (6)   NULL,
    [TerritoryGroup]    VARCHAR (100) NULL,
    [LoadRunId]         VARCHAR (100) NULL
);


GO
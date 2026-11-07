CREATE TABLE [gold].[DimGeography] (
    [GeographyKey]      INT           NOT NULL,
    [City]              VARCHAR (100) NULL,
    [PostalCode]        VARCHAR (30)  NULL,
    [StateProvinceCode] VARCHAR (6)   NULL,
    [StateProvinceName] VARCHAR (100) NULL,
    [CountryRegionCode] VARCHAR (6)   NULL,
    [CountryRegionName] VARCHAR (100) NULL,
    [TerritoryName]     VARCHAR (100) NULL,
    [TerritoryGroup]    VARCHAR (100) NULL,
    [LoadRunId]         VARCHAR (100) NULL
);


GO
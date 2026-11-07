CREATE TABLE [gold].[DimCustomer] (
    [CustomerKey]       INT           NOT NULL,
    [AccountNumber]     VARCHAR (20)  NULL,
    [CustomerType]      VARCHAR (20)  NULL,
    [CustomerName]      VARCHAR (250) NULL,
    [ContactName]       VARCHAR (250) NULL,
    [EmailAddress]      VARCHAR (200) NULL,
    [AddressLine1]      VARCHAR (200) NULL,
    [City]              VARCHAR (100) NULL,
    [StateProvinceName] VARCHAR (100) NULL,
    [CountryRegionName] VARCHAR (100) NULL,
    [PostalCode]        VARCHAR (30)  NULL,
    [GeographyKey]      INT           NULL,
    [LoadRunId]         VARCHAR (100) NULL
);


GO
CREATE TABLE [gold].[DimCurrency] (
    [CurrencyKey]  INT           NOT NULL,
    [CurrencyCode] VARCHAR (3)   NULL,
    [CurrencyName] VARCHAR (100) NULL,
    [LoadRunId]    VARCHAR (100) NULL
);


GO
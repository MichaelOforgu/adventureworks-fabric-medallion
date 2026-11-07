CREATE TABLE [gold].[FactSalesQuota] (
    [EmployeeKey]       INT             NOT NULL,
    [QuotaDateKey]      INT             NOT NULL,
    [SalesTerritoryKey] INT             NULL,
    [SalesQuota]        DECIMAL (19, 4) NULL,
    [LoadRunId]         VARCHAR (100)   NULL
);


GO
CREATE   VIEW dbo.[Sales_SalesPersonQuotaHistory] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([QuotaDate] AS datetime2(6)) AS [QuotaDate], CAST([SalesQuota] AS money) AS [SalesQuota], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_SalesPersonQuotaHistory];

GO
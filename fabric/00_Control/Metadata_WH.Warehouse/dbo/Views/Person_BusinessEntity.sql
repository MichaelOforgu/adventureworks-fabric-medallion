CREATE   VIEW dbo.[Person_BusinessEntity] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_BusinessEntity];

GO
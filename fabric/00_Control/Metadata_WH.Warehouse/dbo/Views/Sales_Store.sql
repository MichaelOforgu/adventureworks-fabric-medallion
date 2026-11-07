CREATE   VIEW dbo.[Sales_Store] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([SalesPersonID] AS int) AS [SalesPersonID], CAST([Demographics] AS VARCHAR(MAX)) AS [Demographics], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_Store];

GO
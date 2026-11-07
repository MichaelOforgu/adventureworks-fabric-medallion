CREATE   VIEW dbo.[Person_BusinessEntityContact] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([PersonID] AS int) AS [PersonID], CAST([ContactTypeID] AS int) AS [ContactTypeID], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_BusinessEntityContact];

GO
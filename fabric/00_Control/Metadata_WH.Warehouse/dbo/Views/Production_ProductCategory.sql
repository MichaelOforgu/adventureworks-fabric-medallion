CREATE   VIEW dbo.[Production_ProductCategory] AS SELECT CAST([ProductCategoryID] AS int) AS [ProductCategoryID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ProductCategory];

GO
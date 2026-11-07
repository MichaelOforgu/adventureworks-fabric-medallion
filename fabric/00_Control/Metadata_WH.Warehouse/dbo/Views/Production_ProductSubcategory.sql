CREATE   VIEW dbo.[Production_ProductSubcategory] AS SELECT CAST([ProductSubcategoryID] AS int) AS [ProductSubcategoryID], CAST([ProductCategoryID] AS int) AS [ProductCategoryID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ProductSubcategory];

GO
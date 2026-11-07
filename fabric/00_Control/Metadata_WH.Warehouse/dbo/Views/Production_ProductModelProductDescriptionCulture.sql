CREATE   VIEW dbo.[Production_ProductModelProductDescriptionCulture] AS SELECT CAST([ProductModelID] AS int) AS [ProductModelID], CAST([ProductDescriptionID] AS int) AS [ProductDescriptionID], CAST([CultureID] AS nchar(6)) AS [CultureID], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ProductModelProductDescriptionCulture];

GO
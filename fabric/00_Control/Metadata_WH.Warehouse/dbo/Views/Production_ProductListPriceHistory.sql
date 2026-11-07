CREATE   VIEW dbo.[Production_ProductListPriceHistory] AS SELECT CAST([ProductID] AS int) AS [ProductID], CAST([StartDate] AS datetime2(6)) AS [StartDate], CAST([EndDate] AS datetime2(6)) AS [EndDate], CAST([ListPrice] AS money) AS [ListPrice], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ProductListPriceHistory];

GO
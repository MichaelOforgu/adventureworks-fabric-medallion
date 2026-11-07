CREATE   VIEW dbo.[Production_ProductModelIllustration] AS SELECT CAST([ProductModelID] AS int) AS [ProductModelID], CAST([IllustrationID] AS int) AS [IllustrationID], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ProductModelIllustration];

GO
CREATE   VIEW dbo.[Production_ScrapReason] AS SELECT CAST([ScrapReasonID] AS smallint) AS [ScrapReasonID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ScrapReason];

GO
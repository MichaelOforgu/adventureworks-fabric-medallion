CREATE   VIEW dbo.[Sales_SalesReason] AS SELECT CAST([SalesReasonID] AS int) AS [SalesReasonID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ReasonType] AS VARCHAR(50)) AS [ReasonType], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_SalesReason];

GO
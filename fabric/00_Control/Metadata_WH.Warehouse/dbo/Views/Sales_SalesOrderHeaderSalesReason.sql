CREATE   VIEW dbo.[Sales_SalesOrderHeaderSalesReason] AS SELECT CAST([SalesOrderID] AS int) AS [SalesOrderID], CAST([SalesReasonID] AS int) AS [SalesReasonID], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_SalesOrderHeaderSalesReason];

GO
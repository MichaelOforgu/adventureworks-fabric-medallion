CREATE   VIEW dbo.[Production_ProductDescription] AS SELECT CAST([ProductDescriptionID] AS int) AS [ProductDescriptionID], CAST([Description] AS VARCHAR(400)) AS [Description], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ProductDescription];

GO
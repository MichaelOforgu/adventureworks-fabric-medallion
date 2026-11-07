CREATE   VIEW dbo.[Production_ProductProductPhoto] AS SELECT CAST([ProductID] AS int) AS [ProductID], CAST([ProductPhotoID] AS int) AS [ProductPhotoID], CAST([Primary] AS bit) AS [Primary], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_ProductProductPhoto];

GO
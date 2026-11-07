CREATE   VIEW dbo.[Production_Culture] AS SELECT CAST([CultureID] AS nchar(6)) AS [CultureID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_Culture];

GO
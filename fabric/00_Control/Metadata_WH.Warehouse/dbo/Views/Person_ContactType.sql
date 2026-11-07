CREATE   VIEW dbo.[Person_ContactType] AS SELECT CAST([ContactTypeID] AS int) AS [ContactTypeID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_ContactType];

GO
CREATE   VIEW dbo.[Sales_Currency] AS SELECT CAST([CurrencyCode] AS nchar(3)) AS [CurrencyCode], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_Currency];

GO
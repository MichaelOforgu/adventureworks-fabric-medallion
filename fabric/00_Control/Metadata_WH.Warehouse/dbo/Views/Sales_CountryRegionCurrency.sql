CREATE   VIEW dbo.[Sales_CountryRegionCurrency] AS SELECT CAST([CountryRegionCode] AS VARCHAR(3)) AS [CountryRegionCode], CAST([CurrencyCode] AS nchar(3)) AS [CurrencyCode], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_CountryRegionCurrency];

GO
CREATE   VIEW dbo.[Person_CountryRegion] AS SELECT CAST([CountryRegionCode] AS VARCHAR(3)) AS [CountryRegionCode], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_CountryRegion];

GO
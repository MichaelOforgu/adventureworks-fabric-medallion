CREATE   VIEW dbo.[Production_Location] AS SELECT CAST([LocationID] AS smallint) AS [LocationID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([CostRate] AS smallmoney) AS [CostRate], CAST([Availability] AS decimal(8,2)) AS [Availability], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_Location];

GO
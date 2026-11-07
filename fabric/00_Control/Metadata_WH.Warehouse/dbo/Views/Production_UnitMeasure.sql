CREATE   VIEW dbo.[Production_UnitMeasure] AS SELECT CAST([UnitMeasureCode] AS nchar(3)) AS [UnitMeasureCode], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Production_UnitMeasure];

GO
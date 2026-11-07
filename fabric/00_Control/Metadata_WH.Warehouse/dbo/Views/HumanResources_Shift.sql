CREATE   VIEW dbo.[HumanResources_Shift] AS SELECT CAST([ShiftID] AS tinyint) AS [ShiftID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([StartTime] AS time) AS [StartTime], CAST([EndTime] AS time) AS [EndTime], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[HumanResources_Shift];

GO
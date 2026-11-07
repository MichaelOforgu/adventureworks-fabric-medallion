CREATE   VIEW dbo.[HumanResources_Department] AS SELECT CAST([DepartmentID] AS smallint) AS [DepartmentID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([GroupName] AS VARCHAR(50)) AS [GroupName], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[HumanResources_Department];

GO
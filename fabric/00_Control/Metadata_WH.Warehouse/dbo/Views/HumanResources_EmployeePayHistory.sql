CREATE   VIEW dbo.[HumanResources_EmployeePayHistory] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([RateChangeDate] AS datetime2(6)) AS [RateChangeDate], CAST([Rate] AS money) AS [Rate], CAST([PayFrequency] AS tinyint) AS [PayFrequency], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[HumanResources_EmployeePayHistory];

GO
CREATE   VIEW dbo.[HumanResources_JobCandidate] AS SELECT CAST([JobCandidateID] AS int) AS [JobCandidateID], CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([Resume] AS VARCHAR(MAX)) AS [Resume], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[HumanResources_JobCandidate];

GO
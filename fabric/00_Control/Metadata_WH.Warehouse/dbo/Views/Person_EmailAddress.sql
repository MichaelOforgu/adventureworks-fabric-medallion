CREATE   VIEW dbo.[Person_EmailAddress] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([EmailAddressID] AS int) AS [EmailAddressID], CAST([EmailAddress] AS VARCHAR(50)) AS [EmailAddress], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_EmailAddress];

GO
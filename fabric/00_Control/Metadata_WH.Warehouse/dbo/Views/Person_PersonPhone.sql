CREATE   VIEW dbo.[Person_PersonPhone] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([PhoneNumber] AS VARCHAR(25)) AS [PhoneNumber], CAST([PhoneNumberTypeID] AS int) AS [PhoneNumberTypeID], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_PersonPhone];

GO
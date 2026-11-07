CREATE   VIEW dbo.[Person_PhoneNumberType] AS SELECT CAST([PhoneNumberTypeID] AS int) AS [PhoneNumberTypeID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_PhoneNumberType];

GO
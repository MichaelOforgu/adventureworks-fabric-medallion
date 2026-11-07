CREATE   VIEW dbo.[Person_AddressType] AS SELECT CAST([AddressTypeID] AS int) AS [AddressTypeID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_AddressType];

GO
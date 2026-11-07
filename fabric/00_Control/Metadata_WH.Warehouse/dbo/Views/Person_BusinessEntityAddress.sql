CREATE   VIEW dbo.[Person_BusinessEntityAddress] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([AddressID] AS int) AS [AddressID], CAST([AddressTypeID] AS int) AS [AddressTypeID], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_BusinessEntityAddress];

GO
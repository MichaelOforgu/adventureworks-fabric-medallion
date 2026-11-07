CREATE   VIEW dbo.[Person_Password] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([PasswordHash] AS varchar(128)) AS [PasswordHash], CAST([PasswordSalt] AS varchar(10)) AS [PasswordSalt], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Person_Password];

GO
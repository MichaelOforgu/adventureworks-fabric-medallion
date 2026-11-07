CREATE   VIEW dbo.[Purchasing_ShipMethod] AS SELECT CAST([ShipMethodID] AS int) AS [ShipMethodID], CAST([Name] AS VARCHAR(50)) AS [Name], CAST([ShipBase] AS money) AS [ShipBase], CAST([ShipRate] AS money) AS [ShipRate], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Purchasing_ShipMethod];

GO
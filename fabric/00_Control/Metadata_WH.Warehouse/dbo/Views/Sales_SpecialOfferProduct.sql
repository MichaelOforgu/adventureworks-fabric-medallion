CREATE   VIEW dbo.[Sales_SpecialOfferProduct] AS SELECT CAST([SpecialOfferID] AS int) AS [SpecialOfferID], CAST([ProductID] AS int) AS [ProductID], CAST([rowguid] AS uniqueidentifier) AS [rowguid], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_SpecialOfferProduct];

GO
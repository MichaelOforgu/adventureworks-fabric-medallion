CREATE   VIEW dbo.[Sales_CreditCard] AS SELECT CAST([CreditCardID] AS int) AS [CreditCardID], CAST([CardType] AS VARCHAR(50)) AS [CardType], CAST([CardNumber] AS VARCHAR(25)) AS [CardNumber], CAST([ExpMonth] AS tinyint) AS [ExpMonth], CAST([ExpYear] AS smallint) AS [ExpYear], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_CreditCard];

GO
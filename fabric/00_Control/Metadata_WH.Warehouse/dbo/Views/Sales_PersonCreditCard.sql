CREATE   VIEW dbo.[Sales_PersonCreditCard] AS SELECT CAST([BusinessEntityID] AS int) AS [BusinessEntityID], CAST([CreditCardID] AS int) AS [CreditCardID], CAST([ModifiedDate] AS datetime2(6)) AS [ModifiedDate] FROM [lh_bronze].[bronze].[Sales_PersonCreditCard];

GO
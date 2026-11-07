CREATE TABLE [gold].[FactSalesOrder] (
    [SalesOrderID]       INT             NOT NULL,
    [SalesOrderNumber]   VARCHAR (50)    NULL,
    [OrderDateKey]       INT             NULL,
    [DueDateKey]         INT             NULL,
    [ShipDateKey]        INT             NULL,
    [CustomerKey]        INT             NULL,
    [SalesTerritoryKey]  INT             NULL,
    [EmployeeKey]        INT             NULL,
    [ShipMethodKey]      INT             NULL,
    [CurrencyKey]        INT             NULL,
    [ShipToGeographyKey] INT             NULL,
    [OnlineOrderFlag]    BIT             NULL,
    [SalesChannel]       VARCHAR (10)    NULL,
    [OrderStatusName]    VARCHAR (20)    NULL,
    [OrderLineCount]     INT             NULL,
    [SubTotal]           DECIMAL (19, 4) NULL,
    [TaxAmt]             DECIMAL (19, 4) NULL,
    [Freight]            DECIMAL (19, 4) NULL,
    [TotalDue]           DECIMAL (19, 4) NULL,
    [DaysToShip]         INT             NULL,
    [IsLateShipment]     BIT             NULL,
    [LoadRunId]          VARCHAR (100)   NULL
);


GO
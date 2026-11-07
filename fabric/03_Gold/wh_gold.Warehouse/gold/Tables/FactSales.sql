CREATE TABLE [gold].[FactSales] (
    [SalesOrderID]       INT             NOT NULL,
    [SalesOrderDetailID] INT             NOT NULL,
    [SalesOrderNumber]   VARCHAR (50)    NULL,
    [OrderDateKey]       INT             NULL,
    [DueDateKey]         INT             NULL,
    [ShipDateKey]        INT             NULL,
    [CustomerKey]        INT             NULL,
    [ProductKey]         INT             NULL,
    [PromotionKey]       INT             NULL,
    [SalesTerritoryKey]  INT             NULL,
    [EmployeeKey]        INT             NULL,
    [ShipMethodKey]      INT             NULL,
    [CurrencyKey]        INT             NULL,
    [ShipToGeographyKey] INT             NULL,
    [OnlineOrderFlag]    BIT             NULL,
    [SalesChannel]       VARCHAR (10)    NULL,
    [OrderQty]           INT             NULL,
    [UnitPrice]          DECIMAL (19, 4) NULL,
    [UnitPriceDiscount]  DECIMAL (19, 4) NULL,
    [DiscountAmount]     DECIMAL (19, 4) NULL,
    [LineTotal]          DECIMAL (19, 4) NULL,
    [UnitCost]           DECIMAL (19, 4) NULL,
    [TotalProductCost]   DECIMAL (19, 4) NULL,
    [GrossMargin]        DECIMAL (19, 4) NULL,
    [LoadRunId]          VARCHAR (100)   NULL
);


GO
CREATE TABLE [gold].[DimShipMethod] (
    [ShipMethodKey]  INT             NOT NULL,
    [ShipMethodName] VARCHAR (100)   NULL,
    [ShipBase]       DECIMAL (19, 4) NULL,
    [ShipRate]       DECIMAL (19, 4) NULL,
    [LoadRunId]      VARCHAR (100)   NULL
);


GO
/* =====================================================================
   01_gold_setup.sql                                          (v3)
   RUN IN : wh_gold
   PURPOSE: schemas, logging (2 tables + 2 procs), gold tables.

   Design: every gold table is fully rebuilt on each run, so
     - dimension keys are the source IDs (ProductKey = ProductID ...)
       except DimGeography and DimCurrency, which have no integer ID
     - -1 = Unknown member (no -1 row in DimDate)
     - re-running this script drops and recreates the gold tables;
       the next load repopulates them. Log tables are kept.
   ===================================================================== */

IF SCHEMA_ID('gold') IS NULL EXEC('CREATE SCHEMA gold');
GO
IF SCHEMA_ID('control')  IS NULL EXEC('CREATE SCHEMA control');
GO

/* ============================== LOGGING ============================== */

IF OBJECT_ID('control.PipelineRunLog') IS NULL
CREATE TABLE control.PipelineRunLog (
    PipelineRunId   VARCHAR(100)  NOT NULL,
    PipelineName    VARCHAR(200)  NOT NULL,
    TriggerType     VARCHAR(50)   NULL,
    StartTime       DATETIME2(6)  NOT NULL,
    EndTime         DATETIME2(6)  NULL,
    Status          VARCHAR(20)   NOT NULL,   -- Running / Succeeded / Failed
    ErrorMessage    VARCHAR(4000) NULL
);
GO

IF OBJECT_ID('control.TableLoadLog') IS NULL
CREATE TABLE control.TableLoadLog (
    PipelineRunId   VARCHAR(100)  NOT NULL,
    TableName       VARCHAR(200)  NOT NULL,
    StartTime       DATETIME2(6)  NOT NULL,
    EndTime         DATETIME2(6)  NULL,
    Status          VARCHAR(20)   NOT NULL,   -- Running / Succeeded / Failed
    RowsLoaded      INT           NULL,
    ErrorMessage    VARCHAR(4000) NULL
);
GO

-- Pipeline level: 'Running' inserts, 'Succeeded'/'Failed' closes the row
CREATE OR ALTER PROCEDURE control.usp_LogPipelineRun
    @PipelineRunId VARCHAR(100),
    @PipelineName  VARCHAR(200),
    @Status        VARCHAR(20),
    @TriggerType   VARCHAR(50)   = NULL,
    @ErrorMessage  VARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Status = 'Running'
        INSERT INTO control.PipelineRunLog (PipelineRunId, PipelineName, TriggerType, StartTime, Status)
        VALUES (@PipelineRunId, @PipelineName, @TriggerType, SYSUTCDATETIME(), 'Running');
    ELSE
        UPDATE control.PipelineRunLog
        SET EndTime = SYSUTCDATETIME(), Status = @Status, ErrorMessage = @ErrorMessage
        WHERE PipelineRunId = @PipelineRunId AND Status = 'Running';
END;
GO

-- Table level: 'Running' inserts, 'Succeeded'/'Failed' closes the row
CREATE OR ALTER PROCEDURE control.usp_LogTableLoad
    @PipelineRunId VARCHAR(100),
    @TableName     VARCHAR(200),
    @Status        VARCHAR(20),
    @RowsLoaded    INT           = NULL,
    @ErrorMessage  VARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Status = 'Running'
        INSERT INTO control.TableLoadLog (PipelineRunId, TableName, StartTime, Status)
        VALUES (@PipelineRunId, @TableName, SYSUTCDATETIME(), 'Running');
    ELSE
        UPDATE control.TableLoadLog
        SET EndTime = SYSUTCDATETIME(), Status = @Status,
            RowsLoaded = @RowsLoaded, ErrorMessage = @ErrorMessage
        WHERE PipelineRunId = @PipelineRunId AND TableName = @TableName AND Status = 'Running';
END;
GO

/* ============================ DIMENSIONS ============================= */

DROP TABLE IF EXISTS gold.DimDate;
CREATE TABLE gold.DimDate (
    DateKey         INT          NOT NULL,   -- YYYYMMDD
    [Date]          DATE         NOT NULL,
    DayOfMonth      SMALLINT,
    DayName         VARCHAR(10),
    DayOfWeek       SMALLINT,                -- 1 = Monday .. 7 = Sunday
    MonthNumber     SMALLINT,
    MonthName       VARCHAR(10),
    MonthYear       VARCHAR(8),              -- Jan-2014
    YearMonth       INT,                     -- 201401 (sort key for MonthYear)
    Quarter         SMALLINT,
    QuarterName     VARCHAR(2),              -- Q1..Q4
    [Year]          SMALLINT,
    FiscalQuarter   SMALLINT,                -- AdventureWorks FY starts 1 July
    FiscalYear      SMALLINT,
    IsWeekend       BIT
);
GO

DROP TABLE IF EXISTS gold.DimSalesTerritory;
CREATE TABLE gold.DimSalesTerritory (
    SalesTerritoryKey   INT NOT NULL,        -- = TerritoryID
    TerritoryName       VARCHAR(100),
    CountryRegionCode   VARCHAR(6),
    TerritoryGroup      VARCHAR(100),
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.DimGeography;
CREATE TABLE gold.DimGeography (
    GeographyKey        INT NOT NULL,        -- generated (no source ID at this grain)
    City                VARCHAR(100),
    PostalCode          VARCHAR(30),
    StateProvinceCode   VARCHAR(6),
    StateProvinceName   VARCHAR(100),
    CountryRegionCode   VARCHAR(6),
    CountryRegionName   VARCHAR(100),
    TerritoryName       VARCHAR(100),
    TerritoryGroup      VARCHAR(100),
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.DimCurrency;
CREATE TABLE gold.DimCurrency (
    CurrencyKey         INT NOT NULL,        -- generated (source key is a code)
    CurrencyCode        VARCHAR(3),
    CurrencyName        VARCHAR(100),
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.DimPromotion;
CREATE TABLE gold.DimPromotion (
    PromotionKey        INT NOT NULL,        -- = SpecialOfferID
    PromotionName       VARCHAR(510),
    DiscountPct         DECIMAL(19,4),
    PromotionType       VARCHAR(100),
    PromotionCategory   VARCHAR(100),
    StartDate           DATE,
    EndDate             DATE,
    MinQty              INT,
    MaxQty              INT,
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.DimShipMethod;
CREATE TABLE gold.DimShipMethod (
    ShipMethodKey       INT NOT NULL,        -- = ShipMethodID
    ShipMethodName      VARCHAR(100),
    ShipBase            DECIMAL(19,4),
    ShipRate            DECIMAL(19,4),
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.DimProduct;
CREATE TABLE gold.DimProduct (
    ProductKey          INT NOT NULL,        -- = ProductID
    ProductName         VARCHAR(100),
    ProductNumber       VARCHAR(50),
    Color               VARCHAR(30),
    Size                VARCHAR(10),
    ProductLine         VARCHAR(20),         -- Road / Mountain / Touring / Standard
    Class               VARCHAR(20),         -- High / Medium / Low
    Style               VARCHAR(20),         -- Womens / Mens / Universal
    ModelName           VARCHAR(100),
    Subcategory         VARCHAR(100),
    Category            VARCHAR(100),
    StandardCost        DECIMAL(19,4),       -- current cost (facts use cost history)
    ListPrice           DECIMAL(19,4),
    IsFinishedGood      BIT,
    SellStartDate       DATE,
    SellEndDate         DATE,
    ProductStatus       VARCHAR(20),         -- Current / Discontinued
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.DimEmployee;
CREATE TABLE gold.DimEmployee (
    EmployeeKey         INT NOT NULL,        -- = BusinessEntityID
    FullName            VARCHAR(250),
    JobTitle            VARCHAR(100),
    Department          VARCHAR(100),
    HireDate            DATE,
    IsSalesPerson       BIT,
    IsCurrentEmployee   BIT,
    TerritoryName       VARCHAR(100),
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.DimCustomer;
CREATE TABLE gold.DimCustomer (
    CustomerKey         INT NOT NULL,        -- = CustomerID
    AccountNumber       VARCHAR(20),
    CustomerType        VARCHAR(20),         -- Individual / Store / Unknown
    CustomerName        VARCHAR(250),        -- person name, or store name for stores
    ContactName         VARCHAR(250),        -- store contact (NULL for individuals)
    EmailAddress        VARCHAR(200),
    AddressLine1        VARCHAR(200),
    City                VARCHAR(100),
    StateProvinceName   VARCHAR(100),
    CountryRegionName   VARCHAR(100),
    PostalCode          VARCHAR(30),
    GeographyKey        INT,
    LoadRunId           VARCHAR(100)
);
GO

/* =============================== FACTS =============================== */

DROP TABLE IF EXISTS gold.FactSales;
CREATE TABLE gold.FactSales (
    SalesOrderID        INT NOT NULL,
    SalesOrderDetailID  INT NOT NULL,
    SalesOrderNumber    VARCHAR(50),
    OrderDateKey        INT,
    DueDateKey          INT,
    ShipDateKey         INT,                 -- NULL when not shipped
    CustomerKey         INT,
    ProductKey          INT,
    PromotionKey        INT,
    SalesTerritoryKey   INT,
    EmployeeKey         INT,                 -- -1 = online / no salesperson
    ShipMethodKey       INT,
    CurrencyKey         INT,
    ShipToGeographyKey  INT,
    OnlineOrderFlag     BIT,
    SalesChannel        VARCHAR(10),
    OrderQty            INT,
    UnitPrice           DECIMAL(19,4),
    UnitPriceDiscount   DECIMAL(19,4),
    DiscountAmount      DECIMAL(19,4),
    LineTotal           DECIMAL(19,4),
    UnitCost            DECIMAL(19,4),       -- cost as at order date
    TotalProductCost    DECIMAL(19,4),
    GrossMargin         DECIMAL(19,4),
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.FactSalesOrder;
CREATE TABLE gold.FactSalesOrder (
    SalesOrderID        INT NOT NULL,
    SalesOrderNumber    VARCHAR(50),
    OrderDateKey        INT,
    DueDateKey          INT,
    ShipDateKey         INT,
    CustomerKey         INT,
    SalesTerritoryKey   INT,
    EmployeeKey         INT,
    ShipMethodKey       INT,
    CurrencyKey         INT,
    ShipToGeographyKey  INT,
    OnlineOrderFlag     BIT,
    SalesChannel        VARCHAR(10),
    OrderStatusName     VARCHAR(20),
    OrderLineCount      INT,
    SubTotal            DECIMAL(19,4),
    TaxAmt              DECIMAL(19,4),
    Freight             DECIMAL(19,4),
    TotalDue            DECIMAL(19,4),
    DaysToShip          INT,
    IsLateShipment      BIT,
    LoadRunId           VARCHAR(100)
);
GO

DROP TABLE IF EXISTS gold.FactSalesQuota;
CREATE TABLE gold.FactSalesQuota (
    EmployeeKey         INT NOT NULL,
    QuotaDateKey        INT NOT NULL,
    SalesTerritoryKey   INT,
    SalesQuota          DECIMAL(19,4),
    LoadRunId           VARCHAR(100)
);
GO

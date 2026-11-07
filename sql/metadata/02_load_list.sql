/* =====================================================================
   02_load_list.sql                                           (v3.2)
   RUN IN : Metadata_WH
   PURPOSE: register the gold load in the existing metadata control
            table, metadata.MainControlTable (layer = 'gold').
            Read by gold.usp_Run_GoldLoad and by the gold pipeline's
            Lookup -> ForEach.

   Column use for gold rows:
     OrderExecution       load order (gaps of 10 leave room to insert)
     StoredProcedure_exec proc the loop executes in wh_gold
     sinkschema.sinktable target table (also the name in etl.TableLoadLog)
     skipload             1 = skip this table
     sourcetable          main silver view the table is built from (info only)
     tablekey             grain of the gold table (info only)

   Re-running replaces only the gold rows; bronze/silver rows are untouched.
   ===================================================================== */

DECLARE @pipeline VARCHAR(200) = 'pl_gold_load';    -- <-- set to your gold pipeline's name

DELETE FROM metadata.MainControlTable WHERE layer = 'gold';

DECLARE @baseId INT = (SELECT ISNULL(MAX(id), 0) FROM metadata.MainControlTable);

INSERT INTO metadata.MainControlTable
    (id, pipelinename, layer,
     sourcedatabase, sourceschema, sourcetable,
     sinkdatabase, sinkschema, sinktable,
     tablekey, loadtype, skipload, BusinessUnit,
     StoredProcedure_exec, OrderExecution)
SELECT  @baseId + ROW_NUMBER() OVER (ORDER BY v.OrderExecution),
        @pipeline, 'gold',
        'lh_silver', 'silver', v.sourcetable,
        'wh_gold', 'gold', v.sinktable,
        v.tablekey, 'full', 0, 'Sales',
        v.procname, v.OrderExecution
FROM (VALUES
    ( 10, 'DimDate',           NULL,                            'DateKey',                   'gold.usp_Load_DimDate'),
    ( 20, 'DimSalesTerritory', 'Sales_SalesTerritory',          'SalesTerritoryKey',         'gold.usp_Load_DimSalesTerritory'),
    ( 30, 'DimGeography',      'Person_Address',                'GeographyKey',              'gold.usp_Load_DimGeography'),
    ( 40, 'DimCurrency',       'Sales_Currency',                'CurrencyKey',               'gold.usp_Load_DimCurrency'),
    ( 50, 'DimPromotion',      'Sales_SpecialOffer',            'PromotionKey',              'gold.usp_Load_DimPromotion'),
    ( 60, 'DimShipMethod',     'Purchasing_ShipMethod',         'ShipMethodKey',             'gold.usp_Load_DimShipMethod'),
    ( 70, 'DimProduct',        'Production_Product',            'ProductKey',                'gold.usp_Load_DimProduct'),
    ( 80, 'DimEmployee',       'HumanResources_Employee',       'EmployeeKey',               'gold.usp_Load_DimEmployee'),
    ( 90, 'DimCustomer',       'Sales_Customer',                'CustomerKey',               'gold.usp_Load_DimCustomer'),   -- after DimGeography
    (100, 'FactSales',         'Sales_SalesOrderDetail',        'SalesOrderDetailID',        'gold.usp_Load_FactSales'),
    (110, 'FactSalesOrder',    'Sales_SalesOrderHeader',        'SalesOrderID',              'gold.usp_Load_FactSalesOrder'),
    (120, 'FactSalesQuota',    'Sales_SalesPersonQuotaHistory', 'EmployeeKey,QuotaDateKey',  'gold.usp_Load_FactSalesQuota')
) v (OrderExecution, sinktable, sourcetable, tablekey, procname);

-- Check
SELECT id, OrderExecution, sinkschema + '.' + sinktable AS TableName,
       StoredProcedure_exec, skipload
FROM metadata.MainControlTable
WHERE layer = 'gold'
ORDER BY OrderExecution;

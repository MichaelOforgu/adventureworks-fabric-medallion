/* =====================================================================
   04_dq_checks.sql                                          
   ===================================================================== */

-- 1. Latest run: pipeline row + every table 'Succeeded'
SELECT p.PipelineName, p.Status AS PipelineStatus, p.ErrorMessage AS PipelineError,
       t.TableName, t.Status, t.RowsLoaded,
       DATEDIFF(SECOND, t.StartTime, t.EndTime) AS DurationSec, t.ErrorMessage
FROM etl.PipelineRunLog p
LEFT JOIN etl.TableLoadLog t ON t.PipelineRunId = p.PipelineRunId
WHERE p.PipelineRunId = (SELECT TOP 1 PipelineRunId FROM etl.PipelineRunLog ORDER BY StartTime DESC)
ORDER BY t.StartTime;


-- 2. Reconciliation with silver: counts and amounts must match exactly
SELECT 'Lines'   AS Check_, 'Silver' AS Src, COUNT(*) AS Cnt, SUM(LineTotal) AS Amount
FROM lh_silver.silver.Sales_SalesOrderDetail
UNION ALL SELECT 'Lines',   'Gold',   COUNT(*), SUM(LineTotal) FROM gold.FactSales
UNION ALL SELECT 'Headers', 'Silver', COUNT(*), SUM(TotalDue)  FROM lh_silver.silver.Sales_SalesOrderHeader
UNION ALL SELECT 'Headers', 'Gold',   COUNT(*), SUM(TotalDue)  FROM gold.FactSalesOrder;


-- 3. Unknown-member usage in FactSales
--    Expect 0 everywhere; EmployeeKey -1 is expected only on online orders
SELECT COUNT(*)                                                 AS TotalLines,
       SUM(CASE WHEN CustomerKey        = -1 THEN 1 ELSE 0 END) AS UnknownCustomer,
       SUM(CASE WHEN ProductKey         = -1 THEN 1 ELSE 0 END) AS UnknownProduct,
       SUM(CASE WHEN PromotionKey       = -1 THEN 1 ELSE 0 END) AS UnknownPromotion,
       SUM(CASE WHEN SalesTerritoryKey  = -1 THEN 1 ELSE 0 END) AS UnknownTerritory,
       SUM(CASE WHEN ShipMethodKey      = -1 THEN 1 ELSE 0 END) AS UnknownShipMethod,
       SUM(CASE WHEN CurrencyKey        = -1 THEN 1 ELSE 0 END) AS UnknownCurrency,
       SUM(CASE WHEN ShipToGeographyKey = -1 THEN 1 ELSE 0 END) AS UnknownGeography,
       SUM(CASE WHEN EmployeeKey = -1 AND OnlineOrderFlag = 0
                THEN 1 ELSE 0 END)                              AS UnknownSalespersonOnResellerOrder,
       SUM(CASE WHEN UnitCost = 0 THEN 1 ELSE 0 END)            AS ZeroCostLines
FROM gold.FactSales;


-- 4. DimDate contiguous (needed for Power BI "Mark as date table")
--    Expect DayCount = ExpectedDays
SELECT MIN([Date]) AS FirstDate, MAX([Date]) AS LastDate, COUNT(*) AS DayCount,
       DATEDIFF(DAY, MIN([Date]), MAX([Date])) + 1 AS ExpectedDays
FROM gold.DimDate;

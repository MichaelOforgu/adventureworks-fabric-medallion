/* ---------------------------------------------------------------------
   FactSalesOrder  (grain: one row per sales order header)
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_FactSalesOrder
    @RunId VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.FactSalesOrder', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.FactSalesOrder;

        INSERT INTO gold.FactSalesOrder
            (SalesOrderID, SalesOrderNumber, OrderDateKey, DueDateKey, ShipDateKey,
             CustomerKey, SalesTerritoryKey, EmployeeKey, ShipMethodKey, CurrencyKey,
             ShipToGeographyKey, OnlineOrderFlag, SalesChannel, OrderStatusName, OrderLineCount,
             SubTotal, TaxAmt, Freight, TotalDue, DaysToShip, IsLateShipment, LoadRunId)
        SELECT
            h.SalesOrderID,
            h.SalesOrderNumber,
            CAST(CONVERT(VARCHAR(8), h.OrderDate, 112) AS INT),
            CAST(CONVERT(VARCHAR(8), h.DueDate,   112) AS INT),
            CAST(CONVERT(VARCHAR(8), h.ShipDate,  112) AS INT),
            ISNULL(dc.CustomerKey, -1),
            ISNULL(dt.SalesTerritoryKey, -1),
            ISNULL(de.EmployeeKey, -1),
            ISNULL(dsm.ShipMethodKey, -1),
            ISNULL(dcu.CurrencyKey, -1),
            ISNULL(dg.GeographyKey, -1),
            h.OnlineOrderFlag,
            CASE WHEN h.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Reseller' END,
            CASE h.Status WHEN 1 THEN 'In Process' WHEN 2 THEN 'Approved'
                          WHEN 3 THEN 'Backordered' WHEN 4 THEN 'Rejected'
                          WHEN 5 THEN 'Shipped' WHEN 6 THEN 'Cancelled'
                          ELSE 'Unknown' END,
            ISNULL(lc.LineCount, 0),
            h.SubTotal,
            h.TaxAmt,
            h.Freight,
            h.TotalDue,
            DATEDIFF(DAY, h.OrderDate, h.ShipDate),
            CASE WHEN h.ShipDate > h.DueDate THEN 1 ELSE 0 END,
            @RunId
        FROM lh_silver.silver.Sales_SalesOrderHeader h
        LEFT JOIN (
            SELECT SalesOrderID, COUNT(*) AS LineCount
            FROM lh_silver.silver.Sales_SalesOrderDetail
            GROUP BY SalesOrderID
        ) lc ON lc.SalesOrderID = h.SalesOrderID
        LEFT JOIN lh_silver.silver.Sales_CurrencyRate cr
               ON cr.CurrencyRateID = h.CurrencyRateID
        LEFT JOIN lh_silver.silver.Person_Address a
               ON a.AddressID = h.ShipToAddressID
        LEFT JOIN lh_silver.silver.Person_StateProvince sp
               ON sp.StateProvinceID = a.StateProvinceID
        LEFT JOIN gold.DimCustomer       dc  ON dc.CustomerKey       = h.CustomerID
        LEFT JOIN gold.DimSalesTerritory dt  ON dt.SalesTerritoryKey = h.TerritoryID
        LEFT JOIN gold.DimEmployee       de  ON de.EmployeeKey       = h.SalesPersonID
        LEFT JOIN gold.DimShipMethod     dsm ON dsm.ShipMethodKey    = h.ShipMethodID
        LEFT JOIN gold.DimCurrency       dcu ON dcu.CurrencyCode     = ISNULL(RTRIM(cr.ToCurrencyCode), 'USD')
        LEFT JOIN gold.DimGeography      dg
               ON  dg.City              = a.City
               AND dg.PostalCode        = ISNULL(a.PostalCode, '')
               AND dg.StateProvinceCode = RTRIM(sp.StateProvinceCode)
               AND dg.CountryRegionCode = RTRIM(sp.CountryRegionCode);
        SET @rows = @@ROWCOUNT;

        COMMIT TRANSACTION;
        EXEC control.usp_LogTableLoad @RunId, @table, 'Succeeded', @rows;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC control.usp_LogTableLoad @RunId, @table, 'Failed', NULL, @err;
        THROW;
    END CATCH;
END;

GO
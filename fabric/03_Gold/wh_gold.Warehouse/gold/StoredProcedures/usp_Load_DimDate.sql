/* =====================================================================
   02_dims.sql                                                (v3)
   RUN IN : wh_gold
   PURPOSE: all dimension loads. Every proc follows one pattern:

       log Running
       BEGIN TRAN
           DELETE all rows
           INSERT the -1 Unknown member   (not for DimDate)
           INSERT ... SELECT from silver
       COMMIT
       log Succeeded  (on error: ROLLBACK, log Failed, re-throw)

   Load order matters only for DimCustomer (needs DimGeography).
   ===================================================================== */


/* ---------------------------------------------------------------------
   DimDate  (no -1 row: Power BI date tables must be contiguous)
   --------------------------------------------------------------------- */
CREATE   PROCEDURE gold.usp_Load_DimDate
    @RunId     VARCHAR(100) = NULL,
    @StartDate DATE         = '2005-01-01',
    @EndDate   DATE         = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @table VARCHAR(200) = 'gold.DimDate', @rows INT, @err VARCHAR(4000);
    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    EXEC control.usp_LogTableLoad @RunId, @table, 'Running';

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM gold.DimDate;

        WITH digits AS (
            SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)
        ),
        nums AS (       -- 0..99,999 (Fabric has no recursive CTEs)
            SELECT a.n + b.n*10 + c.n*100 + d.n*1000 + e.n*10000 AS n
            FROM digits a CROSS JOIN digits b CROSS JOIN digits c
                 CROSS JOIN digits d CROSS JOIN digits e
        ),
        cal AS (        -- 1900-01-01 was a Monday -> day of week with no DATEFIRST dependency
            SELECT DATEADD(DAY, n, @StartDate) AS d,
                   (DATEDIFF(DAY, CAST('1900-01-01' AS DATE), DATEADD(DAY, n, @StartDate)) % 7) + 1 AS dow
            FROM nums
            WHERE n <= DATEDIFF(DAY, @StartDate, @EndDate)
        )
        INSERT INTO gold.DimDate
            (DateKey, [Date], DayOfMonth, DayName, DayOfWeek, MonthNumber, MonthName,
             MonthYear, YearMonth, Quarter, QuarterName, [Year],
             FiscalQuarter, FiscalYear, IsWeekend)
        SELECT
            CAST(CONVERT(VARCHAR(8), d, 112) AS INT),
            d,
            DAY(d),
            CHOOSE(dow, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
            dow,
            MONTH(d),
            CHOOSE(MONTH(d), 'January','February','March','April','May','June',
                             'July','August','September','October','November','December'),
            LEFT(CHOOSE(MONTH(d), 'January','February','March','April','May','June',
                        'July','August','September','October','November','December'), 3)
                + '-' + CAST(YEAR(d) AS VARCHAR(4)),
            YEAR(d) * 100 + MONTH(d),
            DATEPART(QUARTER, d),
            'Q' + CAST(DATEPART(QUARTER, d) AS VARCHAR(1)),
            YEAR(d),
            ((MONTH(d) + 5) % 12) / 3 + 1,
            YEAR(d) + CASE WHEN MONTH(d) >= 7 THEN 1 ELSE 0 END,
            CAST(CASE WHEN dow IN (6, 7) THEN 1 ELSE 0 END AS BIT)
        FROM cal;
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
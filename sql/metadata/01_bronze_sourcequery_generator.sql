/* =====================================================================
   01_bronze_sourcequery_generator.sql
   RUN IN : Metadata_WH
   PURPOSE: Delta Lake has no type for some SQL Server columns, so the
            bronze Copy activity fails on them
            (ErrorCode=DeltaNotSupportedInterimDataType).
            This builds an explicit SELECT for every bronze table that
            has such a column and stores it in MainControlTable.sourcequery.
            The query runs on the on-prem SQL Server during the copy.

            geography / geometry -> WKT text      ([col].STAsText())
            hierarchyid          -> path text     ([col].ToString())
            time                 -> 'HH:MM:SS'    (CONVERT(..., 108))
            xml                  -> text          (CAST AS NVARCHAR(MAX))

   The bronze Copy activity must use:
     @if(empty(<sourcequery>),
         concat('SELECT * FROM [', <schema>, '].[', <table>, ']'),
         <sourcequery>)

   Re-runnable: overwrites sourcequery for the affected bronze rows only.
   ===================================================================== */

UPDATE c
SET sourcequery = q.sourcequery
FROM metadata.MainControlTable c
JOIN (
    SELECT TABLE_SCHEMA, TABLE_NAME,
           'SELECT ' +
           STRING_AGG(CAST(
               CASE
                   WHEN DATA_TYPE IN ('geography', 'geometry')
                       THEN QUOTENAME(COLUMN_NAME) + '.STAsText() AS ' + QUOTENAME(COLUMN_NAME)
                   WHEN DATA_TYPE = 'hierarchyid'
                       THEN QUOTENAME(COLUMN_NAME) + '.ToString() AS ' + QUOTENAME(COLUMN_NAME)
                   WHEN DATA_TYPE = 'time'
                       THEN 'CONVERT(VARCHAR(8), ' + QUOTENAME(COLUMN_NAME) + ', 108) AS ' + QUOTENAME(COLUMN_NAME)
                   WHEN DATA_TYPE = 'xml'
                       THEN 'CAST(' + QUOTENAME(COLUMN_NAME) + ' AS NVARCHAR(MAX)) AS ' + QUOTENAME(COLUMN_NAME)
                   ELSE QUOTENAME(COLUMN_NAME)
               END AS VARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY ORDINAL_POSITION)
           + ' FROM ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) AS sourcequery
    FROM metadata.AdventureWorks
    GROUP BY TABLE_SCHEMA, TABLE_NAME
    HAVING SUM(CASE WHEN DATA_TYPE IN ('geography', 'geometry', 'hierarchyid', 'time', 'xml')
                    THEN 1 ELSE 0 END) > 0
) q
  ON  q.TABLE_SCHEMA = c.sourceschema
  AND q.TABLE_NAME   = c.sourcetable
WHERE c.layer = 'bronze';

-- Check (expect ~10 rows for AdventureWorks2019)
SELECT sourceschema, sourcetable, sourcequery
FROM metadata.MainControlTable
WHERE layer = 'bronze' AND sourcequery IS NOT NULL
ORDER BY sourceschema, sourcetable;

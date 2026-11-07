CREATE OR ALTER PROCEDURE [util].[usp_CreateSilverView]
(
    @sourcetable    VARCHAR(250),
    @sourcedatabase VARCHAR(250) = 'lh_bronze',
    @sourceschema   VARCHAR(128) = 'bronze',
    @targetschema   VARCHAR(128) = 'silver'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql VARCHAR(MAX);

    SELECT @sql =
        'CREATE OR ALTER VIEW ' + QUOTENAME(@targetschema) + '.' +
        QUOTENAME(TABLE_SCHEMA + '_' + TABLE_NAME) +
        ' AS SELECT ' +
        STRING_AGG(
            CAST(
                'CAST(' + QUOTENAME(COLUMN_NAME) + ' AS ' +
                CASE
                    WHEN DATA_TYPE IN ('geography', 'geometry', 'xml', 'hierarchyid')
                        THEN 'VARCHAR(MAX)'
                    WHEN DATA_TYPE IN ('datetime', 'datetime2', 'smalldatetime')
                        THEN 'datetime2(6)'
                    WHEN DATA_TYPE IN ('money', 'smallmoney')
                        THEN 'decimal(19,4)'
                    WHEN DATA_TYPE IN ('nvarchar', 'nchar')
                        THEN 'VARCHAR(' +
                             CASE WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX'
                                  ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) END + ')'
                    WHEN DATA_TYPE IN ('numeric', 'decimal')
                        THEN DATA_TYPE + '(' +
                             CAST(NUMERIC_PRECISION AS VARCHAR(10)) + ',' +
                             CAST(NUMERIC_SCALE AS VARCHAR(10)) + ')'
                    WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL
                        THEN DATA_TYPE + '(' +
                             CASE WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX'
                                  ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) END + ')'
                    ELSE DATA_TYPE
                END +
                ') AS ' + QUOTENAME(COLUMN_NAME)
                AS VARCHAR(MAX)
            ),
            ', '
        ) WITHIN GROUP (ORDER BY ORDINAL_POSITION) +
        ' FROM ' + QUOTENAME(@sourcedatabase) +
        '.' + QUOTENAME(@sourceschema) +
        '.' + QUOTENAME(@sourcetable) + ';'
    FROM [Metadata_WH].[metadata].[AdventureWorks]   -- cross-database read from your metadata warehouse
    WHERE TABLE_SCHEMA + '_' + TABLE_NAME = @sourcetable
    GROUP BY TABLE_SCHEMA, TABLE_NAME;

    IF @sql IS NULL
        THROW 50001, 'No matching source table found in metadata.', 1;

    PRINT @sql;
    EXEC (@sql);
END;
GO

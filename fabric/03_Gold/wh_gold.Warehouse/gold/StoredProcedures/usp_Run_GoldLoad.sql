/* =====================================================================
   05_orchestration.sql                                       (v3.1)
   RUN IN : wh_gold
   PURPOSE: run the gold load for manual / ad-hoc use.
            Loops over etl.GoldLoadControl in LoadOrder, prints each
            step to Messages as it goes, and returns the per-table
            results at the end.

   In the Fabric pipeline you don't call this proc - the pipeline runs
   the same list with Lookup -> ForEach so each table appears as its
   own iteration in Monitor (see the setup steps in the chat).
   ===================================================================== */

CREATE   PROCEDURE gold.usp_Run_GoldLoad
    @RunId        VARCHAR(100) = NULL,
    @PipelineName VARCHAR(200) = 'Manual - gold.usp_Run_GoldLoad',
    @TriggerType  VARCHAR(50)  = 'Manual'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @order INT = 0,
            @step  INT = 0,
            @total INT,
            @table VARCHAR(200),
            @proc  VARCHAR(200),
            @sql   VARCHAR(500),
            @err   VARCHAR(4000);

    IF @RunId IS NULL SET @RunId = CONVERT(VARCHAR(36), NEWID());
    SELECT @total = COUNT(*) FROM etl.GoldLoadControl WHERE IsActive = 1;

    EXEC etl.usp_LogPipelineRun @RunId, @PipelineName, 'Running', @TriggerType;
    PRINT 'Gold load started. RunId = ' + @RunId + ' | ' + CAST(@total AS VARCHAR(10)) + ' tables';

    BEGIN TRY
        WHILE 1 = 1
        BEGIN
            SET @proc = NULL;

            SELECT TOP 1 @order = LoadOrder, @table = TableName, @proc = ProcName
            FROM etl.GoldLoadControl
            WHERE IsActive = 1 AND LoadOrder > @order
            ORDER BY LoadOrder;

            IF @proc IS NULL BREAK;

            IF OBJECT_ID(@proc) IS NULL
            BEGIN
                SET @err = 'Proc listed in etl.GoldLoadControl does not exist: ' + @proc;
                THROW 50300, @err, 1;
            END;

            SET @step = @step + 1;
            PRINT CONCAT('[', @step, '/', @total, '] ', @table, ' ... ');

            SET @sql = 'EXEC ' + @proc + ' @RunId = ''' + REPLACE(@RunId, '''', '''''') + ''';';
            EXEC (@sql);

            PRINT CONCAT('[', @step, '/', @total, '] ', @table, ' done');
        END;

        EXEC etl.usp_LogPipelineRun @RunId, @PipelineName, 'Succeeded';
        PRINT 'Gold load succeeded.';
    END TRY
    BEGIN CATCH
        SET @err = LEFT(ERROR_MESSAGE(), 4000);
        EXEC etl.usp_LogPipelineRun @RunId, @PipelineName, 'Failed', NULL, @err;
        PRINT 'Gold load FAILED at ' + ISNULL(@table, '?') + ': ' + @err;

        -- Show what ran before re-throwing
        SELECT c.LoadOrder, c.TableName, ISNULL(t.Status, 'Not run') AS Status,
               t.RowsLoaded, DATEDIFF(SECOND, t.StartTime, t.EndTime) AS DurationSec, t.ErrorMessage
        FROM etl.GoldLoadControl c
        LEFT JOIN etl.TableLoadLog t
               ON t.TableName = c.TableName AND t.PipelineRunId = @RunId
        WHERE c.IsActive = 1
        ORDER BY c.LoadOrder;

        THROW;
    END CATCH;

    -- The list: every table, in order, with its result
    SELECT c.LoadOrder, c.TableName, ISNULL(t.Status, 'Not run') AS Status,
           t.RowsLoaded, DATEDIFF(SECOND, t.StartTime, t.EndTime) AS DurationSec
    FROM etl.GoldLoadControl c
    LEFT JOIN etl.TableLoadLog t
           ON t.TableName = c.TableName AND t.PipelineRunId = @RunId
    WHERE c.IsActive = 1
    ORDER BY c.LoadOrder;
END;

GO
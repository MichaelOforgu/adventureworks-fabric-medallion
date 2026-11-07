-- Table level: 'Running' inserts, 'Succeeded'/'Failed' closes the row
CREATE   PROCEDURE control.usp_LogTableLoad
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
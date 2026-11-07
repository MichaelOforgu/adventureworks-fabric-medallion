-- Pipeline level: 'Running' inserts, 'Succeeded'/'Failed' closes the row
CREATE   PROCEDURE control.usp_LogPipelineRun
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
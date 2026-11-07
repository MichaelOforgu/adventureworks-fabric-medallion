CREATE TABLE [control].[PipelineRunLog] (
    [PipelineRunId] VARCHAR (100)  NOT NULL,
    [PipelineName]  VARCHAR (200)  NOT NULL,
    [TriggerType]   VARCHAR (50)   NULL,
    [StartTime]     DATETIME2 (6)  NOT NULL,
    [EndTime]       DATETIME2 (6)  NULL,
    [Status]        VARCHAR (20)   NOT NULL,
    [ErrorMessage]  VARCHAR (4000) NULL
);


GO
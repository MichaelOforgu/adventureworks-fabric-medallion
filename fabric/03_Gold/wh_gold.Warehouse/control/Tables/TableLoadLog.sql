CREATE TABLE [control].[TableLoadLog] (
    [PipelineRunId] VARCHAR (100)  NOT NULL,
    [TableName]     VARCHAR (200)  NOT NULL,
    [StartTime]     DATETIME2 (6)  NOT NULL,
    [EndTime]       DATETIME2 (6)  NULL,
    [Status]        VARCHAR (20)   NOT NULL,
    [RowsLoaded]    INT            NULL,
    [ErrorMessage]  VARCHAR (4000) NULL
);


GO
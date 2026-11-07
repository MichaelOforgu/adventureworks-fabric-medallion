CREATE TABLE [metadata].[MainControlTable] (
    [id]                          INT            NULL,
    [pipelinename]                VARCHAR (200)  NULL,
    [layer]                       VARCHAR (50)   NULL,
    [sourcedatabase]              VARCHAR (200)  NULL,
    [sourceschema]                VARCHAR (128)  NULL,
    [sourcetable]                 VARCHAR (200)  NULL,
    [sourceincrementalcolumn]     VARCHAR (200)  NULL,
    [sourceincrementaltype]       VARCHAR (50)   NULL,
    [sourceincrementalstartvalue] VARCHAR (200)  NULL,
    [sinkdatabase]                VARCHAR (200)  NULL,
    [sinkschema]                  VARCHAR (128)  NULL,
    [sinktable]                   VARCHAR (200)  NULL,
    [tablekey]                    VARCHAR (500)  NULL,
    [loadtype]                    VARCHAR (50)   NULL,
    [skipload]                    BIT            NULL,
    [BusinessUnit]                VARCHAR (200)  NULL,
    [StoredProcedure_exec]        VARCHAR (500)  NULL,
    [Notebook_exec]               VARCHAR (500)  NULL,
    [DataSourceId]                VARCHAR (200)  NULL,
    [OrderExecution]              INT            NULL,
    [sourcequery]                 VARCHAR (8000) NULL
);


GO
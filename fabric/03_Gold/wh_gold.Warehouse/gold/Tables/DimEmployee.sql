CREATE TABLE [gold].[DimEmployee] (
    [EmployeeKey]       INT           NOT NULL,
    [FullName]          VARCHAR (250) NULL,
    [JobTitle]          VARCHAR (100) NULL,
    [Department]        VARCHAR (100) NULL,
    [HireDate]          DATE          NULL,
    [IsSalesPerson]     BIT           NULL,
    [IsCurrentEmployee] BIT           NULL,
    [TerritoryName]     VARCHAR (100) NULL,
    [LoadRunId]         VARCHAR (100) NULL
);


GO
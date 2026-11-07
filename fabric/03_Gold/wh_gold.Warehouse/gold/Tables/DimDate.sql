CREATE TABLE [gold].[DimDate] (
    [DateKey]       INT          NOT NULL,
    [Date]          DATE         NOT NULL,
    [DayOfMonth]    SMALLINT     NULL,
    [DayName]       VARCHAR (10) NULL,
    [DayOfWeek]     SMALLINT     NULL,
    [MonthNumber]   SMALLINT     NULL,
    [MonthName]     VARCHAR (10) NULL,
    [MonthYear]     VARCHAR (8)  NULL,
    [YearMonth]     INT          NULL,
    [Quarter]       SMALLINT     NULL,
    [QuarterName]   VARCHAR (2)  NULL,
    [Year]          SMALLINT     NULL,
    [FiscalQuarter] SMALLINT     NULL,
    [FiscalYear]    SMALLINT     NULL,
    [IsWeekend]     BIT          NULL
);


GO
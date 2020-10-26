CREATE TABLE [dbo].[Reporting_ActivityByMonthWithTargetTypes] (
    [TargetType]        NVARCHAR (25)   NULL,
    [TargetTypeInteger] INT             NULL,
    [Metric]            NVARCHAR (25)   NULL,
    [MetricInteger]     INT             NULL,
    [Month]             NVARCHAR (25)   NOT NULL,
    [MonthInteger]      INT             NOT NULL,
    [Value]             DECIMAL (10, 1) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_ActivityByMonthWithTargetTypes_Metric]
    ON [dbo].[Reporting_ActivityByMonthWithTargetTypes]([Metric] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_ActivityByMonthWithTargetTypes_TargetType]
    ON [dbo].[Reporting_ActivityByMonthWithTargetTypes]([TargetType] ASC);


CREATE TABLE [dbo].[Reporting_ActivityByTerritoryWithTargetTypes] (
    [Territory Name]    NVARCHAR (200)  NULL,
    [TargetType]        NVARCHAR (25)   NULL,
    [TargetTypeInteger] INT             NULL,
    [Time Period]       NVARCHAR (25)   NOT NULL,
    [TimePeriodInteger] INT             NULL,
    [Metric]            NVARCHAR (25)   NULL,
    [MetricInteger]     INT             NULL,
    [Value]             DECIMAL (10, 1) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_ActivityByTerritoryWithTargetTypes_TimePeriod]
    ON [dbo].[Reporting_ActivityByTerritoryWithTargetTypes]([Time Period] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_ActivityByTerritoryWithTargetTypes_Metric]
    ON [dbo].[Reporting_ActivityByTerritoryWithTargetTypes]([Metric] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_ActivityByTerritoryWithTargetTypes_TargetType]
    ON [dbo].[Reporting_ActivityByTerritoryWithTargetTypes]([TargetType] ASC);


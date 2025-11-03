CREATE TABLE [dbo].[Live_MR_ActivityByTerritory] (
    [Territory]         VARCHAR (400)   NOT NULL,
    [Territory Name]    NVARCHAR (200)  NOT NULL,
    [Time Period]       NVARCHAR (25)   NOT NULL,
    [TimePeriodInteger] INT             NULL,
    [Metric]            NVARCHAR (25)   NULL,
    [MetricInteger]     INT             NULL,
    [Value]             DECIMAL (10, 1) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Live_MR_ActivityByTerritory_TimePeriod]
    ON [dbo].[Live_MR_ActivityByTerritory]([Time Period] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Live_MR_ActivityByTerritory_Metric]
    ON [dbo].[Live_MR_ActivityByTerritory]([Metric] ASC);


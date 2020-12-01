
CREATE TABLE [dbo].[ADF_PipelineRun](
	[PipelineRunId] [uniqueidentifier] NOT NULL,
	[PipelineId] [int] NOT NULL,
	[RunStart] [datetime] NOT NULL,
	[RunEnd] [datetime] NOT NULL,
	[RunStatus] [varchar](100) NOT NULL,
	[LastUpdated] [datetime] NOT NULL,
	[DurationInMilliSeconds] [int] NOT NULL,
	[InvokedByType] [varchar](100) NOT NULL,
	[InvokedByName] [varchar](100) NOT NULL,
 CONSTRAINT [PK_ADF_PipelineRun] PRIMARY KEY CLUSTERED ([PipelineRunId] ASC)
)
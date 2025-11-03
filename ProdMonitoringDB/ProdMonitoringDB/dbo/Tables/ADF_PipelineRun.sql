
CREATE TABLE [dbo].[ADF_PipelineRun](
	[PipelineRunId] [uniqueidentifier] NOT NULL,
	[PipelineId] [int] NOT NULL,
	[RunStart] [datetime] NOT NULL,
	[RunEnd] [datetime] NULL,
	[RunStatus] [varchar](100) NOT NULL,
	[LastUpdated] [datetime] NOT NULL,
	[DurationInMilliSeconds] [int] NULL,
	[InvokedById] [varchar](100) NULL,
	[InvokedByType] [varchar](100) NOT NULL,
	[InvokedByName] [varchar](100) NOT NULL,
	[ErrorMessage] [varchar](4000) NULL,
	[RunGroupId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ADF_PipelineRun] PRIMARY KEY CLUSTERED ([PipelineRunId] ASC)
)



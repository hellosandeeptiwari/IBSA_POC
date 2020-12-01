CREATE TABLE [dbo].[ADF_Pipeline](
	[PipelineId] [int] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[ResourceGroupName] [varchar](100) NOT NULL,
	[DataFactoryName] [varchar](100) NOT NULL,
	[PipelineName] [varchar](100) NOT NULL,
 CONSTRAINT [PK_ADF_Pipeline] PRIMARY KEY CLUSTERED ([PipelineId] ASC)
 CONSTRAINT [UK_ADF_Pipeline_1] UNIQUE NONCLUSTERED ([ResourceGroupName] ASC,
	[DataFactoryName] ASC,
	[PipelineName] ASC)
)
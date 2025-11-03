
CREATE TABLE ADF_PipelineRunHistory
(
	CustomerId int NULL,
	ResourceGroupName varchar(100) NOT NULL,
	DataFactoryName varchar(100) NOT NULL,
	PipelineName varchar(100) NOT NULL,
	PipelineRunId uniqueidentifier NOT NULL,
	RunStart datetime NOT NULL,
	RunEnd datetime NULL,
	RunStatus varchar(100) NOT NULL,
	LastUpdated datetime NOT NULL,
	DurationInMilliSeconds int NULL,
	InvokedById varchar(100) NULL,
	InvokedByType varchar(100) NOT NULL,
	InvokedByName varchar(100) NOT NULL,
	ErrorMessage varchar(4000) NULL,
	RunGroupId uniqueidentifier NULL
);



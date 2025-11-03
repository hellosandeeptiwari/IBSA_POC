CREATE TABLE [dbo].[VEEV_AsyncApexJob] (
    [AsyncApexJobId]      UNIQUEIDENTIFIER NOT NULL,
    [ApexClassId]         VARCHAR (50)     NULL,
    [CompletedDate]       DATETIME         NULL,
    [CreatedById]         VARCHAR (50)     NOT NULL,
    [CreatedDate]         DATETIME         NOT NULL,
    [ExtendedStatus]      VARCHAR (500)    NULL,
    [EndDate]             DATETIME         NULL,
    [ExternalId1]         VARCHAR (50)     NOT NULL,
    [JobItemsProcessed]   INT              NULL,
    [JobType]             VARCHAR (100)    NULL,
    [LastProcessed]       VARCHAR (200)    NULL,
    [LastProcessedOffset] INT              NULL,
    [MethodName]          VARCHAR (200)    NULL,
    [NumberOfErrors]      INT              NULL,
    [ParentJobId]         VARCHAR (50)     NULL,
    [Status]              VARCHAR (50)     NULL,
    [TotalJobItems]       INT              NULL,
    [CustomerId]          INT              NOT NULL,
	CONSTRAINT PK_VEEV_AsyncApexJob PRIMARY KEY (AsyncApexJobId)
);

CREATE NONCLUSTERED INDEX IX_VEEV_AsyncApexJob_CustomerId_ExternalId1 ON VEEV_AsyncApexJob(CustomerId, ExternalId1);
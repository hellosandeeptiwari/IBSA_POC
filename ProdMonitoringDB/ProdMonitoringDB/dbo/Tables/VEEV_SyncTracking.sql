CREATE TABLE [dbo].[VEEV_SyncTracking] (
    [SyncTrackingId]        UNIQUEIDENTIFIER NOT NULL,
    [ExternalId1]           VARCHAR (50)     NOT NULL,
    [SyncTrackingName]      VARCHAR (200)    NULL,
    [CreatedById]           VARCHAR (50)     NOT NULL,
    [CreatedDate]           DATETIME         NOT NULL,
    [IsDeleted]             BIT              NOT NULL,
    [LastModifiedById]      VARCHAR (50)     NOT NULL,
    [LastModifiedDate]      DATETIME         NOT NULL,
    [MobileId]              VARCHAR (100)    NULL,
    [Ownerid]               VARCHAR (50)     NULL,
    [NumberofRetries]       DECIMAL (9, 1)   NULL,
    [NumberofUploadErrors]  DECIMAL (9, 1)   NULL,
    [NumberOfUploads]       DECIMAL (9, 1)   NULL,
    [NumberOfVTrans]        DECIMAL (9, 1)   NULL,
    [MediaProcessed]        BIT              NULL,
    [Cancelled]             BIT              NULL,
    [SuccessfulSync]        DECIMAL (9, 1)   NULL,
    [SyncDuration]          DECIMAL (9, 1)   NULL,
    [SyncType]              VARCHAR (50)     NULL,
    [SyncStartDatetime]     DATETIME         NULL,
    [SyncCompletedDatetime] DATETIME         NULL,
    [UploadProcessed]       BIT     		 NULL,
    [DownloadProcessed]     BIT              NULL,
    [Version]               VARCHAR (50)     NULL,
    [VInsightsProcessed]    BIT              NULL,
    [SystemModstamp]        DATETIME         NOT NULL,
    [CustomerId]            INT              NOT NULL,
	CONSTRAINT PK_VEEV_SyncTracking PRIMARY KEY (SyncTrackingId)
);

CREATE NONCLUSTERED INDEX IX_VEEV_SyncTracking_CustomerId_ExternalId1 ON VEEV_SyncTracking(CustomerId, ExternalId1);


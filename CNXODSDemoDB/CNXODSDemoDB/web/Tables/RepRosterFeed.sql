CREATE TABLE [web].[RepRosterFeed] (
    [RepRosterFeedId]      INT            IDENTITY (1, 1) NOT NULL,
    [Status]               NVARCHAR (4)   NOT NULL,
    [TotalRecordCount]     INT            NOT NULL,
    [UploadRecordCount]    INT            NOT NULL,
    [FailedRecordCount]    INT            NOT NULL,
    [SourceFileId]         INT            NULL,
    [UploadedRecordFileId] INT            NULL,
    [FailedRecordFileId]   INT            NULL,
    [Comment]              NVARCHAR (MAX) NULL,
    [CreatedBy]            INT            NOT NULL,
    [CreatedDate]          DATETIME       NOT NULL,
    PRIMARY KEY CLUSTERED ([RepRosterFeedId] ASC)
);


CREATE TABLE [web].[RepRosterAttachment] (
    [RepRosterAttachmentId] INT             IDENTITY (1, 1) NOT NULL,
    [RepRosterFeedId]       INT             NOT NULL,
    [FileName]              NVARCHAR (2000) NOT NULL,
    [FileType]              NVARCHAR (4)    NOT NULL,
    [BlobUrl]               NVARCHAR (MAX)  NULL,
    PRIMARY KEY CLUSTERED ([RepRosterAttachmentId] ASC),
    CONSTRAINT [FK_RepRosterFeed_RepRosterFeedId] FOREIGN KEY ([RepRosterFeedId]) REFERENCES [web].[RepRosterFeed] ([RepRosterFeedId])
);


GO
CREATE NONCLUSTERED INDEX [IX_RepRosterAttachment_RepRosterFeedId]
    ON [web].[RepRosterAttachment]([RepRosterFeedId] ASC);


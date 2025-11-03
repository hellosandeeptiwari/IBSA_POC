CREATE TABLE [dbo].[CMS_AccountMerge] (
    [AccountMergeId]        INT            IDENTITY (1, 1) NOT NULL,
    [CmsId1]                INT            NOT NULL,
    [CmsId2]                INT            NOT NULL,
    [Status]                VARCHAR (4)    NOT NULL,
    [Winner]                INT            NULL,
    [PopulateNullFields]    BIT            NULL,
    [JWScoreForName]        DECIMAL (5, 2) NOT NULL,
    [JWScoreForAddress]     DECIMAL (5, 2) NOT NULL,
    [MergeType]             VARCHAR (4)    NOT NULL,
    [MatchType]             VARCHAR (4)    NOT NULL,
    [VeevaMergeStatus]      VARCHAR (4)    NULL,
    [PrimaryAddressMergeId] INT            NULL,
    [RejectComments]        VARCHAR (250)  NULL,
    [CreatedUtcDate]        DATETIME       NOT NULL,
    [UpdatedUtcDate]        DATETIME       NULL,
    [UpdatedBy]             INT            NULL,
    [CmsAddressId1]         INT            NULL,
    [CmsAddressId2]         INT            NULL,
    CONSTRAINT [PK_CMS_AccountMerge] PRIMARY KEY CLUSTERED ([AccountMergeId] ASC),
    CONSTRAINT [FK_CMS_AccountMerge_CmsId1_CMS_Account_CmsId] FOREIGN KEY ([CmsId1]) REFERENCES [dbo].[CMS_Account] ([CmsId]),
    CONSTRAINT [FK_CMS_AccountMerge_CmsId2_CMS_Account_CmsId] FOREIGN KEY ([CmsId2]) REFERENCES [dbo].[CMS_Account] ([CmsId])
);


GO
CREATE NONCLUSTERED INDEX [IX_CMS_AccountMerge_CmsId1]
    ON [dbo].[CMS_AccountMerge]([CmsId1] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CMS_AccountMerge_CmsId2]
    ON [dbo].[CMS_AccountMerge]([CmsId2] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CMS_AccountMerge_Status]
    ON [dbo].[CMS_AccountMerge]([Status] ASC);


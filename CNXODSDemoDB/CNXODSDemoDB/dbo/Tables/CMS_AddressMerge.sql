CREATE TABLE [dbo].[CMS_AddressMerge] (
    [AddressMergeId]   INT         IDENTITY (1, 1) NOT NULL,
    [AccountMergeId]   INT         NOT NULL,
    [CmsAddressId]     INT         NOT NULL,
    [CmsId]            INT         NOT NULL,
    [Status]           VARCHAR (4) NOT NULL,
    [CreatedUtcDate]   DATETIME    NOT NULL,
    [UpdatedUtcDate]   DATETIME    NULL,
    [UpdatedBy]        INT         NULL,
    [VeevaMergeStatus] VARCHAR (4) NULL,
    CONSTRAINT [PK_CMS_AddressMerge] PRIMARY KEY CLUSTERED ([AddressMergeId] ASC),
    CONSTRAINT [FK_CMS_AddressMerge_AccountMergeId_CMS_AccountMerge_AccountMergeId] FOREIGN KEY ([AccountMergeId]) REFERENCES [dbo].[CMS_AccountMerge] ([AccountMergeId]) ON DELETE CASCADE,
    CONSTRAINT [FK_CMS_AddressMerge_CmsAddressId_CMS_AccountAddress_CmsAddressId] FOREIGN KEY ([CmsAddressId]) REFERENCES [dbo].[CMS_AccountAddress] ([CmsAddressId]),
    CONSTRAINT [FK_CMS_AddressMerge_CmsId_CMS_Account_CmsId] FOREIGN KEY ([CmsId]) REFERENCES [dbo].[CMS_Account] ([CmsId])
);


GO
CREATE NONCLUSTERED INDEX [IX_CMS_AddressMerge_AccountMergeId_Status]
    ON [dbo].[CMS_AddressMerge]([AccountMergeId] ASC, [Status] ASC);


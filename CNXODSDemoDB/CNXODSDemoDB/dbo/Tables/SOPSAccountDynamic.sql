CREATE TABLE [dbo].[SOPSAccountDynamic] (
    [SOPSAccountDynamicId] INT            IDENTITY (1, 1) NOT NULL,
    [SOpsAccountId]        INT            NOT NULL,
    [OdsAccountId]         NVARCHAR (200) NULL,
    [TextField1]           NVARCHAR (200) NULL,
    [TextField2]           NVARCHAR (200) NULL,
    [TextField3]           NVARCHAR (200) NULL,
    [TextField4]           NVARCHAR (200) NULL,
    [TextField5]           NVARCHAR (200) NULL,
    [TextField6]           NVARCHAR (200) NULL,
    [TextField7]           NVARCHAR (200) NULL,
    [TextField8]           NVARCHAR (200) NULL,
    [TextField9]           NVARCHAR (200) NULL,
    [TextField10]          NVARCHAR (200) NULL,
    [TextField11]          NVARCHAR (200) NULL,
    [TextField12]          NVARCHAR (200) NULL,
    [TextField13]          NVARCHAR (200) NULL,
    [TextField14]          NVARCHAR (200) NULL,
    [TextField15]          NVARCHAR (200) NULL,
    [TextField16]          NVARCHAR (200) NULL,
    [TextField17]          NVARCHAR (200) NULL,
    [TextField18]          NVARCHAR (200) NULL,
    [TextField19]          NVARCHAR (200) NULL,
    [TextField20]          NVARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([SOPSAccountDynamicId] ASC),
    CONSTRAINT [FK_SOPSAccountDynamic_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [dbo].[SOpsAccount] ([SOpsAccountId]),
    UNIQUE NONCLUSTERED ([SOpsAccountId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SOPSAccountDynamic_SOpsAccountId]
    ON [dbo].[SOPSAccountDynamic]([SOpsAccountId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOPSAccountDynamic_OdsAccountId]
    ON [dbo].[SOPSAccountDynamic]([OdsAccountId] ASC);


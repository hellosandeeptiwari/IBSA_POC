CREATE TABLE [dbo].[SOpsAccount] (
    [SOpsAccountId]     INT            IDENTITY (1, 1) NOT NULL,
    [OdsAccountId]      NVARCHAR (200) NOT NULL,
    [Name]              NVARCHAR (200) NOT NULL,
    [SopsSpecialtyId]   INT            NULL,
    [RecommendedTierId] INT            NULL,
    [AccountType]       NVARCHAR (4)   NOT NULL,
    [ExternalId1]       NVARCHAR (200) NULL,
    [ExternalId2]       NVARCHAR (200) NULL,
    [ExternalId3]       NVARCHAR (200) NULL,
    [ExternalId4]       NVARCHAR (200) NULL,
    [ExternalId5]       NVARCHAR (200) NULL,
    [ExternalId6]       NVARCHAR (200) NULL,
    [ExternalId7]       NVARCHAR (200) NULL,
    [ExternalId8]       NVARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([SOpsAccountId] ASC),
    CONSTRAINT [FK_SOpsAccount_RecommendedTierId] FOREIGN KEY ([RecommendedTierId]) REFERENCES [dbo].[SOpsAccountTier] ([SOpsAccountTierId]),
    CONSTRAINT [FK_SOpsAccount_SopsSpecialtyId] FOREIGN KEY ([SopsSpecialtyId]) REFERENCES [dbo].[SopsSpecialty] ([SopsSpecialtyId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccount_SOpsAccountId]
    ON [dbo].[SOpsAccount]([SOpsAccountId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccount_RecommendedTierId]
    ON [dbo].[SOpsAccount]([RecommendedTierId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccount_SopsSpecialtyId]
    ON [dbo].[SOpsAccount]([SopsSpecialtyId] ASC);


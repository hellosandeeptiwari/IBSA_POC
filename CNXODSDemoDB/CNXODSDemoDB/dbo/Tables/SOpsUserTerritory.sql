CREATE TABLE [dbo].[SOpsUserTerritory] (
    [SOpsUserTerritoryId] INT IDENTITY (1, 1) NOT NULL,
    [SOpsUserId]          INT NOT NULL,
    [SOpsTerritoryId]     INT NOT NULL,
    [IsActiveTerritory]   BIT NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsUserTerritoryId] ASC),
    CONSTRAINT [FK_SOpsUserTerritory_SOpsTerritoryId] FOREIGN KEY ([SOpsTerritoryId]) REFERENCES [dbo].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsUserTerritory_SOpsUserId] FOREIGN KEY ([SOpsUserId]) REFERENCES [dbo].[SOpsUser] ([SOpsUserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsUserTerritory_SOpsUserTerritoryId]
    ON [dbo].[SOpsUserTerritory]([SOpsUserTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsUserTerritory_SOpsUserId]
    ON [dbo].[SOpsUserTerritory]([SOpsUserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsUserTerritory_SOpsTerritoryId]
    ON [dbo].[SOpsUserTerritory]([SOpsTerritoryId] ASC);


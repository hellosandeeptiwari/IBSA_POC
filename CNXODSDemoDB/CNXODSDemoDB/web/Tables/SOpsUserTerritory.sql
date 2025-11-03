CREATE TABLE [web].[SOpsUserTerritory] (
    [SOpsUserTerritoryId] INT IDENTITY (1, 1) NOT NULL,
    [SOpsUserId]          INT NOT NULL,
    [SOpsTerritoryId]     INT NOT NULL,
    [IsActiveTerritory]   BIT NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsUserTerritoryId] ASC),
    CONSTRAINT [FK_SOpsUserTerritory_SOpsTerritoryId] FOREIGN KEY ([SOpsTerritoryId]) REFERENCES [web].[SOpsTerritory] ([SOpsTerritoryId]),
    CONSTRAINT [FK_SOpsUserTerritory_SOpsUserId] FOREIGN KEY ([SOpsUserId]) REFERENCES [web].[SOpsUser] ([SOpsUserId]),
    CONSTRAINT [SOpsUserTerritory_SOpsTerritoryId] UNIQUE NONCLUSTERED ([SOpsTerritoryId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsUserTerritory_SOpsUserTerritoryId]
    ON [web].[SOpsUserTerritory]([SOpsUserTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsUserTerritory_SOpsUserId]
    ON [web].[SOpsUserTerritory]([SOpsUserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsUserTerritory_SOpsTerritoryId]
    ON [web].[SOpsUserTerritory]([SOpsTerritoryId] ASC);


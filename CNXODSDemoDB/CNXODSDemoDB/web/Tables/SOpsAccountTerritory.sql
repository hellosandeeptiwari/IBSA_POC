CREATE TABLE [web].[SOpsAccountTerritory] (
    [SOpsAccountTerritoryId] INT IDENTITY (1, 1) NOT NULL,
    [SOpsAccountId]          INT NOT NULL,
    [SOpsTerritoryId]        INT NOT NULL,
    [SopsAddressId]          INT NOT NULL,
    [CurrentTierId]          INT NULL,
    [FutureTierId]           INT NULL,
    PRIMARY KEY CLUSTERED ([SOpsAccountTerritoryId] ASC),
    CONSTRAINT [FK_SOpsAccountTerritory_CurrentTierId] FOREIGN KEY ([CurrentTierId]) REFERENCES [web].[SOpsAccountTier] ([SOpsAccountTierId]),
    CONSTRAINT [FK_SOpsAccountTerritory_FutureTierId] FOREIGN KEY ([FutureTierId]) REFERENCES [web].[SOpsAccountTier] ([SOpsAccountTierId]),
    CONSTRAINT [FK_SOpsAccountTerritory_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [web].[SOpsAccount] ([SOpsAccountId]),
    CONSTRAINT [FK_SOpsAccountTerritory_SopsAddressId] FOREIGN KEY ([SopsAddressId]) REFERENCES [web].[SOpsAddress] ([SOpsAddressId]),
    CONSTRAINT [FK_SOpsAccountTerritory_SOpsTerritoryId] FOREIGN KEY ([SOpsTerritoryId]) REFERENCES [web].[SOpsTerritory] ([SOpsTerritoryId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SOpsAccountTerritoryId]
    ON [web].[SOpsAccountTerritory]([SOpsAccountTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SOpsAccountId]
    ON [web].[SOpsAccountTerritory]([SOpsAccountId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SOpsTerritoryId]
    ON [web].[SOpsAccountTerritory]([SOpsTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SopsAddressId]
    ON [web].[SOpsAccountTerritory]([SopsAddressId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_CurrentTierId]
    ON [web].[SOpsAccountTerritory]([CurrentTierId] ASC);


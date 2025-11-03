CREATE TABLE [dbo].[SOpsAccountTerritory] (
    [SOpsAccountTerritoryId] INT IDENTITY (1, 1) NOT NULL,
    [SOpsAccountId]          INT NOT NULL,
    [SOpsTerritoryId]        INT NOT NULL,
    [SopsAddressId]          INT NOT NULL,
    [CurrentTierId]          INT NULL,
    [FutureTierId]           INT NULL,
    PRIMARY KEY CLUSTERED ([SOpsAccountTerritoryId] ASC),
    CONSTRAINT [FK_SOpsAccountTerritory_CurrentTierId] FOREIGN KEY ([CurrentTierId]) REFERENCES [dbo].[SOpsAccountTier] ([SOpsAccountTierId]),
    CONSTRAINT [FK_SOpsAccountTerritory_FutureTierId] FOREIGN KEY ([FutureTierId]) REFERENCES [dbo].[SOpsAccountTier] ([SOpsAccountTierId]),
    CONSTRAINT [FK_SOpsAccountTerritory_SOpsAccountId] FOREIGN KEY ([SOpsAccountId]) REFERENCES [dbo].[SOpsAccount] ([SOpsAccountId]),
    CONSTRAINT [FK_SOpsAccountTerritory_SopsAddressId] FOREIGN KEY ([SopsAddressId]) REFERENCES [dbo].[SOpsAddress] ([SOpsAddressId]),
    CONSTRAINT [FK_SOpsAccountTerritory_SOpsTerritoryId] FOREIGN KEY ([SOpsTerritoryId]) REFERENCES [dbo].[SOpsTerritory] ([SOpsTerritoryId])
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SOpsAccountTerritoryId]
    ON [dbo].[SOpsAccountTerritory]([SOpsAccountTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SOpsAccountId]
    ON [dbo].[SOpsAccountTerritory]([SOpsAccountId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SOpsTerritoryId]
    ON [dbo].[SOpsAccountTerritory]([SOpsTerritoryId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_SopsAddressId]
    ON [dbo].[SOpsAccountTerritory]([SopsAddressId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAccountTerritory_CurrentTierId]
    ON [dbo].[SOpsAccountTerritory]([CurrentTierId] ASC);


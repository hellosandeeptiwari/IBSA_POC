CREATE TABLE [dbo].[SOpsTerritory] (
    [SOpsTerritoryId]       INT            IDENTITY (1, 1) NOT NULL,
    [Name]                  NVARCHAR (200) NOT NULL,
    [Description]           NVARCHAR (200) NULL,
    [SOpsParentTerritoryId] INT            NULL,
    [OdsTerritoryId]        NVARCHAR (200) NOT NULL,
    [OdsParentTerritoryId]  NVARCHAR (200) NULL,
    [Status]                NVARCHAR (4)   NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsTerritoryId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsTerritory_SOpsTerritoryId]
    ON [dbo].[SOpsTerritory]([SOpsTerritoryId] ASC);


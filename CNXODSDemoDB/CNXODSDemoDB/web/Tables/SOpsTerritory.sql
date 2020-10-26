CREATE TABLE [web].[SOpsTerritory] (
    [SOpsTerritoryId]             INT            IDENTITY (1, 1) NOT NULL,
    [Name]                        NVARCHAR (200) NOT NULL,
    [Description]                 NVARCHAR (200) NULL,
    [SOpsParentTerritoryId]       INT            NULL,
    [OdsTerritoryId]              NVARCHAR (200) NOT NULL,
    [OdsParentTerritoryId]        NVARCHAR (200) NULL,
    [CurrentTargetCount]          INT            NULL,
    [CurrentNonTargetCount]       INT            NULL,
    [FutureTargetCount]           INT            NULL,
    [FutureNonTargetCount]        INT            NULL,
    [NumberOfCurrentTotalCalls]   INT            NULL,
    [NumberOfCurrentAverageCalls] DECIMAL (6, 2) NULL,
    [NumberOfFutureTotalCalls]    INT            NULL,
    [NumberOfFutureAverageCalls]  DECIMAL (6, 2) NULL,
    [Status]                      NVARCHAR (4)   NOT NULL,
    PRIMARY KEY CLUSTERED ([SOpsTerritoryId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsTerritory_SOpsTerritoryId]
    ON [web].[SOpsTerritory]([SOpsTerritoryId] ASC);


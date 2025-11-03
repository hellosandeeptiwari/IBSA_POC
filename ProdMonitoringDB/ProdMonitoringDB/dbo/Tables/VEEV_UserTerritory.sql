CREATE TABLE [dbo].[VEEV_UserTerritory] (
    [UserTerritoryId]  UNIQUEIDENTIFIER NOT NULL,
    [ExternalId1]      VARCHAR (50)     NOT NULL,
    [EndDate]          DATETIME         NULL,
    [IsActive]         VARCHAR (20)     NULL,
    [LastModifiedById] VARCHAR (50)     NOT NULL,
    [LastModifiedDate] DATETIME         NOT NULL,
    [SystemModstamp]   DATETIME         NOT NULL,
    [TerritoryId]      VARCHAR (50)     NULL,
    [UserId]           VARCHAR (50)     NULL,
    [CustomerId]       INT              NOT NULL,
	CONSTRAINT PK_VEEV_UserTerritory PRIMARY KEY (UserTerritoryId)
);
CREATE NONCLUSTERED INDEX IX_VEEV_UserTerritory_CustomerId_ExternalId1 ON VEEV_UserTerritory(CustomerId, ExternalId1);


CREATE TABLE [dbo].[VEEV_UserTerritory] (
    [UserTerritoryId]  UNIQUEIDENTIFIER NULL,
    [ExternalId1]      VARCHAR (50)     NULL,
    [EndDate]          DATETIME         NULL,
    [IsActive]         VARCHAR (50)     NULL,
    [LastModifiedById] VARCHAR (50)     NULL,
    [LastModifiedDate] DATETIME         NULL,
    [SystemModstamp]   DATETIME         NULL,
    [TerritoryId]      VARCHAR (50)     NULL,
    [UserId]           VARCHAR (50)     NULL,
    [CustomerId]       INT              NULL
);


CREATE TABLE [dbo].[VEEV_Territory] (
    [TerritoryId]       UNIQUEIDENTIFIER NULL,
    [Description]       VARCHAR (100)    NULL,
    [DeveloperName]     VARCHAR (100)    NULL,
    [EndDate]           DATETIME         NULL,
    [ExternalId1]       VARCHAR (50)     NULL,
    [LastModifiedById]  VARCHAR (50)     NULL,
    [LastModifiedDate]  DATETIME         NULL,
    [TerritoryName]     VARCHAR (100)    NULL,
    [ParentTerritoryId] VARCHAR (50)     NULL,
    [SystemModstamp]    DATETIME         NULL,
    [CustomerId]        INT              NULL
);


CREATE TABLE [dbo].[VEEV_Territory] (
    [TerritoryId]       UNIQUEIDENTIFIER NOT NULL,
    [Description]       VARCHAR (100)    NULL,
    [DeveloperName]     VARCHAR (100)    NULL,
    [EndDate]           DATETIME         NULL,
    [ExternalId1]       VARCHAR (50)     NOT NULL,
    [LastModifiedById]  VARCHAR (50)     NOT NULL,
    [LastModifiedDate]  DATETIME         NOT NULL,
    [TerritoryName]     VARCHAR (100)    NOT NULL,
    [ParentTerritoryId] VARCHAR (50)     NULL,
    [SystemModstamp]    DATETIME         NOT NULL,
    [CustomerId]        INT              NOT NULL,
	CONSTRAINT PK_VEEV_Territory PRIMARY KEY (TerritoryId)
);

CREATE NONCLUSTERED INDEX IX_VEEV_Territory_CustomerId_ExternalId1 ON VEEV_Territory(CustomerId, ExternalId1);
CREATE TABLE [dbo].[Staging_UserTerritory] (
    [Id]               VARCHAR (400) NOT NULL,
    [UserId]           VARCHAR (400) NULL,
    [TerritoryId]      VARCHAR (400) NULL,
    [IsActive]         VARCHAR (400) NULL,
    [LastModifiedDate] VARCHAR (400) NULL,
    [LastModifiedById] VARCHAR (400) NULL,
    [SystemModstamp]   VARCHAR (400) NULL,
    CONSTRAINT [PK_Staging_UserTerritory] PRIMARY KEY CLUSTERED ([Id] ASC)
);


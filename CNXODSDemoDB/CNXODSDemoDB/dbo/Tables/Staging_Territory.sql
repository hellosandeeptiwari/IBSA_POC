CREATE TABLE [dbo].[Staging_Territory] (
    [Id]                     VARCHAR (400) NOT NULL,
    [Name]                   VARCHAR (400) NULL,
    [ParentTerritoryId]      VARCHAR (400) NULL,
    [Description]            VARCHAR (400) NULL,
    [LastModifiedDate]       VARCHAR (400) NULL,
    [LastModifiedById]       VARCHAR (400) NULL,
    [SystemModstamp]         VARCHAR (400) NULL,
    [Master_Align_Id_vod__c] VARCHAR (400) NULL,
    CONSTRAINT [PK_Staging_Territory] PRIMARY KEY CLUSTERED ([Id] ASC)
);


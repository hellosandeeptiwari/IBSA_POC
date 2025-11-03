CREATE TABLE [dbo].[Staging_ATL] (
    [Id]                       VARCHAR (400) NOT NULL,
    [OwnerId]                  VARCHAR (400) NULL,
    [IsDeleted]                VARCHAR (400) NULL,
    [Name]                     VARCHAR (400) NULL,
    [CreatedDate]              VARCHAR (400) NULL,
    [CreatedById]              VARCHAR (400) NULL,
    [LastModifiedDate]         VARCHAR (400) NULL,
    [LastModifiedById]         VARCHAR (400) NULL,
    [SystemModstamp]           VARCHAR (400) NULL,
    [MayEdit]                  VARCHAR (400) NULL,
    [IsLocked]                 VARCHAR (400) NULL,
    [Account_vod__c]           VARCHAR (400) NULL,
    [External_ID_vod__c]       VARCHAR (400) NULL,
    [Territory_vod__c]         VARCHAR (400) NULL,
    [Mobile_ID_vod__c]         VARCHAR (400) NULL,
    [Territory_To_Add_vod__c]  VARCHAR (400) NULL,
    [Territory_to_Drop_vod__c] VARCHAR (400) NULL,
    CONSTRAINT [PK_Staging_ATL] PRIMARY KEY CLUSTERED ([Id] ASC)
);


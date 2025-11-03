CREATE TABLE [dbo].[Staging_CallDetail] (
    [Id]                     VARCHAR (400) NOT NULL,
    [IsDeleted]              VARCHAR (400) NULL,
    [Name]                   VARCHAR (400) NULL,
    [CreatedDate]            VARCHAR (400) NULL,
    [CreatedById]            VARCHAR (400) NULL,
    [LastModifiedDate]       VARCHAR (400) NULL,
    [LastModifiedById]       VARCHAR (400) NULL,
    [SystemModstamp]         VARCHAR (400) NULL,
    [MayEdit]                VARCHAR (400) NULL,
    [IsLocked]               VARCHAR (400) NULL,
    [Is_Parent_Call_vod__c]  VARCHAR (400) NULL,
    [Call2_vod__c]           VARCHAR (400) NULL,
    [Product_vod__c]         VARCHAR (400) NULL,
    [Detail_Priority_vod__c] VARCHAR (400) NULL,
    [Mobile_ID_vod__c]       VARCHAR (400) NULL,
    [Override_Lock_vod__c]   VARCHAR (400) NULL,
    [Type_vod__c]            VARCHAR (400) NULL,
    [Detail_Group_vod__c]    VARCHAR (400) NULL,
    CONSTRAINT [PK_Staging_CallDetail] PRIMARY KEY CLUSTERED ([Id] ASC)
);


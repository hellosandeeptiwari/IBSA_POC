CREATE TABLE [dbo].[Staging_VEEV_UserRole] (
    [CaseAccessForAccountOwner]        VARCHAR (20) NULL,
    [ContactAccessForAccountOwner]     VARCHAR (20) NULL,
    [DeveloperName]                    VARCHAR (50) NULL,
    [ForecastUserId]                   VARCHAR (50) NULL,
    [Id]                               VARCHAR (50) NULL,
    [LastModifiedById]                 VARCHAR (50) NULL,
    [LastModifiedDate]                 DATETIME     NULL,
    [MayForecastManagerShare]          BIT          NULL,
    [Name]                             VARCHAR (50) NULL,
    [OpportunityAccessForAccountOwner] VARCHAR (20) NULL,
    [ParentRoleId]                     VARCHAR (50) NULL,
    [PortalAccountId]                  VARCHAR (50) NULL,
    [PortalAccountOwnerId]             VARCHAR (50) NULL,
    [PortalType]                       VARCHAR (50) NULL,
    [RollupDescription]                VARCHAR (50) NULL,
    [SystemModstamp]                   DATETIME     NULL,
    [CustomerId]                       INT          NULL
);


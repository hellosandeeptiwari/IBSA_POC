CREATE TABLE [dbo].[Staging_VEEV_Territory] (
    [AccountAccessLevel]          VARCHAR (50)  NULL,
    [CaseAccessLevel]             VARCHAR (50)  NULL,
    [ContactAccessLevel]          VARCHAR (50)  NULL,
    [Description]                 VARCHAR (100) NULL,
    [DeveloperName]               VARCHAR (100) NULL,
    [ForecastUserId]              VARCHAR (50)  NULL,
    [Id]                          VARCHAR (50)  NULL,
    [LastModifiedById]            VARCHAR (50)  NULL,
    [LastModifiedDate]            DATETIME      NULL,
    [MasterAlignId]               VARCHAR (50)  NULL,
    [MayForecastManagerShare]     VARCHAR (50)  NULL,
    [Name]                        VARCHAR (100) NULL,
    [OpportunityAccessLevel]      VARCHAR (50)  NULL,
    [ParentTerritoryId]           VARCHAR (50)  NULL,
    [RestrictOpportunityTransfer] VARCHAR (50)  NULL,
    [SystemModstamp]              DATETIME      NULL,
    [CustomerId]                  INT           NULL
);


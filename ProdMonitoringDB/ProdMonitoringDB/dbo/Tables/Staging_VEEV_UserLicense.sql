CREATE TABLE [dbo].[Staging_VEEV_UserLicense] (
    [CreatedDate]             DATETIME      NULL,
    [Id]                      VARCHAR (50)  NULL,
    [LastModifiedDate]        DATETIME      NULL,
    [LicenseDefinitionKey]    VARCHAR (100) NULL,
    [MasterLabel]             VARCHAR (100) NULL,
    [Name]                    VARCHAR (100) NULL,
    [Status]                  VARCHAR (20)  NULL,
    [SystemModstamp]          DATETIME      NULL,
    [TotalLicenses]           INT           NULL,
    [UsedLicenses]            INT           NULL,
    [UsedLicensesLastUpdated] DATETIME      NULL,
    [CustomerId]              INT           NULL
);


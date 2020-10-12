CREATE TABLE [dbo].[VEEV_UserLicense] (
    [UserLicenseId]           UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate]             DATETIME         NOT NULL,
    [EndDate]                 DATETIME         NULL,
    [ExternalId1]             VARCHAR (50)     NOT NULL,
    [LastModifiedDate]        DATETIME         NOT NULL,
    [LicenseDefinitionKey]    VARCHAR (100)    NULL,
    [MasterLabel]             VARCHAR (100)    NULL,
    [UserLicenseName]         VARCHAR (100)    NOT NULL,
    [Status]                  VARCHAR (20)     NULL,
    [SystemModstamp]          DATETIME         NOT NULL,
    [TotalLicenses]           INT              NULL,
    [UsedLicenses]            INT              NULL,
    [UsedLicensesLastUpdated] DATETIME         NULL,
    [CustomerId]              INT              NOT NULL,
	CONSTRAINT PK_VEEV_UserLicense PRIMARY KEY (UserLicenseId)
);

CREATE NONCLUSTERED INDEX IX_VEEV_UserLicense_CustomerId_ExternalId1 ON VEEV_UserLicense(CustomerId, ExternalId1);
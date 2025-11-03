CREATE TABLE [dbo].[VEEV_Profile] (
    [ProfileId]        UNIQUEIDENTIFIER NOT NULL,
    [CreatedById]      VARCHAR (50)     NOT NULL,
    [CreatedDate]      DATETIME         NOT NULL,
    [Description]      VARCHAR (200)    NULL,
    [EndDate]          DATETIME         NULL,
    [ExternalId1]      VARCHAR (50)     NOT NULL,
    [LastModifiedById] VARCHAR (50)     NOT NULL,
    [LastModifiedDate] DATETIME         NOT NULL,
    [ProfileName]      VARCHAR (50)     NOT  NULL,
    [SystemModstamp]   DATETIME         NOT NULL,
    [Type]             VARCHAR (50)     NULL,
    [UserLicenseId]    VARCHAR (50)     NULL,
    [UserType]         VARCHAR (50)     NULL,
    [CustomerId]       INT              NOT NULL,
	CONSTRAINT PK_VEEV_Profile PRIMARY KEY (ProfileId)
);

CREATE NONCLUSTERED INDEX IX_VEEV_Profile_CustomerId_ExternalId1 ON VEEV_Profile(CustomerId, ExternalId1);
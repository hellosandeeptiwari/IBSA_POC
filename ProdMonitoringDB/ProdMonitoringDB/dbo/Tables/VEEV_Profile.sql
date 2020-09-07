CREATE TABLE [dbo].[VEEV_Profile] (
    [ProfileId]        UNIQUEIDENTIFIER NULL,
    [CreatedById]      VARCHAR (50)     NULL,
    [CreatedDate]      DATETIME         NULL,
    [Description]      VARCHAR (200)    NULL,
    [EndDate]          DATETIME         NULL,
    [ExternalId1]      VARCHAR (50)     NULL,
    [LastModifiedById] VARCHAR (50)     NULL,
    [LastModifiedDate] DATETIME         NULL,
    [ProfileName]      VARCHAR (50)     NULL,
    [SystemModstamp]   DATETIME         NULL,
    [Type]             VARCHAR (50)     NULL,
    [UserLicenseId]    VARCHAR (50)     NULL,
    [UserType]         VARCHAR (50)     NULL,
    [CustomerId]       INT              NULL
);


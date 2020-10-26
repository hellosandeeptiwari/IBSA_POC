CREATE TABLE [web].[SOpsUser] (
    [SOpsUserId]       INT            IDENTITY (1, 1) NOT NULL,
    [Email]            NVARCHAR (200) NOT NULL,
    [OdsUserId]        NVARCHAR (200) NOT NULL,
    [DisplayName]      NVARCHAR (200) NOT NULL,
    [OdsManagerUserId] NVARCHAR (200) NULL,
    [ExternalId1]      NVARCHAR (200) NULL,
    [ExternalId2]      NVARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([SOpsUserId] ASC)
);


CREATE TABLE [dbo].[VEEV_UserRole] (
    [UserRoleId]        UNIQUEIDENTIFIER NOT NULL,
    [DeveloperName]     VARCHAR (50)     NULL,
    [EndDate]           DATETIME         NULL,
    [ForecastUserId]    VARCHAR (50)     NULL,
    [ExternalId1]       VARCHAR (50)     NOT NULL,
    [LastModifiedById]  VARCHAR (50)     NOT  NULL,
    [LastModifiedDate]  DATETIME         NOT NULL,
    [UserRoleName]      VARCHAR (50)     NOT NULL,
    [ParentRoleId]      VARCHAR (50)     NULL,
    [RollupDescription] VARCHAR (50)     NULL,
    [SystemModstamp]    DATETIME         NOT NULL,
    [CustomerId]        INT              NOT NULL,
	CONSTRAINT PK_VEEV_UserRole PRIMARY KEY (UserRoleId)
);

CREATE NONCLUSTERED INDEX IX_VEEV_UserRole_CustomerId_ExternalId1 ON VEEV_UserRole(CustomerId, ExternalId1);
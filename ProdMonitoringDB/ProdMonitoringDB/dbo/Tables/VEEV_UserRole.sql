CREATE TABLE [dbo].[VEEV_UserRole] (
    [UserRoleId]        UNIQUEIDENTIFIER NULL,
    [DeveloperName]     VARCHAR (50)     NULL,
    [EndDate]           DATETIME         NULL,
    [ForecastUserId]    VARCHAR (50)     NULL,
    [ExternalId1]       VARCHAR (50)     NULL,
    [LastModifiedById]  VARCHAR (50)     NULL,
    [LastModifiedDate]  DATETIME         NULL,
    [UserRoleName]      VARCHAR (50)     NULL,
    [ParentRoleId]      VARCHAR (50)     NULL,
    [RollupDescription] VARCHAR (50)     NULL,
    [SystemModstamp]    DATETIME         NULL,
    [CustomerId]        INT              NULL
);


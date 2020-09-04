CREATE EXTERNAL TABLE [dbo].[ConexusUser] (
    [UserId] INT NOT NULL,
    [UserName] NVARCHAR (MAX) NULL,
    [Email] NVARCHAR (MAX) NULL,
    [FirstName] NVARCHAR (200) NULL,
    [LastName] NVARCHAR (200) NULL,
    [MiddleName] NVARCHAR (200) NULL,
    [WebAddress] NVARCHAR (2000) NULL,
    [Phone] NVARCHAR (200) NULL,
    [LastUpdatedDate] DATETIME NULL,
    [DOB] DATE NULL,
    [Gender] NVARCHAR (4) NULL,
    [TimeZone] NVARCHAR (200) NULL,
    [DisplayName] NVARCHAR (602) NULL,
    [Avatar] VARBINARY (MAX) NULL,
    [AvatarContentType] NVARCHAR (MAX) NULL,
    [DisplayNameWithUserName] NVARCHAR (MAX) NULL,
    [CreatedDate] DATETIME NOT NULL,
    [CustomerId] INT NOT NULL,
    [ManagerUserId] INT NULL,
    [CostCenter] NVARCHAR (4) NULL,
    [ExternalId1] NVARCHAR (200) NULL,
    [Status] VARCHAR (4) NOT NULL
)
    WITH (
    DATA_SOURCE = [ConexusDB],
    SCHEMA_NAME = N'dbo',
    OBJECT_NAME = N'UserProfile'
    );


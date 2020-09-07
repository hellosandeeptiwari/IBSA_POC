CREATE EXTERNAL TABLE [dbo].[ConexusCustomer] (
    [CustomerId] INT NOT NULL,
    [Name] NVARCHAR (200) NOT NULL,
    [Domain] NVARCHAR (4) NULL,
    [Status] NVARCHAR (4) NOT NULL,
    [CreatedBy] INT NOT NULL,
    [LastUpdatedDate] DATETIME NOT NULL,
    [CreatedDate] DATETIME NOT NULL,
    [Description] NVARCHAR (MAX) NULL,
    [BusinessPhone1] NVARCHAR (50) NULL,
    [BusinessPhone2] NVARCHAR (50) NULL,
    [BusinessFax] NVARCHAR (50) NULL,
    [WebAddress] NVARCHAR (2000) NULL,
    [UpdatedBy] INT NOT NULL,
    [UserHomeWebAddress] NVARCHAR (2000) NULL,
    [ShortName] NVARCHAR (4) NOT NULL,
    [DisplayName] NVARCHAR (220) NULL,
    [BaseCurrency] NVARCHAR (4) NOT NULL,
    [WeekStartDay] INT NOT NULL
)
    WITH (
    DATA_SOURCE = [ConexusDB],
    SCHEMA_NAME = N'dbo',
    OBJECT_NAME = N'Customer'
    );


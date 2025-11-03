
CREATE TABLE [dbo].[Staging_Boast_Customer](
	[CustomerId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Domain] [nvarchar](4) NULL,
	[Status] [nvarchar](4) NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[LastUpdatedDate] [datetime] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[Description] [nvarchar](max) NULL,
	[BusinessPhone1] [nvarchar](50) NULL,
	[BusinessPhone2] [nvarchar](50) NULL,
	[BusinessFax] [nvarchar](50) NULL,
	[WebAddress] [nvarchar](2000) NULL,
	[UpdatedBy] [int] NOT NULL,
	[UserHomeWebAddress] [nvarchar](2000) NULL,
	[ShortName] [nvarchar](4) NOT NULL,
	[DisplayName]  AS ((((([Name]+' (')+[ShortName])+' - ')+ltrim(str([CustomerId])))+')'),
	[BaseCurrency] [nvarchar](4) NOT NULL,
	[WeekStartDay] [int] NOT NULL,
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([CustomerId] ASC)
)
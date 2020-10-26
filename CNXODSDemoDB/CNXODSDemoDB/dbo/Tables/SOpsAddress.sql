CREATE TABLE [dbo].[SOpsAddress] (
    [SOpsAddressId] INT             IDENTITY (1, 1) NOT NULL,
    [OdsAddressId]  NVARCHAR (200)  NOT NULL,
    [AddressLine1]  NVARCHAR (2000) NOT NULL,
    [AddressLine2]  NVARCHAR (2000) NULL,
    [City]          NVARCHAR (200)  NULL,
    [State]         NVARCHAR (4)    NULL,
    [Country]       NVARCHAR (4)    NULL,
    [ZipCode]       NVARCHAR (50)   NULL,
    PRIMARY KEY CLUSTERED ([SOpsAddressId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAddress_SOpsAddressId]
    ON [dbo].[SOpsAddress]([SOpsAddressId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SOpsAddress_OdsAddressId]
    ON [dbo].[SOpsAddress]([OdsAddressId] ASC);


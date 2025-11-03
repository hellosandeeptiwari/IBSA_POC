CREATE TABLE [dbo].[Reporting_AU_AccountDetails] (
    [AccountCRMId]  VARCHAR (50)  NULL,
    [AccountName]   VARCHAR (200) NULL,
    [AccountType]   VARCHAR (200) NULL,
    [NPINumber]     VARCHAR (50)  NULL,
    [TargetType]    VARCHAR (25)  NULL,
    [Specialty1]    VARCHAR (200) NULL,
    [Specialty2]    VARCHAR (200) NULL,
    [AddressCRMId]  VARCHAR (50)  NULL,
    [AddressLine1]  VARCHAR (200) NULL,
    [AddressLine2]  VARCHAR (200) NULL,
    [City]          VARCHAR (50)  NULL,
    [State]         VARCHAR (50)  NULL,
    [ZipCode]       VARCHAR (50)  NULL,
    [Territory]     VARCHAR (200) NULL,
    [CallCount]     INT           NULL,
    [PrimaryParent] VARCHAR (200) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_AU_AccountDetails_Specialty]
    ON [dbo].[Reporting_AU_AccountDetails]([Specialty1] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_AU_AccountDetails_TargetType]
    ON [dbo].[Reporting_AU_AccountDetails]([TargetType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Reporting_AU_AccountDetails_Territory]
    ON [dbo].[Reporting_AU_AccountDetails]([Territory] ASC);


CREATE TABLE [dbo].[Test_SalesAccount] (
    [ClientId]     INT            NOT NULL,
    [ReportNumber] INT            NOT NULL,
    [TenantId]     INT            NULL,
    [IMSID]        NVARCHAR (200) NULL,
    [Specialty]    NVARCHAR (200) NULL,
    [ME]           NVARCHAR (100) NULL,
    [L_Name]       NVARCHAR (200) NULL,
    [F_Name]       NVARCHAR (200) NULL,
    [M_Initial]    NVARCHAR (200) NULL,
    [DisplayName]  NVARCHAR (MAX) NULL,
    [Address]      NVARCHAR (200) NULL,
    [City]         NVARCHAR (100) NULL,
    [State]        NVARCHAR (100) NULL,
    [ZipCode]      NVARCHAR (50)  NOT NULL,
    [NPI]          NVARCHAR (50)  NULL,
    [PDRPFlag]     BIT            NULL
);


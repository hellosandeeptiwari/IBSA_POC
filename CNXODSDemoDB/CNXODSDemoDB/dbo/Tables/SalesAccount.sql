CREATE TABLE [dbo].[SalesAccount] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [IMSID]       NVARCHAR (200) NULL,
    [Specialty]   NVARCHAR (200) NULL,
    [ME]          NVARCHAR (100) NULL,
    [L_Name]      NVARCHAR (200) NULL,
    [F_Name]      NVARCHAR (200) NULL,
    [DisplayName] NVARCHAR (200) NULL,
    [Address]     NVARCHAR (200) NULL,
    [City]        NVARCHAR (100) NULL,
    [State]       NVARCHAR (100) NULL,
    [ZipCode]     NVARCHAR (50)  NOT NULL,
    [NPI]         NVARCHAR (50)  NULL,
    CONSTRAINT [PK_SalesAccount_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SalesAccount_IMSId]
    ON [dbo].[SalesAccount]([IMSID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SalesAccount_ZipCode]
    ON [dbo].[SalesAccount]([ZipCode] ASC);


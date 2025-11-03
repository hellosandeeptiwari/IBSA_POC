CREATE TABLE [dbo].[CMS_DisplayFields] (
    [DisplayFieldId]     INT            IDENTITY (1, 1) NOT NULL,
    [TableName]          NVARCHAR (200) NOT NULL,
    [ColumnName]         NVARCHAR (200) NOT NULL,
    [DisplayName]        NVARCHAR (200) NOT NULL,
    [SortOrder]          INT            NULL,
    [ShowInScreen]       BIT            CONSTRAINT [DF_CMS_DisplayFields_ShowInScreen] DEFAULT ((0)) NOT NULL,
    [CreatedUtcDate]     DATETIME       NOT NULL,
    [UpdatedUtcDate]     DATETIME       NULL,
    [UpdatedBy]          INT            NULL,
    [AliasName]          NVARCHAR (200) NULL,
    [ShowInSearchResult] BIT            NOT NULL,
    CONSTRAINT [PK_CMS_DisplayFields] PRIMARY KEY CLUSTERED ([DisplayFieldId] ASC)
);


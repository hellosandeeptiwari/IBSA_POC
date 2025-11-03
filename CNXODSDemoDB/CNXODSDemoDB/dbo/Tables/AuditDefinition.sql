CREATE TABLE [dbo].[AuditDefinition] (
    [AuditDefinitionId] INT            IDENTITY (1, 1) NOT NULL,
    [TableName]         NVARCHAR (400) NOT NULL,
    [ColumnName]        NVARCHAR (400) NOT NULL,
    CONSTRAINT [PK_AuditDefinition] PRIMARY KEY CLUSTERED ([AuditDefinitionId] ASC)
);


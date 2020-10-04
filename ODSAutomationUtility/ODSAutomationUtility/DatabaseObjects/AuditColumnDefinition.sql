
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AuditColumnDefinition')
    CREATE TABLE [dbo].[AuditColumnDefinition] (
        [AuditColumnDefinitionId]	INT	IDENTITY (1, 1) NOT NULL,
        [AuditTableDefinitionId]	INT NOT NULL,
        [ColumnName]				NVARCHAR (400) NOT NULL,
        CONSTRAINT [PK_AuditColumnDefinition] PRIMARY KEY CLUSTERED ([AuditColumnDefinitionId] ASC),
	    CONSTRAINT FK_AuditColumnDefinition_AuditTableDefinition_1 FOREIGN KEY ([AuditTableDefinitionId]) REFERENCES [AuditTableDefinition]([AuditTableDefinitionId])
    );

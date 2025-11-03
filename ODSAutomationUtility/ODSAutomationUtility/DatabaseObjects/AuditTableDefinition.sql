
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AuditTableDefinition')
    CREATE TABLE [dbo].[AuditTableDefinition] (
        [AuditTableDefinitionId]	INT		IDENTITY (1, 1) NOT NULL,
        [TableName]					NVARCHAR (400) NOT NULL,
	    PrimaryKeyColumnName		NVARCHAR (400) NOT NULL,
        CONSTRAINT [PK_AuditTableDefinition] PRIMARY KEY CLUSTERED ([AuditTableDefinitionId] ASC)
    );

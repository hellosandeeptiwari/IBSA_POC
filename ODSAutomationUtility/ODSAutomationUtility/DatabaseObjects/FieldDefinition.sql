
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FieldDefinition')
	CREATE TABLE FieldDefinition
	(
		FieldDefinitionId	INT NOT NULL IDENTITY(1, 1),
		ObjectName			VARCHAR(400)	NOT NULL,
		ObjectAPIName		VARCHAR(400)	NOT NULL,
		FieldName			VARCHAR(400)	NOT NULL,
		FieldAPIName		VARCHAR(400)	NULL,
		DataType			VARCHAR(200)	NOT NULL,
		SCDRequired			BIT				NOT NULL,
		CONSTRAINT PK_FieldDefinition PRIMARY KEY (FieldDefinitionId)
	);

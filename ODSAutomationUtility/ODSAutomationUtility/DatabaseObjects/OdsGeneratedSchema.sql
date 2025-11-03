
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'OdsGeneratedSchema')
	CREATE TABLE OdsGeneratedSchema
	(
		OdsTableName			VARCHAR(400)	NOT NULL,
		SCDRequired				BIT				NOT NULL,
		StagingTableSchema		VARCHAR(MAX),
		ProductionTableSchema	VARCHAR(MAX),
		TransformationSPSchema	VARCHAR(MAX),
		UpdatedDate				DATETIME,
		CONSTRAINT PK_OdsGeneratedSchema PRIMARY KEY (OdsTableName)
	);


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'VeevaOdsFieldMapping')
	CREATE TABLE VeevaOdsFieldMapping
	(
		VeevaObjectAPIName		VARCHAR(400)	NOT NULL,
		OdsTableName			VARCHAR(400)	NOT NULL,
		VeevaFieldAPIName		VARCHAR(400)	NULL,
		OdsColumnName			VARCHAR(200)	NOT NULL,
		SCDRequired				BIT				NOT NULL,
		OdsDataType				VARCHAR(100)
	);


IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'VeevaOdsDataTypeMapping')
	CREATE TABLE VeevaOdsDataTypeMapping
	(
		VeevaType		VARCHAR(100),
		OdsType			VARCHAR(100),
		ExactMatch		BIT
	);

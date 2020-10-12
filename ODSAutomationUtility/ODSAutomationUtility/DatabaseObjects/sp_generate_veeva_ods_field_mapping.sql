CREATE OR ALTER PROCEDURE sp_generate_veeva_ods_field_mapping
AS
BEGIN

	SET NOCOUNT ON;


	TRUNCATE TABLE VeevaOdsDataTypeMapping;

	INSERT INTO VeevaOdsDataTypeMapping
	VALUES 
	-- Text Types
	('Email', 'VARCHAR', 1), ('Fax', 'VARCHAR', 1), ('Hierarchy', 'VEEVAID', 1), ('Long Text Area', 'VARCHAR', 0), 
	('Lookup', 'VEEVAID', 0), ('Master-Detail', 'VEEVAID', 0), ('Name', 'VARCHAR', 1), ('Phone', 'VARCHAR', 1), 
	('Picklist', 'VARCHAR', 1), ('Record Type', 'VEEVAID', 0), ('Rich Text Area', 'VARCHAR', 0), 
	('Text', 'VARCHAR', 0), ('Text Area', 'VARCHAR', 0), ('URL', 'VARCHAR', 0), ('Auto Number', 'VARCHAR', 0), 
	('Formula (Text)', 'VARCHAR', 0),

	-- Boolean Types
	('<Check box>', 'BIT', 1), ('Checkbox', 'BIT', 1), 

	-- Number Types
	('Numeric', 'DECIMAL', 0), ('Percent', 'DECIMAL', 0), ('Formula (Number)', 'INT', 0), ('Number', 'INT', 0), 

	-- Date Types
	('Date', 'DATE', 1), ('Date/Time', 'DATETIME', 1);


	TRUNCATE TABLE VeevaOdsFieldMapping;

	; WITH cte_VeevaOdsFieldMapping AS
	(
		SELECT
			FD.ObjectAPIName AS VeevaObjectAPIName, 
			--REPLACE(REPLACE(FD.ObjectName, ' ', ''), ' ', '') AS OdsTableName,
			[dbo].[fn_GetStringWithoutDigits](REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(FD.ObjectAPIName, '_vod__c', ''), '__c', ''), '_CNX', ''), '_CN', ''), 'Association', '')) AS OdsTableName,
			FD.FieldAPIName AS VeevaFieldAPIName, 
			REPLACE(REPLACE(REPLACE(REPLACE(FD.FieldAPIName, '_vod__c', ''), '__c', ''), '_CNX', ''), '_CN', '') AS OdsColumnName, 
			FD.SCDRequired,
			CASE
				-- Veeva CRM Id's are always 18 character strings, hence using CHAR datatype. Any data we load from Salesforce into ODS will nto involve 15 char Id's.
				WHEN DTM.OdsType = 'VEEVAID' THEN 'CHAR(18)'
				-- Formula (Text) datatypes in Veeva are converted to varchar(400).
				WHEN DTM.OdsType = 'VARCHAR' AND FD.DataType LIKE 'Formula%' THEN DTM.OdsType + '(400)'
				-- Auto Number datatypes in Veeva are actually strings since they ususally contain some pre-fixed string like 'CNX-'. Hence it is better to use string datatype like VARCHAR in ODS.
				WHEN DTM.OdsType = 'VARCHAR' AND FD.DataType LIKE '%Auto%Number%' THEN DTM.OdsType + '(400)'
				-- If the length of the string datatype in Veeva is more than 8000 characters then we should use MAX datatype.
				WHEN DTM.OdsType = 'VARCHAR' AND CHARINDEX('(', FD.DataType) > 0 AND CAST(SUBSTRING(FD.DataType, CHARINDEX('(', FD.DataType) + 1, CHARINDEX(')', FD.DataType) - CHARINDEX('(', FD.DataType) - 1) AS INT) > 8000 THEN DTM.OdsType + '(MAX)'
				-- If the length of the string datatype in Veeva is less than 8000 characters then we should use the exact length string datatype.
				WHEN DTM.OdsType = 'VARCHAR' AND CHARINDEX('(', FD.DataType) > 0 THEN DTM.OdsType + SUBSTRING(FD.DataType, CHARINDEX('(', FD.DataType), CHARINDEX(')', FD.DataType) - CHARINDEX('(', FD.DataType) + 1)
				-- If the length is not provided in Veeva, then we will use 400 as the default length.
				WHEN DTM.OdsType = 'VARCHAR' THEN DTM.OdsType + '(400)'
				ELSE DTM.OdsType
			END AS OdsDataType,
			ROW_NUMBER() OVER(PARTITION BY FD.ObjectName, FD.FieldAPIName ORDER BY FD.SCDRequired DESC) AS RowNum
		FROM FieldDefinition FD
		LEFT OUTER JOIN VeevaOdsDataTypeMapping DTM ON (DTM.ExactMatch = 1 AND FD.DataType = DTM.VeevaType) OR (DTM.ExactMatch = 0 AND FD.DataType LIKE DTM.VeevaType + '%')
	)
	INSERT INTO VeevaOdsFieldMapping
	SELECT
		VeevaObjectAPIName, 
		-- If the ODS table name has multiple words, then use Camel Case. Else use the original field name from Veeva.
		CASE WHEN CHARINDEX('_', OdsTableName) > 0 THEN REPLACE(dbo.fn_GetCamelCase(REPLACE(OdsTableName, '_', ' ')), ' ', '')
			ELSE OdsTableName
		END AS OdsTableName,
		VeevaFieldAPIName, 
		-- If the ODS column name has multiple words, then use Camel Case. Else use the original field name from Veeva.
		CASE WHEN CHARINDEX('_', OdsColumnName) > 0 THEN REPLACE(dbo.fn_GetCamelCase(REPLACE(OdsColumnName, '_', ' ')), ' ', '')
			ELSE REPLACE(OdsColumnName, ' ', '')
		END AS OdsColumnName,
		SCDRequired, OdsDataType
	FROM cte_VeevaOdsFieldMapping 
	WHERE RowNum = 1;

	-- Add the word 'Id' at the end of any Veeva Id columns if it is not already present.
	UPDATE VeevaOdsFieldMapping SET OdsColumnName = CASE WHEN RIGHT(OdsColumnName, 2) <> 'Id' THEN OdsColumnName + 'Id' ELSE OdsColumnName END
	WHERE OdsDataType = 'CHAR(18)';

	-- If any VeevaId columns have digits, remove them.
	UPDATE VeevaOdsFieldMapping SET 
		OdsColumnName = [dbo].[fn_GetStringWithoutDigits](OdsColumnName) 
	WHERE OdsDataType = 'CHAR(18)' AND OdsColumnName LIKE '%Id'

	IF EXISTS (SELECT 1 FROM VeevaOdsFieldMapping WHERE OdsDataType IS NULL)
		THROW 51000, 'There is ods datatype information missing for few rows in VeevaOdsFieldMapping. Please check the Veeva Ods column mapping.', 1;

END
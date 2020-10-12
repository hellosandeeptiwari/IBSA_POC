
CREATE OR ALTER PROCEDURE sp_generate_ods_objects
	@strVeevaObjectAPIName VARCHAR(400),
	@bCreateObjectsInDatabase BIT = 0,
	@bSCDNeeded BIT = 1
AS
BEGIN

SET NOCOUNT ON

DECLARE 
	@iOdsTableCount INT, @iMaxColumnNameLength AS INT, 
	@strTableType VARCHAR(20), @strOdsTableName VARCHAR(400), 
	@strColumnListScript AS NVARCHAR(4000), @strOdsTableScript NVARCHAR(MAX), -- NVARCHAR datatype is mandatory if you want to execute the script.
	@bSCDRequired BIT;

DECLARE @tableColumnList TABLE (ColumnList VARCHAR(4000));
DECLARE @tableColumnMapping TABLE (Id INT IDENTITY(1, 1), StagingColumnName VARCHAR(400), ProductionColumnName VARCHAR(400));

CREATE TABLE #temp_OdsTableDefinition
(
	OdsTableName			VARCHAR(400)	NOT NULL,
	OdsColumnName			VARCHAR(200)	NOT NULL,
	SCDRequired				BIT				NOT NULL,
	OdsDataType				VARCHAR(100)
);

---------------------------------------------- Staging & Production Code ----------------------------------------------

IF @strVeevaObjectAPIName = 'All'
	INSERT INTO #temp_OdsTableDefinition
	SELECT OdsTableName, OdsColumnName, SCDRequired, OdsDataType 
	FROM VeevaOdsFieldMapping
	ORDER BY OdsTableName, OdsColumnName;
ELSE
	INSERT INTO #temp_OdsTableDefinition
	SELECT OdsTableName, OdsColumnName, SCDRequired, OdsDataType 
	FROM VeevaOdsFieldMapping
	WHERE VeevaObjectAPIName = @strVeevaObjectAPIName
	ORDER BY OdsTableName, OdsColumnName;

IF NOT EXISTS(SELECT 1 FROM #temp_OdsTableDefinition)
	THROW 51000, 'There is no column informtion available for the given Veeva object API name. Please check the Veeva object API name.', 1;

-- Get the count of all the tables that require script generation.
-- We are repeating the WHILE loop two times. First to generate Staging table and second to generate Production table.
SELECT @iOdsTableCount = COUNT(DISTINCT OdsTableName) * 2 FROM #temp_OdsTableDefinition;

-- Loop through all the tables in the temp table to generate script for Staging & Production tables.
WHILE @iOdsTableCount > 0
BEGIN

	-- Clear the table variable so that any column list from previous iteration is not accidentally used.
	DELETE @tableColumnList;

	-- Get the ODS table name.
	SELECT TOP 1 @strOdsTableName = OdsTableName FROM #temp_OdsTableDefinition;

	-- We are repeating the WHILE loop two times. First to generate Staging table and second to generate Production table.
	SET @strTableType = CASE WHEN @iOdsTableCount % 2 = 0 THEN 'Staging' ELSE 'Production' END;

	-- Getting the MAX column name length to format the script with proper indentation.
	SELECT @iMaxColumnNameLength = MAX(LEN(OdsColumnName)), @bSCDRequired = MAX(CAST(SCDRequired AS INT)) 
	FROM #temp_OdsTableDefinition WHERE OdsTableName = @strOdsTableName;

	-- If the MAX column name length is less than the common columns max length, then use the common columns max length.
	SELECT @iMaxColumnNameLength = CASE WHEN @iMaxColumnNameLength < 22 THEN 22 ELSE @iMaxColumnNameLength END;

	-- Insert table list into schema table.
	IF NOT EXISTS (SELECT 1 FROM OdsGeneratedSchema O WHERE O.OdsTableName = @strOdsTableName)
		INSERT INTO OdsGeneratedSchema(OdsTableName, SCDRequired)
		SELECT MAX(OdsTableName), MAX(CAST(SCDRequired AS INT)) FROM #temp_OdsTableDefinition T
		WHERE T.OdsTableName = @strOdsTableName;

	-- Step-1: Adding the CREATE statement.
	SET @strOdsTableScript = 
'
CREATE TABLE ' + CASE WHEN @strTableType = 'Staging' THEN 'Staging_' + @strOdsTableName WHEN @strOdsTableName = 'User' THEN '[User]' ELSE @strOdsTableName END + '
(';

	-- Step-2: Add SCD specific fields: Id, StartDate, EndDate
	IF @bSCDRequired = 1 AND @strTableType = 'Production'
	BEGIN

		SET @strColumnListScript = 
		'SELECT 
			CHAR(13) + CHAR(9) + CAST(''Id'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'INT IDENTITY(1, 1) NOT NULL,'' +
			CHAR(13) + CHAR(9) + CAST(''StartDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
			CHAR(13) + CHAR(9) + CAST(''EndDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NULL,'''

		INSERT @tableColumnList EXEC SP_EXECUTESQL @strColumnListScript;
	END

	-- Step-3: Add VeevaId column which is Id field from Veeva.
	SET @strColumnListScript = 
	'SELECT 
		CHAR(13) + CHAR(9) + CAST(''VeevaId'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'''

	INSERT @tableColumnList EXEC SP_EXECUTESQL @strColumnListScript;


	-- Step-4: Add all the columns from VeevaOdsFieldMapping which are the actual fields from Veeva for each Veeva object.
	-- Any columns which are SQL keywords shoudl be enclosed in [] brackets.
	SET @strColumnListScript = '
	SELECT ColumnList + '','' FROM 
	(
		SELECT
			STRING_AGG(CHAR(13) + CHAR(9) + CAST(CASE WHEN OdsColumnName IN (''Primary'', ''User'') THEN ''['' + OdsColumnName + '']'' ELSE OdsColumnName END AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + CHAR(9) + CHAR(9) + OdsDataType, '','') AS ColumnList
		FROM VeevaOdsFieldMapping
		WHERE OdsTableName = ''' + @strOdsTableName + '''
		GROUP BY OdsTableName 
	) AS T;'

	INSERT @tableColumnList EXEC SP_EXECUTESQL @strColumnListScript;

	-- Step-5: Add Common fields, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, SystemModstamp, IsDeleted columns from Veeva.
	IF @strTableType = 'Staging'
		IF @strOdsTableName IN ('User', 'RecordType') -- IsDeleted field does not exist in these objects.
			SET @strColumnListScript =
			'SELECT 
				CHAR(13) + CHAR(9) + CAST(''CreatedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''CreatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''LastModifiedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''LastModifiedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''SystemModstamp'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,''';
		ELSE IF @strOdsTableName IN ('Territory', 'UserTerritory') -- IsDeleted, CreatedDate, CreatedById fields does not exist in these objects.
			SET @strColumnListScript =
			'SELECT 
				CHAR(13) + CHAR(9) + CAST(''LastModifiedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''LastModifiedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''SystemModstamp'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,''';
		ELSE
			SET @strColumnListScript =
			'SELECT 
				CHAR(13) + CHAR(9) + CAST(''CreatedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''CreatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''LastModifiedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''LastModifiedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''SystemModstamp'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''IsDeleted'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'BIT NOT NULL,''';
	ELSE IF @strTableType = 'Production'
		IF @strOdsTableName IN ('User', 'RecordType') -- IsDeleted field does not exist in these objects.
			SET @strColumnListScript =
			'SELECT 
				CHAR(13) + CHAR(9) + CAST(''VeevaCreatedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaCreatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaLastModifiedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaLastModifiedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaSystemModstamp'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''CreatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''UpdatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,''';
		ELSE IF @strOdsTableName IN ('Territory', 'UserTerritory') -- IsDeleted, CreatedDate, CreatedById fields does not exist in these objects.
			SET @strColumnListScript =
			'SELECT 
				CHAR(13) + CHAR(9) + CAST(''VeevaLastModifiedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaLastModifiedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaSystemModstamp'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''CreatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''UpdatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,''';
		ELSE
			SET @strColumnListScript =
			'SELECT 
				CHAR(13) + CHAR(9) + CAST(''VeevaCreatedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaCreatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaLastModifiedById'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'CHAR(18) NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaLastModifiedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''VeevaSystemModstamp'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''IsDeleted'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'BIT NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''CreatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,'' +
				CHAR(13) + CHAR(9) + CAST(''UpdatedDate'' AS CHAR(' + CAST(@iMaxColumnNameLength AS VARCHAR) + ')) + ''' + CHAR(9) + CHAR(9) + 'DATETIME NOT NULL,''';

	INSERT @tableColumnList EXEC SP_EXECUTESQL @strColumnListScript;
	
	SELECT @strOdsTableScript = @strOdsTableScript + ColumnList FROM @tableColumnList;

	-- Step-6: Add Primary Key constraint
	SET @strOdsTableScript = @strOdsTableScript + '
	CONSTRAINT PK_' + CASE WHEN @strTableType = 'Staging' THEN 'Staging_' ELSE '' END + @strOdsTableName + ' PRIMARY KEY (' + CASE WHEN @bSCDRequired = 1 AND @strTableType = 'Production' THEN 'Id' ELSE 'VeevaId' END + ')
);


CREATE NONCLUSTERED INDEX IX_' + CASE WHEN @strTableType = 'Staging' THEN 'Staging_' ELSE '' END + 
@strOdsTableName + '_' + CASE WHEN @strTableType = 'Staging' THEN '' ELSE 'Veeva' END + 'SystemModstamp ON ' + 
CASE WHEN @strTableType = 'Staging' THEN 'Staging_' + @strOdsTableName WHEN @strOdsTableName = 'User' THEN '[User]' ELSE @strOdsTableName END + 
'(' + CASE WHEN @strTableType = 'Staging' THEN '' ELSE 'Veeva' END + 'SystemModstamp);
'

	-- Step-7: Add indexes
	IF @bSCDRequired = 1 AND @strTableType = 'Production'
	BEGIN
		SET @strOdsTableScript = @strOdsTableScript + '
CREATE NONCLUSTERED INDEX IX_' + @strOdsTableName + '_VeevaId ON ' + CASE WHEN @strOdsTableName = 'User' THEN '[User]' ELSE @strOdsTableName END + '(VeevaId);

CREATE NONCLUSTERED INDEX IX_' + @strOdsTableName + '_EndDate ON ' + CASE WHEN @strOdsTableName = 'User' THEN '[User]' ELSE @strOdsTableName END + '(EndDate);
'
	END

	-- Step-8: Add Additional Indexes on Production tables.
	IF @strTableType = 'Production'
	BEGIN

		SET @strOdsTableScript = @strOdsTableScript + 
			CASE 
				WHEN @strOdsTableName = 'Account' THEN
'
CREATE NONCLUSTERED INDEX IX_Account_RecordTypeId ON Account(RecordTypeId);
'
				WHEN @strOdsTableName = 'AccountTerritoryLoader' THEN
'
CREATE NONCLUSTERED INDEX IX_AccountTerritoryLoader_AccountId ON AccountTerritoryLoader(AccountId);

CREATE NONCLUSTERED INDEX IX_AccountTerritoryLoader_Territory ON AccountTerritoryLoader(Territory);
'
				WHEN @strOdsTableName = 'Address' THEN
'
CREATE NONCLUSTERED INDEX IX_Address_AccountId ON Address(AccountId);

CREATE NONCLUSTERED INDEX IX_Address_Zip ON Address(Zip);
'
				WHEN @strOdsTableName = 'Affiliation' THEN
'
CREATE NONCLUSTERED INDEX IX_Affiliation_FromAccountId ON Affiliation(FromAccountId);

CREATE NONCLUSTERED INDEX IX_Affiliation_ToAccountId ON Affiliation(ToAccountId);
'
				WHEN @strOdsTableName = 'Call' THEN
'
CREATE NONCLUSTERED INDEX IX_Call_AccountId ON Call(AccountId);

CREATE NONCLUSTERED INDEX IX_Call_Territory ON Call(Territory);

CREATE NONCLUSTERED INDEX IX_Call_OwnerId ON Call(OwnerId);

CREATE NONCLUSTERED INDEX IX_Call_ParentCallId ON Call(ParentCallId);
'
				WHEN @strOdsTableName = 'CallDetail' THEN
'
CREATE NONCLUSTERED INDEX IX_CallDetail_CallId ON CallDetail(CallId);

CREATE NONCLUSTERED INDEX IX_CallDetail_ProductId ON CallDetail(ProductId);
'
				WHEN @strOdsTableName = 'CallSample' THEN
'
CREATE NONCLUSTERED INDEX IX_CallSample_CallId ON CallSample(CallId);
'
				WHEN @strOdsTableName = 'MedicalInquiry' THEN
'
CREATE NONCLUSTERED INDEX IX_MedicalInquiry_AccountId ON MedicalInquiry(AccountId);

CREATE NONCLUSTERED INDEX IX_MedicalInquiry_CallId ON MedicalInquiry(CallId);

CREATE NONCLUSTERED INDEX IX_MedicalInquiry_OwnerId ON MedicalInquiry(OwnerId);
'
				WHEN @strOdsTableName = 'MedicalInsight' THEN
'
CREATE NONCLUSTERED INDEX IX_MedicalInsight_AccountId ON MedicalInsight(AccountId);

CREATE NONCLUSTERED INDEX IX_MedicalInsight_OwnerId ON MedicalInsight(OwnerId);
'
				WHEN @strOdsTableName = 'TimeOffTerritory' THEN
'
CREATE NONCLUSTERED INDEX IX_TimeOffTerritory_OwnerId ON TimeOffTerritory(OwnerId);
'
				WHEN @strOdsTableName = 'UserTerritory' THEN
'
CREATE NONCLUSTERED INDEX IX_UserTerritory_TerritoryId ON UserTerritory(TerritoryId);

CREATE NONCLUSTERED INDEX IX_UserTerritory_UserId ON UserTerritory(UserId);
'
				WHEN @strOdsTableName = 'ZipToTerr' THEN
'
CREATE NONCLUSTERED INDEX IX_ZipToTerr_Territory ON ZipToTerr(Territory);

CREATE NONCLUSTERED INDEX IX_ZipToTerr_Name ON ZipToTerr(Name);
'
				ELSE ''
			END
	END

	--SELECT @strOdsTableScript;
	IF @bCreateObjectsInDatabase = 1
		EXECUTE sp_executesql @strOdsTableScript;

	-- Delete the table only when the Production table has been generated.
	IF @strTableType = 'Production'
	BEGIN
		
		-- SCD Setup. All the SCD specific objects(tables & SP) will be deployed by the .NET Utility.
		-- First condition ensures that there is atleast one column in the table which requires SCD.
		-- Second condition checks if SCD should be setup or not(this depend on ODS or BRF environment).
		-- Third condition ensures that there is no SCD column data in Audit tables.
		IF	@bSCDRequired = 1 
			AND @bSCDNeeded = 1
			AND NOT EXISTS (SELECT 1 FROM [AuditTableDefinition] T 
							INNER JOIN [AuditColumnDefinition] C ON T.AuditTableDefinitionId = C.AuditTableDefinitionId
							WHERE T.TableName = @strOdsTableName)
		BEGIN
			INSERT INTO [AuditTableDefinition]
			VALUES (@strOdsTableName, 'VeevaId');

			DECLARE @iAuditTableDefinitionId INT
			SELECT @iAuditTableDefinitionId = AuditTableDefinitionId FROM [AuditTableDefinition] WHERE TableName = @strOdsTableName;

			INSERT INTO [AuditColumnDefinition]
			SELECT @iAuditTableDefinitionId, OdsColumnName FROM #temp_OdsTableDefinition 
			WHERE OdsTableName = @strOdsTableName AND SCDRequired = 1;

			EXEC sp_generate_trigger @strOdsTableName;

		END		

		DELETE FROM #temp_OdsTableDefinition WHERE OdsTableName = @strOdsTableName;
		UPDATE OdsGeneratedSchema SET ProductionTableSchema = @strOdsTableScript, UpdatedDate = GETDATE() WHERE OdsTableName = @strOdsTableName;
	END
	ELSE
	BEGIN
		UPDATE OdsGeneratedSchema SET StagingTableSchema = @strOdsTableScript, UpdatedDate = GETDATE() WHERE OdsTableName = @strOdsTableName;
	END

	-- Decrease the Loop counter so that it does not go into an infinite loop.
	SET @iOdsTableCount = @iOdsTableCount - 1;
END


------------------------------------------------ Transformation SP Code ----------------------------------------------

TRUNCATE TABLE #temp_OdsTableDefinition;

IF @strVeevaObjectAPIName = 'All'
	INSERT INTO #temp_OdsTableDefinition
	SELECT OdsTableName, OdsColumnName, SCDRequired, OdsDataType 
	FROM VeevaOdsFieldMapping
	ORDER BY OdsTableName, OdsColumnName;
ELSE
	INSERT INTO #temp_OdsTableDefinition
	SELECT OdsTableName, OdsColumnName, SCDRequired, OdsDataType 
	FROM VeevaOdsFieldMapping
	WHERE VeevaObjectAPIName = @strVeevaObjectAPIName
	ORDER BY OdsTableName, OdsColumnName;

-- Get the count of all the tables that require script generation.
SELECT @iOdsTableCount = COUNT(DISTINCT OdsTableName) FROM #temp_OdsTableDefinition;

-- Loop through all the tables in the temp table to generate script for Transformation SP.
WHILE @iOdsTableCount > 0
BEGIN

	-- Clear the table variable so that any column mapping from previous iteration is not accidentally used.
	DELETE @tableColumnMapping;

	-- Get the ODS table name.
	SELECT TOP 1 @strOdsTableName = OdsTableName FROM #temp_OdsTableDefinition;

	SELECT @bSCDRequired = MAX(CAST(SCDRequired AS INT)) FROM #temp_OdsTableDefinition WHERE OdsTableName = @strOdsTableName;

	-- Common columns - Present in every Veeva object.
	INSERT INTO @tableColumnMapping
	VALUES 
	('VeevaId', 'VeevaId'), 
	('LastModifiedById', 'VeevaLastModifiedById'), 
	('LastModifiedDate', 'VeevaLastModifiedDate'), 
	('SystemModstamp', 'VeevaSystemModstamp');

	-- Common columns - IsDeleted field does not exist in the below objects.
	IF @strOdsTableName NOT IN ('User', 'RecordType', 'Territory', 'UserTerritory')
		INSERT INTO @tableColumnMapping
		VALUES('IsDeleted', 'IsDeleted');

	-- Common columns - CreatedDate, CreatedById fields do not exist in the below objects.
	IF @strOdsTableName NOT IN ('Territory', 'UserTerritory')
		INSERT INTO @tableColumnMapping
		VALUES 
		('CreatedById', 'VeevaCreatedById'), 
		('CreatedDate', 'VeevaCreatedDate');

	-- Columns from VeevaOdsFieldMapping
	-- Any columns which are SQL keywords shoudl be enclosed in [] brackets.
	INSERT INTO @tableColumnMapping
	SELECT 
		CASE WHEN OdsColumnName IN ('Primary', 'User') THEN '[' + OdsColumnName + ']' ELSE OdsColumnName END AS StagingColumnName, 
		CASE WHEN OdsColumnName IN ('Primary', 'User') THEN '[' + OdsColumnName + ']' ELSE OdsColumnName END AS ProductionColumnName
	FROM VeevaOdsFieldMapping
	WHERE OdsTableName = @strOdsTableName
	GROUP BY OdsColumnName;

	-- Step-1: Adding the CREATE statement.
	SET @strOdsTableScript = 
'
CREATE OR ALTER PROCEDURE sp_' + LOWER(@strOdsTableName) + '_transform
AS
BEGIN

	SET NOCOUNT ON

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES(''sp_' + LOWER(@strOdsTableName) + '_transform'', ''sp_' + LOWER(@strOdsTableName) + '_transform Started'', GETUTCDATE());

	UPDATE P SET
';

	-- Step-2: Adding the SET column list for UPDATE statement.
	SELECT 
		@strOdsTableScript =	@strOdsTableScript + 
								STRING_AGG(CHAR(9) + CHAR(9) + 'P.' + ProductionColumnName + ' = S.' + StagingColumnName, ', ' + CHAR(13)) + 
								', ' + CHAR(13)
	FROM @tableColumnMapping
	WHERE ProductionColumnName NOT IN ('VeevaId', 'VeevaCreatedById', 'VeevaCreatedDate');


	-- Step-3: Adding the FROM and WHERE clauses for UPDATE statement.
	SET @strOdsTableScript = @strOdsTableScript + '		UpdatedDate = GETDATE()
	FROM ' + CASE WHEN @strOdsTableName = 'User' THEN '[User]' ELSE @strOdsTableName END + ' P
	INNER JOIN Staging_' + @strOdsTableName + ' S ON P.VeevaId = S.VeevaId AND P.VeevaSystemModstamp <> S.SystemModstamp' +
	CASE WHEN @bSCDRequired = 1 THEN ' AND P.EndDate IS NULL' ELSE '' END + ';

	
	INSERT INTO ' + CASE WHEN @strOdsTableName = 'User' THEN '[User]' ELSE @strOdsTableName END + '
		(';


	-- Step-4: Add the INSERT statement Production column list by adding five columns in each line.
	SELECT 
		@strOdsTableScript =	@strOdsTableScript + 
								STRING_AGG(ProductionColumnName + ', ' + CASE WHEN Id % 5 = 0 THEN CHAR(13) + CHAR(9) + CHAR(9) ELSE '' END, '')
	FROM @tableColumnMapping;


	-- Step-5: Add the INSERT statement Production column list by adding common columns.
	SET @strOdsTableScript = @strOdsTableScript + '
		CreatedDate, UpdatedDate)
	SELECT
		';


	-- Step-6: Add the SELECT statement Staging column list by adding five columns in each line.
	SELECT 
		@strOdsTableScript =	@strOdsTableScript + 
								STRING_AGG(StagingColumnName + ', ' + CASE WHEN Id % 5 = 0 THEN CHAR(13) + CHAR(9) + CHAR(9) ELSE '' END, '')
	FROM @tableColumnMapping;


	-- Step-7: Adding the FROM and WHERE clauses for INSERT statement.
	SET @strOdsTableScript = @strOdsTableScript + '
		GETDATE(), GETDATE()
	FROM Staging_' + @strOdsTableName + ' S
	WHERE NOT EXISTS (SELECT 1 FROM ' + CASE WHEN @strOdsTableName = 'User' THEN '[User]' ELSE @strOdsTableName END + ' P WHERE P.VeevaId = S.VeevaId' + 
	CASE WHEN @bSCDRequired = 1 THEN ' AND P.EndDate IS NULL' ELSE '' END + ');


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES(''sp_' + LOWER(@strOdsTableName) + '_transform'', ''sp_' + LOWER(@strOdsTableName) + '_transform Completed'', GETUTCDATE());


END
'

	--SELECT @strOdsTableScript;
	IF @bCreateObjectsInDatabase = 1
		EXECUTE sp_executesql @strOdsTableScript;

	-- Delete the table for which SP has been generated.
	DELETE FROM #temp_OdsTableDefinition WHERE OdsTableName = @strOdsTableName;
	UPDATE OdsGeneratedSchema SET TransformationSPSchema = @strOdsTableScript, UpdatedDate = GETDATE() WHERE OdsTableName = @strOdsTableName;

	-- Decrease the Loop counter so that it does not go into an infinite loop.
	SET @iOdsTableCount = @iOdsTableCount - 1;
END


DROP TABLE IF EXISTS #temp_OdsTableDefinition;

END

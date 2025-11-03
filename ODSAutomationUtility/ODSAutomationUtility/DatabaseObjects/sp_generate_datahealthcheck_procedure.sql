
CREATE OR ALTER PROCEDURE sp_generate_datahealthcheck_procedure
AS
BEGIN

SET NOCOUNT ON

DECLARE @strProcedureScript NVARCHAR(MAX), @strOdsTableName VARCHAR(400), @bSCDExists BIT;

	SET @strProcedureScript = 
'
CREATE OR ALTER PROCEDURE sp_veeva_datahealthcheck
AS
BEGIN

	SET NOCOUNT ON

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES(''sp_veeva_datahealthcheck'', ''sp_veeva_datahealthcheck Started'', GETUTCDATE());

';

	IF EXISTS (SELECT 1 FROM sys.triggers)
		SET @strProcedureScript = @strProcedureScript + 
'
	-- Check if any triggers have been disabled.
	IF EXISTS (SELECT 1 FROM sys.triggers WHERE is_disabled = 1)
	BEGIN
		INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
		VALUES(''sp_veeva_datahealthcheck'', ''Few Triggers have been disabled. Please check the output of following query for more details(SELECT * FROM sys.triggers WHERE is_disabled = 1).'', GETUTCDATE());
		THROW 51000, ''Few Triggers have been disabled. Please check the output of following query for more details(SELECT * FROM sys.triggers WHERE is_disabled = 1).'', 1;
	END';

	-- Create the below check only if Territory, UserTerritory, User tables exist.
	IF		EXISTS (SELECT 1 FROM sys.tables T INNER JOIN sys.columns C ON t.object_id = C.object_id WHERE T.name = 'Territory' AND C.name = 'EndDate')
		AND EXISTS (SELECT 1 FROM sys.tables T INNER JOIN sys.columns C ON t.object_id = C.object_id WHERE T.name = 'UserTerritory' AND C.name = 'EndDate')
		AND EXISTS (SELECT 1 FROM sys.tables T INNER JOIN sys.columns C ON t.object_id = C.object_id WHERE T.name = 'User' AND C.name = 'EndDate')
		SET @strProcedureScript = @strProcedureScript + '


	-- Check if a user is aligned to multiple territories.
	IF EXISTS (	SELECT U.VeevaId, COUNT(*)
				FROM [User] U
				LEFT OUTER JOIN UserTerritory UT ON U.VeevaId = UT.UserId and UT.EndDate IS NULL
				LEFT OUTER JOIN Territory T ON UT.TerritoryId = T.VeevaId and T.EndDate IS NULL
				WHERE U.EndDate IS NULL AND U.Name NOT LIKE ''%Test%''
				GROUP BY U.VeevaId HAVING COUNT(*) > 1)
	BEGIN
		INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
		VALUES(''sp_data_healthcheck'', ''A user is assigned to multiple territories.'', GETUTCDATE());
		THROW 51000, ''A user is assigned to multiple territories.'', 1;
	END

';

	SET @strProcedureScript = @strProcedureScript + '
	----------------------------------------Duplicate Record Checks------------------------------------
';

	CREATE TABLE #temp_OdsTableList
	(
		Id				INT IDENTITY(1, 1),
		OdsTableName	VARCHAR(400)	NOT NULL,
		SCDExists		BIT NOT NULL
	);

	INSERT INTO #temp_OdsTableList
	SELECT 
		CASE WHEN OdsTableName = 'User' THEN '[User]' ELSE OdsTableName END AS OdsTableName,
		MAX(CAST(SCDRequired AS INT))
	FROM VeevaOdsFieldMapping
	GROUP BY OdsTableName
	ORDER BY OdsTableName;

	WHILE EXISTS (SELECT 1 FROM #temp_OdsTableList)
	BEGIN

		-- Get the ODS table name.
		SELECT TOP 1 @strOdsTableName = OdsTableName, @bSCDExists = SCDExists FROM #temp_OdsTableList;

		SET @strProcedureScript = @strProcedureScript + 
		'
	IF EXISTS (	SELECT VeevaId, COUNT(*) FROM ' + @strOdsTableName + ' 
				' + CASE WHEN @bSCDExists = 1 THEN 'WHERE EndDate IS NULL' ELSE '' END + ' GROUP BY VeevaId HAVING COUNT(*) > 1)
	BEGIN
		INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
		VALUES(''sp_veeva_datahealthcheck'', ''Duplicate Rows in ' + @strOdsTableName + ' table'', GETUTCDATE());
		THROW 51000, ''Duplicate Rows in ' + @strOdsTableName + ' table'', 1;
	END
'

		DELETE FROM #temp_OdsTableList WHERE OdsTableName = @strOdsTableName;

	END

	SET @strProcedureScript = @strProcedureScript + '

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) 
	VALUES(''sp_veeva_datahealthcheck'', ''sp_veeva_datahealthcheck Completed'', GETUTCDATE());

END
'

--SELECT @strProcedureScript;
EXECUTE sp_executesql @strProcedureScript;

END

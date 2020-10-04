
CREATE OR ALTER PROCEDURE [dbo].[sp_generate_trigger] 
	@tableName NVARCHAR(400)
AS
BEGIN

SET NOCOUNT ON

DECLARE  @tableCount INT, @sqlTrigger NVARCHAR(MAX), @PrimaryKeyColumnName NVARCHAR(400);

CREATE TABLE #AuditDefinition(AuditColumnDefinitionId INT, TableName NVARCHAR(400), PrimaryKeyColumnName NVARCHAR(400), ColumnName NVARCHAR(400));
IF @tableName = 'All'
	INSERT INTO #AuditDefinition(AuditColumnDefinitionId, TableName, PrimaryKeyColumnName, ColumnName) 
	SELECT 
		ADC.[AuditColumnDefinitionId], ADT.[TableName], ADT.PrimaryKeyColumnName, ADC.[ColumnName]
	FROM [AuditTableDefinition] ADT
	INNER JOIN [AuditColumnDefinition] ADC ON ADT.[AuditTableDefinitionId] = ADC.[AuditTableDefinitionId]
	ORDER BY ADT.TableName;
ELSE
	INSERT INTO #AuditDefinition(AuditColumnDefinitionId, TableName, PrimaryKeyColumnName, ColumnName) 
	SELECT 
		ADC.[AuditColumnDefinitionId], ADT.[TableName], ADT.PrimaryKeyColumnName, ADC.[ColumnName]
	FROM [AuditTableDefinition] ADT
	INNER JOIN [AuditColumnDefinition] ADC ON ADT.[AuditTableDefinitionId] = ADC.[AuditTableDefinitionId]
	WHERE ADT.TableName = @tableName;

IF NOT EXISTS(SELECT 1 FROM #AuditDefinition)
THROW 51000, 'There is no Audit informtion available for the given table name', 1;

-- Get the count of all the tables to requies auditing.
SELECT @tableCount = count(DISTINCT TableName) FROM #AuditDefinition;

-- Loop through all the tables in the tables that requires auditing and create their triggers one-by-one.
WHILE @tableCount > 0
BEGIN

SELECT TOP 1 @tableName = TableName, @PrimaryKeyColumnName = PrimaryKeyColumnName FROM #AuditDefinition;

SET @sqlTrigger = 
'
IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE name = ''trg_' + @tableName + ''' AND type = ''TR'')
BEGIN

  DROP TRIGGER [trg_' + @tableName + ']

END'

-- This is done since CREATE TRIGGER should be the first statement in a batch
-- and we could not use GO to seperate batches since GO statement with executing dynamic SQL.
EXECUTE sp_executesql @sqlTrigger;
SET @sqlTrigger = 
'CREATE TRIGGER [dbo].[trg_' + @tableName + '] on [dbo].[' + @tableName + '] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages FROM the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT ' + @PrimaryKeyColumnName + ', CreatedDate, ' +
	STUFF((
	SELECT ', ' + CASE WHEN ColumnName = 'Primary' THEN '[' + ColumnName + ']' ELSE ColumnName END
	FROM #AuditDefinition WHERE TableName = @tableName
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ' INTO #deleted FROM DELETED WHERE EndDate IS NULL;

	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		IF EXISTS (SELECT 1 FROM #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			SELECT * INTO #insertedUPDATE FROM INSERTED WHERE EndDate IS NULL;

			--declare necessary variables to store temporary values for SCD columns and deleted CreatedDate
			DECLARE ' + 
			--Insert column variable list
				STUFF((
				SELECT '@' + COLUMN_NAME + 'INSERT ' +
						CASE WHEN DATA_TYPE IN ('bit', 'int', 'uniqueidentifier', 'bigint', 'datetime', 'date') THEN DATA_TYPE
							WHEN DATA_TYPE IN ('char', 'varchar', 'nvarchar') THEN DATA_TYPE + '(' + CASE WHEN CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) = '-1' THEN 'MAX' ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
							WHEN DATA_TYPE IN ('decimal', 'numeric', 'float') THEN DATA_TYPE + '(' + CAST(NUMERIC_PRECISION AS NVARCHAR(10)) + ', ' + CAST(ISNULL(NUMERIC_SCALE, 0) AS NVARCHAR(10)) + ') ' 
						END + ', '
				FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName
				AND COLUMN_NAME IN (SELECT ColumnName FROM #AuditDefinition where TableName = @tableName)
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '') + ' 
				' + 
			--Delete column variable list
				STUFF((
				SELECT '@' + COLUMN_NAME + 'DELETE ' +
						CASE WHEN DATA_TYPE IN ('bit', 'int', 'uniqueidentifier', 'bigint', 'datetime', 'date') THEN DATA_TYPE
							WHEN DATA_TYPE IN ('char', 'varchar', 'nvarchar') THEN DATA_TYPE + '(' + CASE WHEN CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) = '-1' THEN 'MAX' ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) END + ')'
							WHEN DATA_TYPE IN ('decimal', 'numeric', 'float') THEN DATA_TYPE + '(' + CAST(NUMERIC_PRECISION AS NVARCHAR(10)) + ', ' + CAST(ISNULL(NUMERIC_SCALE, 0) AS NVARCHAR(10)) + ') ' 
						END + ', '
				FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @tableName
				AND COLUMN_NAME IN (SELECT ColumnName FROM #AuditDefinition where TableName = @tableName)
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '') + '
				@CreatedDateDELETE DATETIME, @PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = COUNT(*) FROM #insertedUPDATE;
			WHILE @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = ' + @PrimaryKeyColumnName + 
					--Insert column values SELECT list
					STUFF((
					SELECT ', @' + ColumnName + 'INSERT = ' + CASE WHEN ColumnName = 'Primary' THEN '[' + ColumnName + ']' ELSE ColumnName END
					FROM #AuditDefinition WHERE TableName = @tableName
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '') + '
				FROM #insertedUPDATE;

				SELECT
					' +
					--Delete column values SELECT list
					STUFF((
					SELECT ', @' + ColumnName + 'DELETE = ' + CASE WHEN ColumnName = 'Primary' THEN '[' + ColumnName + ']' ELSE ColumnName END
					FROM #AuditDefinition WHERE TableName = @tableName
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ', @CreatedDateDELETE = CreatedDate
				FROM #deleted WHERE ' + @PrimaryKeyColumnName + ' = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF ' +
					STUFF((
					SELECT ' OR @' + ColumnName + 'INSERT <> @' + ColumnName + 'DELETE OR (@' + ColumnName + 'INSERT IS NULL AND @' + ColumnName + 'DELETE IS NOT NULL) OR (@' + ColumnName + 'INSERT IS NOT NULL AND @' + ColumnName + 'DELETE IS NULL)'
					FROM #AuditDefinition C WHERE TableName = @tableName
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 4, '') + '
					BEGIN
						UPDATE [' + @tableName + '] SET EndDate = GETDATE() WHERE ' + @PrimaryKeyColumnName + ' = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [' + @tableName + '](' + 
						STUFF((SELECT
							CASE WHEN EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
						THEN
							STUFF((
							SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
							FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
							FOR XML PATH('')), 1, 1, '') + ', StartDate, EndDate, CreatedDate, UpdatedDate'
						ELSE
							STUFF((
							SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
							FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
							FOR XML PATH('')), 1, 1, '') + ', StartDate, CreatedDate, UpdatedDate'
						END FOR XML PATH('')), 1, 1, '')
						 + ')
						SELECT ' + 
						STUFF((SELECT
							CASE WHEN EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
						THEN
							STUFF((
							SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
							FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
							FOR XML PATH('')), 1, 1, '') + ', GETDATE(), CASE WHEN IsDeleted = 1 THEN GETDATE() END, @CreatedDateDELETE, GETDATE()'
						ELSE
							STUFF((
							SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
							FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
							FOR XML PATH('')), 1, 1, '') + ', GETDATE(), @CreatedDateDELETE, GETDATE()'
						END FOR XML PATH('')), 1, 1, '')
						 + '
						FROM #insertedUPDATE WHERE ' + @PrimaryKeyColumnName + ' = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET ' + 
						STUFF((SELECT
							CASE WHEN EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
						THEN
							STUFF((SELECT CHAR(10) + '						 , T.' + 
									CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END + ' = I.' + 
									CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
							FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND (C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate', @PrimaryKeyColumnName) AND C.COLUMN_NAME NOT IN (SELECT ColumnName FROM #AuditDefinition WHERE TableName = @tableName))
							FOR XML PATH('')), 1, 10, '') + ', T.EndDate = CASE WHEN I.IsDeleted = 1 THEN GETDATE() END, T.CreatedDate = I.CreatedDate, T.UpdatedDate = GETDATE() '
						ELSE
							STUFF((SELECT CHAR(10) + '						 , T.' + 
									CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END + ' = I.' + 
									CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
							FROM INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND (C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate', @PrimaryKeyColumnName) AND C.COLUMN_NAME NOT IN (SELECT ColumnName FROM #AuditDefinition WHERE TableName = @tableName))
							FOR XML PATH('')), 1, 10, '') + ', T.UpdatedDate = GETDATE() '
						END FOR XML PATH('')), 1, 0, '')
						 + '
					FROM [' + @tableName + '] T INNER JOIN #insertedUPDATE I ON T.' + @PrimaryKeyColumnName + ' = I.' + @PrimaryKeyColumnName + ' AND I.' + @PrimaryKeyColumnName + ' = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				DELETE FROM #insertedUPDATE WHERE ' + @PrimaryKeyColumnName + ' = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (SELECT 1 FROM DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [' + @tableName + '](' +
				STUFF((SELECT
					CASE WHEN EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
				THEN
					STUFF((
					SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
					FROM INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
					FOR XML PATH('')), 1, 1, '') + ', StartDate, EndDate, CreatedDate, UpdatedDate'
				ELSE
					STUFF((
					SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
					FROM INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
					FOR XML PATH('')), 1, 1, '') + ', StartDate, CreatedDate, UpdatedDate'
				END FOR XML PATH('')), 1, 1, '')
				 + ')
				SELECT ' + 
				STUFF((SELECT
					CASE WHEN EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
				THEN
					STUFF((
					SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
					FROM INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
					FOR XML PATH('')), 1, 1, '') + ', GETDATE(), CASE WHEN IsDeleted = 1 THEN GETDATE() END, GETDATE(), GETDATE()'
				ELSE
					STUFF((
					SELECT ', ' + CASE WHEN C.COLUMN_NAME = 'Primary' THEN '[' + C.COLUMN_NAME + ']' ELSE C.COLUMN_NAME END
					FROM INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'StartDate', 'EndDate', 'CreatedDate', 'UpdatedDate')
					FOR XML PATH('')), 1, 1, '') + ', GETDATE(), GETDATE(), GETDATE()'
				END FOR XML PATH('')), 1, 1, '')
				 + ' FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [' + @tableName + '] SET EndDate = GETDATE() WHERE ' + @PrimaryKeyColumnName + ' IN (SELECT ' + @PrimaryKeyColumnName + ' FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END

'
	--SELECT @sqlTrigger;
	EXECUTE sp_executesql @sqlTrigger;
	DELETE FROM #AuditDefinition WHERE TableName = @tableName;
	SET @tableCount = @tableCount - 1;
END

DROP TABLE IF EXISTS #AuditDefinition;

END


CREATE   PROCEDURE [dbo].[sp_generate_trigger] 
	@tableName NVARCHAR(400)
AS
BEGIN

SET NOCOUNT ON

DECLARE  @tableCount int, @sqlTrigger NVARCHAR(MAX);

CREATE TABLE #AuditDefinition(AuditDefinitionId	int, TableName nvarchar(400), ColumnName nvarchar(400));
IF @tableName = 'All'
	INSERT INTO #AuditDefinition(AuditDefinitionId, TableName, ColumnName) select * from AuditDefinition ORDER BY TableName;
ELSE
	INSERT INTO #AuditDefinition(AuditDefinitionId, TableName, ColumnName) select * from AuditDefinition WHERE TableName = @tableName;

IF NOT EXISTS(SELECT 1 FROM #AuditDefinition)
THROW 51000, 'There is no Audit informtion available for the given table name', 1;

SELECT @tableCount = count(DISTINCT TableName) from #AuditDefinition;
WHILE @tableCount > 0
BEGIN

select TOP 1 @tableName = TableName from #AuditDefinition;

SET @sqlTrigger = 
'
IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE name = ''trg_' + @tableName + ''' and type = ''TR'')
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

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT ' + @tableName + 'Id, ' +
	STUFF((
	select ', ' + ColumnName
	from #AuditDefinition where TableName = @tableName
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ' into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare ' + 
			--Insert column variable list
				STUFF((
				select '@' + COLUMN_NAME + 'INSERT ' +
						CASE WHEN DATA_TYPE IN ('bit', 'int', 'uniqueidentifier', 'bigint', 'datetime', 'date') THEN DATA_TYPE
							WHEN DATA_TYPE IN ('char', 'varchar', 'nvarchar') THEN DATA_TYPE + '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) + ')'
							WHEN DATA_TYPE IN ('decimal', 'numeric', 'float') THEN DATA_TYPE + '(' + CAST(NUMERIC_PRECISION AS NVARCHAR(10)) + ', ' + CAST(ISNULL(NUMERIC_SCALE, 0) AS NVARCHAR(10)) + ') ' 
						END + ', '
				from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName
				AND COLUMN_NAME IN (select ColumnName from #AuditDefinition where TableName = @tableName)
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '') + ' 
				' + 
			--Delete column variable list
				STUFF((
				select '@' + COLUMN_NAME + 'DELETE ' +
						CASE WHEN DATA_TYPE IN ('bit', 'int', 'uniqueidentifier', 'bigint', 'datetime', 'date') THEN DATA_TYPE
							WHEN DATA_TYPE IN ('char', 'varchar', 'nvarchar') THEN DATA_TYPE + '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(10)) + ')'
							WHEN DATA_TYPE IN ('decimal', 'numeric', 'float') THEN DATA_TYPE + '(' + CAST(NUMERIC_PRECISION AS NVARCHAR(10)) + ', ' + CAST(ISNULL(NUMERIC_SCALE, 0) AS NVARCHAR(10)) + ') ' 
						END + ', '
				from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @tableName
				AND COLUMN_NAME IN (select ColumnName from #AuditDefinition where TableName = @tableName)
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '') + '
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = ' + @tableName + 'Id' +
					--Insert column values select list
					STUFF((
					select ', @' + ColumnName + 'INSERT = ' + ColumnName
					from #AuditDefinition where TableName = @tableName
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '') + '
				from #insertedUPDATE;

				SELECT
					' +
					--Delete column values select list
					STUFF((
					select ', @' + ColumnName + 'DELETE = ' + ColumnName
					from #AuditDefinition where TableName = @tableName
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')  + '
				from #deleted WHERE ' + @tableName + 'Id = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					' +
					STUFF((
					select ' OR @' + ColumnName + 'INSERT <> @' + ColumnName + 'DELETE OR (@' + ColumnName + 'INSERT IS NULL AND @' + ColumnName + 'DELETE IS NOT NULL) OR (@' + ColumnName + 'INSERT IS NOT NULL AND @' + ColumnName + 'DELETE IS NULL)'
					FROM #AuditDefinition C WHERE TableName = @tableName
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 4, '') + '
					BEGIN
						UPDATE [' + @tableName + '] SET EndDate = GETDATE() WHERE ' + @tableName + 'Id = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [' + @tableName + '](' + 
						STUFF((SELECT
							CASE WHEN EXISTS(Select 1 From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
						THEN
							STUFF((
							Select ', ' + C.COLUMN_NAME
							From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
							For Xml Path('')), 1, 1, '') + ', EndDate'
						ELSE
							STUFF((
							Select ', ' + C.COLUMN_NAME
							From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
							For Xml Path('')), 1, 1, '') 
						END For Xml Path('')), 1, 1, '')
						 + ')
						SELECT ' + 
						STUFF((SELECT
							CASE WHEN EXISTS(Select 1 From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
						THEN
							STUFF((
							Select ', ' + C.COLUMN_NAME
							From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
							For Xml Path('')), 1, 1, '') + ', CASE WHEN IsDeleted = ''True'' THEN GETDATE() END'
						ELSE
							STUFF((
							Select ', ' + C.COLUMN_NAME
							From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
							For Xml Path('')), 1, 1, '') 
						END For Xml Path('')), 1, 1, '')
						 + '
						FROM #insertedUPDATE WHERE ' + @tableName + 'Id = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET ' + 
						STUFF((SELECT
							CASE WHEN EXISTS(Select 1 From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
						THEN
							STUFF((Select CHAR(10) + '						 , T.' + C.COLUMN_NAME + ' = I.' + C.COLUMN_NAME
							From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND (C.COLUMN_NAME NOT IN ('Id', 'EndDate', @tableName + 'Id') AND C.COLUMN_NAME NOT IN (SELECT ColumnName FROM #AuditDefinition WHERE TableName = @tableName))
							For Xml Path('')), 1, 10, '') + ', T.EndDate = CASE WHEN I.IsDeleted = ''True'' THEN GETDATE() END '
						ELSE
							STUFF((Select CHAR(10) + '						 , T.' + C.COLUMN_NAME + ' = I.' + C.COLUMN_NAME
							From INFORMATION_SCHEMA.COLUMNS As C 
							INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
							WHERE T.TABLE_NAME = @tableName AND (C.COLUMN_NAME NOT IN ('Id', 'EndDate', @tableName + 'Id') AND C.COLUMN_NAME NOT IN (SELECT ColumnName FROM #AuditDefinition WHERE TableName = @tableName))
							For Xml Path('')), 1, 10, '') 
						END For Xml Path('')), 1, 0, '')
						 + '
					FROM [' + @tableName + '] T INNER JOIN #insertedUPDATE I ON T.' + @tableName + 'Id = I.' + @tableName + 'Id AND I.' + @tableName + 'Id = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where ' + @tableName + 'Id = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [' + @tableName + '](' +
				STUFF((SELECT
					CASE WHEN EXISTS(Select 1 From INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
				THEN
					STUFF((
					Select ', ' + C.COLUMN_NAME
					From INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
					For Xml Path('')), 1, 1, '') + ', EndDate'
				ELSE
					STUFF((
					Select ', ' + C.COLUMN_NAME
					From INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
					For Xml Path('')), 1, 1, '') 
				END For Xml Path('')), 1, 1, '')
				 + ')
				SELECT ' + 
				STUFF((SELECT
					CASE WHEN EXISTS(Select 1 From INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME = 'IsDeleted')
				THEN
					STUFF((
					Select ', ' + C.COLUMN_NAME
					From INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
					For Xml Path('')), 1, 1, '') + ', CASE WHEN IsDeleted = ''True'' THEN GETDATE() END'
				ELSE
					STUFF((
					Select ', ' + C.COLUMN_NAME
					From INFORMATION_SCHEMA.COLUMNS As C 
					INNER JOIN INFORMATION_SCHEMA.TABLES As T ON C.TABLE_SCHEMA = T.TABLE_SCHEMA And C.TABLE_NAME = T.TABLE_NAME
					WHERE T.TABLE_NAME = @tableName AND C.COLUMN_NAME NOT IN ('Id', 'EndDate')
					For Xml Path('')), 1, 1, '') 
				END For Xml Path('')), 1, 1, '')
				 + ' FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [' + @tableName + '] SET EndDate = GETDATE() WHERE ' + @tableName + 'Id IN (SELECT ' + @tableName + 'Id FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END

'
	--SELECT @sqlTrigger;
	EXECUTE sp_executesql @sqlTrigger;
	DELETE FROM #AuditDefinition WHERE TableName = @tableName;
	SET @tableCount = @tableCount - 1;
END

drop table #AuditDefinition;

END



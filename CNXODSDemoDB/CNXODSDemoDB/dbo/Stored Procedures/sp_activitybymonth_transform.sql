

CREATE OR ALTER PROCEDURE [dbo].[sp_activitybymonth_transform]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON

IF EXISTS(SELECT 1 FROM sysobjects WHERE type = 'U' and name = 'Reporting_ActivityByMonthWithTargetTypes')
BEGIN
   DROP TABLE Reporting_ActivityByMonthWithTargetTypes;
END
CREATE TABLE Reporting_ActivityByMonthWithTargetTypes
(
	[TargetType]		NVARCHAR(25)		NULL,
	TargetTypeInteger  INT					NULL,
	[Metric]			NVARCHAR(25)		NULL,
	[MetricInteger]		INT					NULL,
	[Month]				NVARCHAR(25)		NOT NULL,
	[MonthInteger]		INT					NOT NULL,
	[Value]				DECIMAL(10, 1)		NULL,
);

DECLARE @ListofMetrics		TABLE(Id INT IDENTITY(1, 1), Metric NVARCHAR(25));
DECLARE @ListofMonthDates	TABLE(Id INT IDENTITY(1, 1), MonthStartDate DATE, NextMonthStartDate DATE);
DECLARE @ListofMonthStrings	TABLE(Id INT IDENTITY(1, 1), MonthString NVARCHAR(25));
DECLARE @ListofTargetTypes	TABLE(Id INT IDENTITY(1, 1), TargetType NVARCHAR(25));

INSERT INTO @ListofMetrics(Metric)
VALUES('Total Calls'), ('Call Only'), ('Detail Only'), ('Group Detail'), ('Detail with Sample'), ('Group Detail with Sample'), ('Calls/day'), ('HCPs Detailed');


INSERT INTO @ListofTargetTypes(TargetType)
VALUES('UT (Ultra Target)'), ('ST (Super Target)'), ('T (Target)'), ('NT (Non Target)');


WITH cte AS 
(
    SELECT dateadd(month, datepart(mm, GETDATE()) - 12, dateadd(year, datepart(yyyy, GETDATE()) - 1900, 0)) AS MonthStartDate
	UNION ALL
	SELECT dateadd(mm, 1, MonthStartDate) from cte where MonthStartDate < GETDATE()
)
INSERT INTO @ListofMonthDates(MonthStartDate, NextMonthStartDate)
select MonthStartDate, DATEADD(MONTH, 1, MonthStartDate) AS NextMonthStartDate from cte where MonthStartDate < GETDATE()

INSERT INTO @ListofMonthStrings(MonthString)
SELECT SUBSTRING(REPLACE(CONVERT(CHAR(9), MonthStartDate, 6), ' ', '-'), 4, 8) FROM @ListofMonthDates;

DECLARE @MonthLoopVariable AS INT, @MetricLoopVariable AS INT;
SELECT @MonthLoopVariable = 1, @MetricLoopVariable = 1;
WHILE @MetricLoopVariable <= (SELECT COUNT(1) FROM @ListofMetrics)
BEGIN

	WHILE @MonthLoopVariable <= (SELECT COUNT(1) FROM @ListofMonthStrings)
	BEGIN

		INSERT INTO Reporting_ActivityByMonthWithTargetTypes ([TargetType], TargetTypeInteger, [Metric], [MetricInteger], [Month], [MonthInteger], [Value])
		SELECT T.TargetType, T.Id,
			(SELECT Metric FROM @ListofMetrics WHERE Id = @MetricLoopVariable) AS Metric,
			(SELECT Id FROM @ListofMetrics WHERE Id = @MetricLoopVariable) AS MetricInteger,
			MonthString, M.Id, NULL
		FROM @ListofMonthStrings M CROSS JOIN @ListofTargetTypes T WHERE M.Id = @MonthLoopVariable;

		SET @MonthLoopVariable = @MonthLoopVariable + 1;
	END

	SET @MonthLoopVariable = 1
	SET @MetricLoopVariable = @MetricLoopVariable + 1;
END


WHILE @MonthLoopVariable <= (SELECT COUNT(1) FROM @ListofMonthStrings)
BEGIN

	WITH CTE_Calls AS
	(
		SELECT CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END AS TargetType, count(*) AS TCount
		FROM Call C
		INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
		where C.EndDate IS NULL 			-- Anis: 2019-01-27 -- AND C.ParentCallId IS NOT NULL
		and C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		GROUP BY CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END
	)
	UPDATE ABM
	SET ABM.Value = C.TCount
	FROM Reporting_ActivityByMonthWithTargetTypes ABM
	INNER JOIN CTE_Calls C ON ABM.TargetType = C.TargetType
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Total Calls';

	WITH CTE_Calls AS
	(
		SELECT CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END AS TargetType, count(*) AS TCount
		FROM Call C
		INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
		where C.EndDate IS NULL
		AND C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallType = 'Call Only'
		GROUP BY CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END
	)
	UPDATE ABM
	SET ABM.Value = C.TCount
	FROM Reporting_ActivityByMonthWithTargetTypes ABM
	INNER JOIN CTE_Calls C ON ABM.TargetType = C.TargetType
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Call Only';

	WITH CTE_Calls AS
	(
		SELECT CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END AS TargetType, count(*) AS TCount
		FROM Call C
		INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
		where C.EndDate IS NULL
		AND C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallType = 'Detail Only'
		GROUP BY CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END
	)
	UPDATE ABM
	SET ABM.Value = C.TCount
	FROM Reporting_ActivityByMonthWithTargetTypes ABM
	INNER JOIN CTE_Calls C ON ABM.TargetType = C.TargetType
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Detail Only';


	WITH CTE_Calls AS
	(
		SELECT CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END AS TargetType, count(*) AS TCount
		FROM Call C
		INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
		where C.EndDate IS NULL
		AND C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallType = 'Group Detail'
		GROUP BY CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END
	)
	UPDATE ABM
	SET ABM.Value = C.TCount
	FROM Reporting_ActivityByMonthWithTargetTypes ABM
	INNER JOIN CTE_Calls C ON ABM.TargetType = C.TargetType
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Group Detail';
	

	WITH CTE_Calls AS
	(
		SELECT CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END AS TargetType, count(*) AS TCount
		FROM Call C
		INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
		where C.EndDate IS NULL
		AND C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallType = 'Detail with Sample'
		GROUP BY CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END
	)
	UPDATE ABM
	SET ABM.Value = C.TCount
	FROM Reporting_ActivityByMonthWithTargetTypes ABM
	INNER JOIN CTE_Calls C ON ABM.TargetType = C.TargetType
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Detail with Sample';
	

	WITH CTE_Calls AS
	(
		SELECT CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END AS TargetType, count(*) AS TCount
		FROM Call C
		INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
		where C.EndDate IS NULL
		AND C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallType = 'Group Detail with Sample'
		GROUP BY CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END
	)
	UPDATE ABM
	SET ABM.Value = C.TCount
	FROM Reporting_ActivityByMonthWithTargetTypes ABM
	INNER JOIN CTE_Calls C ON ABM.TargetType = C.TargetType
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Group Detail with Sample';


	select C.[User], CONVERT(date, C.CallDate) AS CallDate INTO #CTE_WorkDays
	from Call C
	where C.EndDate IS NULL
	AND C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
	AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
	GROUP BY C.[User], CONVERT(date, C. CallDate) HAVING COUNT(*) >= 4;

	UPDATE Reporting_ActivityByMonthWithTargetTypes
	SET Value = 
	(
		select	CASE WHEN (SELECT COUNT(*) FROM #CTE_WorkDays) = 0 THEN 0 ELSE
					ROUND((SELECT Value FROM Reporting_ActivityByMonthWithTargetTypes WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Total Calls' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 1)) /
						(SELECT COUNT(*) FROM #CTE_WorkDays), 1)
				END AS [Calls/day]
	)
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Calls/day' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 1);

	UPDATE Reporting_ActivityByMonthWithTargetTypes
	SET Value = 
	(
		select	CASE WHEN (SELECT COUNT(*) FROM #CTE_WorkDays) = 0 THEN 0 ELSE
					ROUND((SELECT Value FROM Reporting_ActivityByMonthWithTargetTypes WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Total Calls' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 2)) /
						(SELECT COUNT(*) FROM #CTE_WorkDays), 1)
				END AS [Calls/day]
	)
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Calls/day' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 2);

	UPDATE Reporting_ActivityByMonthWithTargetTypes
	SET Value = 
	(
		select	CASE WHEN (SELECT COUNT(*) FROM #CTE_WorkDays) = 0 THEN 0 ELSE
					ROUND((SELECT Value FROM Reporting_ActivityByMonthWithTargetTypes WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Total Calls' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 3)) /
						(SELECT COUNT(*) FROM #CTE_WorkDays), 1)
				END AS [Calls/day]
	)
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Calls/day' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 3);

	UPDATE Reporting_ActivityByMonthWithTargetTypes
	SET Value = 
	(
		select	CASE WHEN (SELECT COUNT(*) FROM #CTE_WorkDays) = 0 THEN 0 ELSE
					ROUND((SELECT Value FROM Reporting_ActivityByMonthWithTargetTypes WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Total Calls' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 4)) /
						(SELECT COUNT(*) FROM #CTE_WorkDays), 1)
				END AS [Calls/day]
	)
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'Calls/day' AND TargetType = (SELECT TargetType FROM @ListofTargetTypes WHERE Id = 4);

	DROP TABLE #CTE_WorkDays;


	WITH CTE_HCPsDetailed AS
	(
		SELECT CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END AS TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed]
		from Call C
		INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
		where C.EndDate IS NULL
		AND C.CallDate >= (select LMD.MonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallDate < (select LMD.NextMonthStartDate FROM @ListofMonthDates LMD WHERE LMD.Id = @MonthLoopVariable)
		AND C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample')
		GROUP BY CASE CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			ELSE 'NT (Non Target)'
			END
	)
	UPDATE ABM
	SET ABM.Value = HD.[HCPs Detailed]
	FROM Reporting_ActivityByMonthWithTargetTypes ABM
	INNER JOIN CTE_HCPsDetailed HD ON ABM.TargetType = HD.TargetType
	WHERE MonthInteger = @MonthLoopVariable AND Metric = 'HCPs Detailed';
	SET @MonthLoopVariable = @MonthLoopVariable + 1;
END

UPDATE Reporting_ActivityByMonthWithTargetTypes SET Value = 0 WHERE Value IS NULL;

IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_ActivityByMonthWithTargetTypes_Metric')   
    DROP INDEX IX_Reporting_ActivityByMonthWithTargetTypes_Metric ON dbo.Reporting_ActivityByMonthWithTargetTypes;
CREATE NONCLUSTERED INDEX IX_Reporting_ActivityByMonthWithTargetTypes_Metric ON dbo.Reporting_ActivityByMonthWithTargetTypes ([Metric] ASC);  

IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_ActivityByMonthWithTargetTypes_TargetType')   
    DROP INDEX IX_Reporting_ActivityByMonthWithTargetTypes_TargetType ON dbo.Reporting_ActivityByMonthWithTargetTypes;
CREATE NONCLUSTERED INDEX IX_Reporting_ActivityByMonthWithTargetTypes_TargetType ON dbo.Reporting_ActivityByMonthWithTargetTypes (TargetType ASC); 


TRUNCATE TABLE Reporting_ActivityByMonthWithTargetTypes_KPI;

INSERT INTO Reporting_ActivityByMonthWithTargetTypes_KPI
SELECT Metric, SUM(Value) AS TotalCalls 
FROM Reporting_ActivityByMonthWithTargetTypes
WHERE Metric <> 'Calls/day'
GROUP BY Metric
UNION ALL
SELECT Metric, AVG(Value) AS TotalCalls 
FROM Reporting_ActivityByMonthWithTargetTypes
WHERE Metric = 'Calls/day'
GROUP BY Metric;


END


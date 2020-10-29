CREATE OR ALTER PROCEDURE [dbo].[sp_activitybyterritory_transform]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON


IF EXISTS(SELECT 1 FROM sysobjects WHERE type = 'U' and name = 'Reporting_ActivityByTerritoryWithTargetTypes')
BEGIN
   DROP TABLE Reporting_ActivityByTerritoryWithTargetTypes;
END
CREATE TABLE Reporting_ActivityByTerritoryWithTargetTypes
(
	[Territory Name]	NVARCHAR(200)		NULL,
	[TargetType]		NVARCHAR(25)		NULL,
	TargetTypeInteger  INT					NULL,
	[Time Period]		NVARCHAR(25)		NOT NULL,
	[TimePeriodInteger]	INT					NULL,
	[Metric]			NVARCHAR(25)		NULL,
	[MetricInteger]		INT					NULL,
	[Value]				DECIMAL(10, 1)		NULL,
);


DECLARE @TimePeriodLoopVariable AS INT, @MetricLoopVariable AS INT;
DECLARE @ListofTimePeriods	TABLE(Id INT IDENTITY(1, 1), TimePeriod NVARCHAR(25));
DECLARE @ListofMetrics		TABLE(Id INT IDENTITY(1, 1), Metric NVARCHAR(25));
DECLARE @ListofTerritories	TABLE(TerritoryName NVARCHAR(400), [TargetType] NVARCHAR(25), TargetTypeInteger INT);
SELECT @TimePeriodLoopVariable = 1, @MetricLoopVariable = 1;

INSERT INTO @ListofTimePeriods(TimePeriod)
VALUES('Previous Week'), ('Previous Month'), ('Previous Quarter'), ('Previous Year'), ('This Month'), ('This Quarter'), ('This Year');

INSERT INTO @ListofMetrics(Metric)
VALUES('Total Calls'), ('Call Only'), ('Detail Only'), ('Group Detail'), ('Detail with Sample'), ('Group Detail with Sample'), ('Calls/day'), ('HCPs Detailed');

INSERT INTO @ListofTerritories(TerritoryName, [TargetType], TargetTypeInteger)
SELECT DISTINCT C.Territory, A.CNXTargetTypec AS TargetType, 
	CASE A.CNXTargetTypec
			WHEN 'UT (Ultra Target)' THEN 1
			WHEN 'ST (Super Target)' THEN 2
			WHEN 'T (Target)' THEN 3
			ELSE 4
	END AS TargetTypeInteger
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
where C.Territory IS NOT NULL AND C.EndDate IS NULL
order by C.Territory, TargetTypeInteger;


WHILE @TimePeriodLoopVariable <= (SELECT COUNT(1) FROM @ListofTimePeriods)
BEGIN

	WHILE @MetricLoopVariable <= (SELECT COUNT(1) FROM @ListofMetrics)
	BEGIN

		INSERT INTO Reporting_ActivityByTerritoryWithTargetTypes ([Territory Name], [TargetType], TargetTypeInteger, [Time Period], [TimePeriodInteger], [Metric], [MetricInteger])
		SELECT DISTINCT
			TerritoryName, [TargetType], TargetTypeInteger, 
			(SELECT TimePeriod FROM @ListofTimePeriods WHERE Id = @TimePeriodLoopVariable) AS TimePeriod,
			(SELECT Id FROM @ListofTimePeriods WHERE Id = @TimePeriodLoopVariable) AS TimePeriodInteger,
			(SELECT Metric FROM @ListofMetrics WHERE Id = @MetricLoopVariable) AS Metric,
			(SELECT Id FROM @ListofMetrics WHERE Id = @MetricLoopVariable) AS MetricInteger
		FROM @ListofTerritories;

		SET @MetricLoopVariable = @MetricLoopVariable + 1;
	END

	SET @MetricLoopVariable = 1
	SET @TimePeriodLoopVariable = @TimePeriodLoopVariable + 1;
END


DECLARE @Dates TABLE 
(
	PreviousWeekStartDate			DATETIME,
	PreviousWeekEndDate				DATETIME,
	ThisMonthStartDate				DATETIME,
	ThisMonthEndDate				DATETIME,
	PreviousMonthStartDate			DATETIME,
	PreviousMonthEndDate			DATETIME,
	ThisQuarterStartDate			DATETIME,
	ThisQuarterEndDate				DATETIME,
	PreviousQuarterStartDate		DATETIME,
	PreviousQuarterEndDate			DATETIME,
	ThisYearStartDate				DATETIME,
	ThisYearEndDate					DATETIME,
	PreviousYearStartDate			DATETIME,
	PreviousYearEndDate				DATETIME
);
DECLARE @TestDate AS DATETIME
SET @TestDate = GETDATE()
INSERT INTO @Dates
	(PreviousWeekStartDate, PreviousWeekEndDate, ThisMonthStartDate, ThisMonthEndDate, PreviousMonthStartDate, 
	PreviousMonthEndDate, ThisQuarterStartDate, ThisQuarterEndDate, PreviousQuarterStartDate, PreviousQuarterEndDate, ThisYearStartDate, 
	ThisYearEndDate, PreviousYearStartDate, PreviousYearEndDate)
SELECT
	CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 7, @TestDate), -1))											-- Previous Week Start Date
    , CONVERT(DATE, DATEADD(WEEK, DATEDIFF(WEEK, 7, @TestDate), 5))											-- Previous Week End Date
    , CONVERT(DATE, DATEADD(d, -( DAY(@TestDate - 1) ), @TestDate))											-- This Month Start Date
    , CONVERT(DATE, DATEADD(d, -( DAY(DATEADD(m, 1, @TestDate)) ), DATEADD(m, 1, @TestDate)))				-- This Month End Date
    , CONVERT(DATE, DATEADD(MM, DATEDIFF(MM, 0, @TestDate)-1, 0))											-- Previous Month Start Date
    , CONVERT(DATE, DATEADD(MS, -3, DATEADD(MM, DATEDIFF(MM, 0, @TestDate) , 0)))							-- Previous Month End Date
	, CONVERT(DATE, DATEADD(q, DATEDIFF(q, 0, @TestDate), 0))												-- This Quarter Start Date
	, CONVERT(DATE, DATEADD(d, -1, DATEADD(q, DATEDIFF(q, 0, @TestDate) + 1, 0)))							-- This Quarter End Date
	, CONVERT(DATE, DATEADD(d, 0, DATEADD(q, DATEDIFF(q, 0, @TestDate) - 1, 0)))							-- Previous Quarter Start Date
	, CONVERT(DATE, DATEADD(d, -1, DATEADD(q, DATEDIFF(q, 0, @TestDate), 0)))								-- Previous Quarter End Date
    , CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, @TestDate), 0))											-- This Year Start Date
    , CONVERT(DATE, DATEADD(ms, -2, DATEADD(YEAR, 0, DATEADD(YEAR, DATEDIFF(YEAR, 0, @TestDate) + 1, 0))))	-- This Year End Date
    , CONVERT(DATE, DATEADD(YEAR, DATEDIFF(YEAR, 0, @TestDate) - 1, 0))										-- Previous Year Start Date
    , CONVERT(DATE, DATEADD(ms, -2, DATEADD(YEAR, 0, DATEADD(YEAR, DATEDIFF(YEAR, 0, @TestDate), 0))))		-- Previous Year End Date
;





-----------------------------------------------------------------------------------
--------------------------------------Total Calls----------------------------------
-----------------------------------------------------------------------------------
WITH cte_calldetails AS
(
SELECT C.Territory, C.CallId, C.CallDate, A.CNXTargetTypec AS TargetType
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
WHERE C.EndDate IS NULL
)
UPDATE LAT
SET LAT.Value = temp.TotalCalls
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select C.Territory, C.TargetType, COUNT(C.CallId) AS TotalCalls, 'Previous Week' AS [Time Period]
from cte_calldetails C
WHERE CAST(C.CallDate AS DATE) >= (SELECT PreviousWeekStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(C.CallId) AS TotalCalls, 'This Month' AS [Time Period]
from cte_calldetails C
WHERE CAST(C.CallDate AS DATE) >= (SELECT ThisMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(C.CallId) AS TotalCalls, 'Previous Month' AS [Time Period]
from cte_calldetails C
WHERE CAST(C.CallDate AS DATE) >= (SELECT PreviousMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(C.CallId) AS TotalCalls, 'This Quarter' AS [Time Period]
from cte_calldetails C
WHERE CAST(C.CallDate AS DATE) >= (SELECT ThisQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(C.CallId) AS TotalCalls, 'Previous Quarter' AS [Time Period]
from cte_calldetails C
WHERE CAST(C.CallDate AS DATE) >= (SELECT PreviousQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(C.CallId) AS TotalCalls, 'This Year' AS [Time Period]
from cte_calldetails C
WHERE CAST(C.CallDate AS DATE) >= (SELECT ThisYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(C.CallId) AS TotalCalls, 'Previous Year' AS [Time Period]
from cte_calldetails C
WHERE CAST(C.CallDate AS DATE) >= (SELECT PreviousYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
) AS temp
ON LAT.[Territory Name] = temp.Territory AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'Total Calls';


-----------------------------------------------------------------------------------
--------------------------------------Call Only----------------------------------
-----------------------------------------------------------------------------------
WITH cte_calldetails AS
(
SELECT C.Territory, C.CallId, C.CallDate, C.CallType, A.CNXTargetTypec AS TargetType
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
WHERE C.EndDate IS NULL
)
UPDATE LAT
SET LAT.Value = temp.[Call Only]
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Call Only') THEN 1 ELSE 0 END) AS [Call Only], 'Previous Week' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousWeekStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Call Only') THEN 1 ELSE 0 END) AS [Call Only], 'This Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Call Only') THEN 1 ELSE 0 END) AS [Call Only], 'Previous Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Call Only') THEN 1 ELSE 0 END) AS [Call Only], 'This Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Call Only') THEN 1 ELSE 0 END) AS [Call Only], 'Previous Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Call Only') THEN 1 ELSE 0 END) AS [Call Only], 'This Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Call Only') THEN 1 ELSE 0 END) AS [Call Only], 'Previous Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
) AS temp
ON LAT.[Territory Name] = temp.Territory AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'Call Only';



-----------------------------------------------------------------------------------
--------------------------------------Detail Only----------------------------------
-----------------------------------------------------------------------------------
WITH cte_calldetails AS
(
SELECT C.Territory, C.CallId, C.CallDate, C.CallType, A.CNXTargetTypec AS TargetType
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
WHERE C.EndDate IS NULL
)
UPDATE LAT
SET LAT.Value = temp.[Detail Only]
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail Only') THEN 1 ELSE 0 END) AS [Detail Only], 'Previous Week' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousWeekStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail Only') THEN 1 ELSE 0 END) AS [Detail Only], 'This Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail Only') THEN 1 ELSE 0 END) AS [Detail Only], 'Previous Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail Only') THEN 1 ELSE 0 END) AS [Detail Only], 'This Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail Only') THEN 1 ELSE 0 END) AS [Detail Only], 'Previous Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail Only') THEN 1 ELSE 0 END) AS [Detail Only], 'This Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail Only') THEN 1 ELSE 0 END) AS [Detail Only], 'Previous Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
) AS temp
ON LAT.[Territory Name] = temp.Territory AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'Detail Only';


-----------------------------------------------------------------------------------
--------------------------------------Group Detail----------------------------------
-----------------------------------------------------------------------------------
WITH cte_calldetails AS
(
SELECT C.Territory, C.CallId, C.CallDate, C.CallType, A.CNXTargetTypec AS TargetType
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
WHERE C.EndDate IS NULL
)
UPDATE LAT
SET LAT.Value = temp.[Group Detail]
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail') THEN 1 ELSE 0 END) AS [Group Detail], 'Previous Week' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousWeekStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail') THEN 1 ELSE 0 END) AS [Group Detail], 'This Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail') THEN 1 ELSE 0 END) AS [Group Detail], 'Previous Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail') THEN 1 ELSE 0 END) AS [Group Detail], 'This Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail') THEN 1 ELSE 0 END) AS [Group Detail], 'Previous Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail') THEN 1 ELSE 0 END) AS [Group Detail], 'This Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail') THEN 1 ELSE 0 END) AS [Group Detail], 'Previous Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
) AS temp
ON LAT.[Territory Name] = temp.Territory AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'Group Detail';


-----------------------------------------------------------------------------------
--------------------------------------Detail with Sample----------------------------------
-----------------------------------------------------------------------------------
WITH cte_calldetails AS
(
SELECT C.Territory, C.CallId, C.CallDate, C.CallType, A.CNXTargetTypec AS TargetType
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
WHERE C.EndDate IS NULL
)
UPDATE LAT
SET LAT.Value = temp.[Detail with Sample]
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail with Sample') THEN 1 ELSE 0 END) AS [Detail with Sample], 'Previous Week' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousWeekStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail with Sample') THEN 1 ELSE 0 END) AS [Detail with Sample], 'This Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail with Sample') THEN 1 ELSE 0 END) AS [Detail with Sample], 'Previous Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail with Sample') THEN 1 ELSE 0 END) AS [Detail with Sample], 'This Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail with Sample') THEN 1 ELSE 0 END) AS [Detail with Sample], 'Previous Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail with Sample') THEN 1 ELSE 0 END) AS [Detail with Sample], 'This Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Detail with Sample') THEN 1 ELSE 0 END) AS [Detail with Sample], 'Previous Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
) AS temp
ON LAT.[Territory Name] = temp.Territory AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'Detail with Sample';


-----------------------------------------------------------------------------------
--------------------------------------Group Detail with Sample----------------------------------
-----------------------------------------------------------------------------------
WITH cte_calldetails AS
(
SELECT C.Territory, C.CallId, C.CallDate, C.CallType, A.CNXTargetTypec AS TargetType
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
WHERE C.EndDate IS NULL
)
UPDATE LAT
SET LAT.Value = temp.[Group Detail with Sample]
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail with Sample') THEN 1 ELSE 0 END) AS [Group Detail with Sample], 'Previous Week' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousWeekStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail with Sample') THEN 1 ELSE 0 END) AS [Group Detail with Sample], 'This Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail with Sample') THEN 1 ELSE 0 END) AS [Group Detail with Sample], 'Previous Month' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail with Sample') THEN 1 ELSE 0 END) AS [Group Detail with Sample], 'This Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail with Sample') THEN 1 ELSE 0 END) AS [Group Detail with Sample], 'Previous Quarter' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail with Sample') THEN 1 ELSE 0 END) AS [Group Detail with Sample], 'This Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT ThisYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, SUM(CASE WHEN C.CallType IN ('Group Detail with Sample') THEN 1 ELSE 0 END) AS [Group Detail with Sample], 'Previous Year' AS [Time Period]
from cte_calldetails C
WHERE  CAST(C.CallDate AS DATE) >= (SELECT PreviousYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
) AS temp
ON LAT.[Territory Name] = temp.Territory AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'Group Detail with Sample';



--Rest All NULLS -> ZEROs where there are no values.
UPDATE Reporting_ActivityByTerritoryWithTargetTypes SET Value = 0
where Value IS NULL and Metric IN ('Total Calls', 'Call Only', 'Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample');



-----------------------------------------------------------------------------------
--------------------------------------Calls/day----------------------------------
-----------------------------------------------------------------------------------
WITH CTE_WorkDays AS
(
	select C.[User], C.Territory, CONVERT(date, C.CallDate) AS CallDate
	from Call C
	WHERE C.EndDate IS NULL
	GROUP BY C.[User], C.Territory, CONVERT(date, C. CallDate) HAVING COUNT(*) >= 4
)
UPDATE LAT
SET LAT.Value = temp.[Calls/day]
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select LAT2.[Territory Name], LAT2.TargetType, ROUND(LAT2.Value/COUNT(*), 1) AS [Calls/day], 'Previous Week' AS [Time Period]
from Reporting_ActivityByTerritoryWithTargetTypes LAT2
LEFT OUTER JOIN CTE_WorkDays WD ON LAT2.[Territory Name] = WD.Territory AND LAT2.Metric = 'Total Calls' AND LAT2.[Time Period] = 'Previous Week'
WHERE WD.CallDate >= (SELECT PreviousWeekStartDate FROM @Dates) AND WD.CallDate <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY LAT2.[Territory Name], LAT2.TargetType, LAT2.Value
UNION ALL
select LAT2.[Territory Name], LAT2.TargetType, ROUND(LAT2.Value/COUNT(*), 1) AS [Calls/day], 'This Month' AS [Time Period]
from Reporting_ActivityByTerritoryWithTargetTypes LAT2
LEFT OUTER JOIN CTE_WorkDays WD ON LAT2.[Territory Name] = WD.Territory AND LAT2.Metric = 'Total Calls' AND LAT2.[Time Period] = 'This Month'
WHERE WD.CallDate >= (SELECT ThisMonthStartDate FROM @Dates) AND WD.CallDate <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY LAT2.[Territory Name], LAT2.TargetType, LAT2.Value
UNION ALL
select LAT2.[Territory Name], LAT2.TargetType, ROUND(LAT2.Value/COUNT(*), 1) AS [Calls/day], 'Previous Month' AS [Time Period]
from Reporting_ActivityByTerritoryWithTargetTypes LAT2
LEFT OUTER JOIN CTE_WorkDays WD ON LAT2.[Territory Name] = WD.Territory AND LAT2.Metric = 'Total Calls' AND LAT2.[Time Period] = 'Previous Month'
WHERE WD.CallDate >= (SELECT PreviousMonthStartDate FROM @Dates) AND WD.CallDate <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY LAT2.[Territory Name], LAT2.TargetType, LAT2.Value
UNION ALL
select LAT2.[Territory Name], LAT2.TargetType, ROUND(LAT2.Value/COUNT(*), 1) AS [Calls/day], 'This Quarter' AS [Time Period]
from Reporting_ActivityByTerritoryWithTargetTypes LAT2
LEFT OUTER JOIN CTE_WorkDays WD ON LAT2.[Territory Name] = WD.Territory AND LAT2.Metric = 'Total Calls' AND LAT2.[Time Period] = 'This Quarter'
WHERE WD.CallDate >= (SELECT ThisQuarterStartDate FROM @Dates) AND WD.CallDate <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY LAT2.[Territory Name], LAT2.TargetType, LAT2.Value
UNION ALL
select LAT2.[Territory Name], LAT2.TargetType, ROUND(LAT2.Value/COUNT(*), 1) AS [Calls/day], 'Previous Quarter' AS [Time Period]
from Reporting_ActivityByTerritoryWithTargetTypes LAT2
LEFT OUTER JOIN CTE_WorkDays WD ON LAT2.[Territory Name] = WD.Territory AND LAT2.Metric = 'Total Calls' AND LAT2.[Time Period] = 'Previous Quarter'
WHERE WD.CallDate >= (SELECT PreviousQuarterStartDate FROM @Dates) AND WD.CallDate <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY LAT2.[Territory Name], LAT2.TargetType, LAT2.Value
UNION ALL
select LAT2.[Territory Name], LAT2.TargetType, ROUND(LAT2.Value/COUNT(*), 1) AS [Calls/day], 'This Year' AS [Time Period]
from Reporting_ActivityByTerritoryWithTargetTypes LAT2
LEFT OUTER JOIN CTE_WorkDays WD ON LAT2.[Territory Name] = WD.Territory AND LAT2.Metric = 'Total Calls' AND LAT2.[Time Period] = 'This Year'
WHERE WD.CallDate >= (SELECT ThisYearStartDate FROM @Dates) AND WD.CallDate <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY LAT2.[Territory Name], LAT2.TargetType, LAT2.Value
UNION ALL
select LAT2.[Territory Name], LAT2.TargetType, ROUND(LAT2.Value/COUNT(*), 1) AS [Calls/day], 'Previous Year' AS [Time Period]
from Reporting_ActivityByTerritoryWithTargetTypes LAT2
LEFT OUTER JOIN CTE_WorkDays WD ON LAT2.[Territory Name] = WD.Territory AND LAT2.Metric = 'Total Calls' AND LAT2.[Time Period] = 'Previous Year'
WHERE WD.CallDate >= (SELECT PreviousYearStartDate FROM @Dates) AND WD.CallDate <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY LAT2.[Territory Name], LAT2.TargetType, LAT2.Value
) AS temp
ON LAT.[Territory Name] = temp.[Territory Name] AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'Calls/day';

-----------------------------------------------------------------------------------
--------------------------------------HCPs Detailed----------------------------------
-----------------------------------------------------------------------------------
WITH cte_calldetails AS
(
SELECT C.Territory, C.CallId, C.CallDate, C.CallType, C.Account, A.CNXTargetTypec AS TargetType
from Call C
INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL
WHERE C.EndDate IS NULL
)
UPDATE LAT
SET LAT.Value = temp.[HCPs Detailed]
FROM Reporting_ActivityByTerritoryWithTargetTypes AS LAT
INNER JOIN
(
select C.Territory, C.TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed], 'Previous Week' AS [Time Period]
from cte_calldetails C
WHERE  C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample') AND CAST(C.CallDate AS DATE) >= (SELECT PreviousWeekStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousWeekEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed], 'This Month' AS [Time Period]
from cte_calldetails C
WHERE  C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample') AND CAST(C.CallDate AS DATE) >= (SELECT ThisMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed], 'Previous Month' AS [Time Period]
from cte_calldetails C
WHERE  C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample') AND CAST(C.CallDate AS DATE) >= (SELECT PreviousMonthStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousMonthEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed], 'This Quarter' AS [Time Period]
from cte_calldetails C
WHERE  C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample') AND CAST(C.CallDate AS DATE) >= (SELECT ThisQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed], 'Previous Quarter' AS [Time Period]
from cte_calldetails C
WHERE  C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample') AND CAST(C.CallDate AS DATE) >= (SELECT PreviousQuarterStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousQuarterEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed], 'This Year' AS [Time Period]
from cte_calldetails C
WHERE  C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample') AND CAST(C.CallDate AS DATE) >= (SELECT ThisYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT ThisYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
UNION ALL
select C.Territory, C.TargetType, COUNT(DISTINCT C.Account) AS [HCPs Detailed], 'Previous Year' AS [Time Period]
from cte_calldetails C
WHERE  C.CallType IN ('Detail Only', 'Group Detail', 'Detail with Sample', 'Group Detail with Sample') AND CAST(C.CallDate AS DATE) >= (SELECT PreviousYearStartDate FROM @Dates) AND CAST(C.CallDate AS DATE) <= (SELECT PreviousYearEndDate FROM @Dates)
GROUP BY C.Territory, C.TargetType
) AS temp
ON LAT.[Territory Name] = temp.Territory AND LAT.[Time Period] = temp.[Time Period] AND ISNULL(LAT.TargetType, -1) = ISNULL(temp.TargetType, -1) AND LAT.Metric = 'HCPs Detailed';


--Rest All NULLS -> ZEROs where there are no values.
UPDATE Reporting_ActivityByTerritoryWithTargetTypes SET Value = 0
where Value IS NULL and Metric IN ('Calls/day', 'HCPs Detailed');


UPDATE R SET R.[Territory Name] = ISNULL(T.Description, T.Name)
FROM Reporting_ActivityByTerritoryWithTargetTypes R
INNER JOIN Territory T ON R.[Territory Name] = T.Name AND T.EndDate IS NULL;


IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_ActivityByTerritoryWithTargetTypes_TimePeriod')   
    DROP INDEX IX_Reporting_ActivityByTerritoryWithTargetTypes_TimePeriod ON dbo.Reporting_ActivityByTerritoryWithTargetTypes;
CREATE NONCLUSTERED INDEX IX_Reporting_ActivityByTerritoryWithTargetTypes_TimePeriod ON dbo.Reporting_ActivityByTerritoryWithTargetTypes ([Time Period] ASC);  

IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_ActivityByTerritoryWithTargetTypes_Metric')   
    DROP INDEX IX_Reporting_ActivityByTerritoryWithTargetTypes_Metric ON dbo.Reporting_ActivityByTerritoryWithTargetTypes;
CREATE NONCLUSTERED INDEX IX_Reporting_ActivityByTerritoryWithTargetTypes_Metric ON dbo.Reporting_ActivityByTerritoryWithTargetTypes ([Metric] ASC);  


IF EXISTS (SELECT name FROM sys.indexes WHERE name = N'IX_Reporting_ActivityByTerritoryWithTargetTypes_TargetType')   
    DROP INDEX IX_Reporting_ActivityByTerritoryWithTargetTypes_TargetType ON dbo.Reporting_ActivityByTerritoryWithTargetTypes;
CREATE NONCLUSTERED INDEX IX_Reporting_ActivityByTerritoryWithTargetTypes_TargetType ON dbo.Reporting_ActivityByTerritoryWithTargetTypes (TargetType ASC);  



TRUNCATE TABLE Reporting_ActivityByTerritoryWithTargetTypes_KPI;

INSERT INTO Reporting_ActivityByTerritoryWithTargetTypes_KPI
SELECT [Time Period], [TimePeriodInteger], Metric, SUM(Value) AS TotalCalls 
FROM Reporting_ActivityByTerritoryWithTargetTypes
WHERE Metric <> 'Calls/day'
GROUP BY [Time Period], [TimePeriodInteger], Metric
UNION ALL
SELECT [Time Period], [TimePeriodInteger], Metric, AVG(Value) AS TotalCalls 
FROM Reporting_ActivityByTerritoryWithTargetTypes
WHERE Metric = 'Calls/day'
GROUP BY [Time Period], [TimePeriodInteger], Metric;



END


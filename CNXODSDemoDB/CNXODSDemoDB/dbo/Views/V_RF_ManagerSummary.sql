
CREATE   VIEW [dbo].[V_RF_ManagerSummary]
AS
WITH CTE_RequiredFrequency AS
(
	SELECT CAST(ROUND(
		(
			(DATEDIFF(dd, dbo.fn_getQuarterStarteDate('Current'), GETDATE()) + 1)
			-(DATEDIFF(wk, dbo.fn_getQuarterStarteDate('Current'), GETDATE()) * 2)
			-(CASE WHEN DATENAME(dw, dbo.fn_getQuarterStarteDate('Current')) = 'Sunday' THEN 1 ELSE 0 END)
			-(CASE WHEN DATENAME(dw, GETDATE()) = 'Saturday' THEN 1 ELSE 0 END)
		) * 1.0 / 
		(
			(DATEDIFF(dd, dbo.fn_getQuarterStarteDate('Current'), DATEADD(dd, -1, dbo.fn_getQuarterStarteDate('Next'))) + 1)
			-(DATEDIFF(wk, dbo.fn_getQuarterStarteDate('Current'), DATEADD(dd, -1, dbo.fn_getQuarterStarteDate('Next'))) * 2)
			-(CASE WHEN DATENAME(dw, dbo.fn_getQuarterStarteDate('Current')) = 'Sunday' THEN 1 ELSE 0 END)
			-(CASE WHEN DATENAME(dw, DATEADD(dd, -1, dbo.fn_getQuarterStarteDate('Next'))) = 'Saturday' THEN 1 ELSE 0 END)
		) * 100, 0) AS INT) AS [Req Freq %]
),
CTE AS
(
	SELECT temp.UserId, temp.QuarterString, SUM(temp.WorkDays) AS WorkDays
	FROM
	(
		SELECT DISTINCT M.UserId, S.TerritoryId, S.QuarterString, WorkDays
		from V_RF_UserTerritoryCallSummary S
		INNER JOIN [User] U ON S.UserId = U.UserId AND U.EndDate IS NULL AND U.IsActive = 'True'
		INNER JOIN [User] M ON U.ManagerId = M.ExternalId1 AND M.EndDate IS NULL AND M.IsActive = 'True'
	) AS temp
	GROUP BY temp.UserId, temp.QuarterString
)
SELECT M.UserId, M.Name AS ManagerName, S.TargetType, S.QuarterString,
	CASE S.TargetType WHEN 'Tier 1' THEN 1 WHEN 'Tier 2' THEN 2 WHEN 'Tier 3' THEN 3 WHEN 'Target' THEN 4 END AS TargetTypeInteger,
	MAX(WD.WorkDays) AS WorkDays, SUM(S.[#Targets]) AS [#Targets], SUM(S.[#TargetCalled]) AS [#TargetCalled], 
	SUM(S.[#Calls]) AS [#Calls], SUM(S.DesiredCalls) AS DesiredCalls, FORMAT(SUM(S.[#TargetCalled]) * 100.0 / SUM(S.[#Targets]), 'N0') AS [% Reach],
	SUM(CEILING(S.[Freq Goal])) AS [Freq Goal per HCP], SUM(S.[Freq Achieved]) AS [#Targets FreqAchieved], SUM(S.[Freq Achieved]) * 100 / SUM(S.[#Targets]) AS [Freq %],
	CASE WHEN S.QuarterString = 'Previous' THEN 100 ELSE (SELECT [Req Freq %] FROM CTE_RequiredFrequency) END AS [Req Freq %]
from V_RF_UserTerritoryCallSummary S
INNER JOIN [User] U ON S.UserId = U.UserId AND U.EndDate IS NULL AND U.IsActive = 'True'
INNER JOIN [User] M ON U.ManagerId = M.ExternalId1 AND M.EndDate IS NULL AND M.IsActive = 'True'
LEFT OUTER JOIN CTE WD ON M.UserId = WD.UserId AND S.QuarterString = WD.QuarterString
--WHERE EXISTS (SELECT 1 FROM UserTerritory UT WHERE UT.UserId = M.UserId)
GROUP BY M.UserId, M.Name, S.TargetType, S.QuarterString



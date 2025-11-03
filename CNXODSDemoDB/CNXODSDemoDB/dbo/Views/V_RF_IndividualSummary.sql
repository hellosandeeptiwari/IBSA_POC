
CREATE   VIEW [dbo].[V_RF_IndividualSummary]
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
cte AS(
SELECT CUS.UserId, CUS.TerritoryId, CUS.TargetType, CUS.[#Targets], CUS.[#TargetCalled], CUS.[#Calls], ISNULL(DC.DesiredCalls, 0) AS DesiredCalls, 
	FORMAT(CUS.[#TargetCalled] * 100.0 / CUS.[#Targets], 'N0') AS [% Reach],
	CASE WHEN CUS.[#Targets] = 0 THEN 0 ELSE ROUND((ISNULL(WD.WorkDays, 0) * ISNULL(DC.DesiredCalls, 0))/(CUS.[#Targets] * 12.0 * 5.0), 2) END AS [Freq Goal],
	ISNULL(WD.WorkDays, 0) AS WorkDays, CUS.QuarterString
from V_RF_CallUserSummary CUS 
LEFT OUTER JOIN V_RF_DesiredCalls DC ON CUS.UserId = DC.UserId AND CUS.TargetType = DC.TargetType AND CUS.QuarterString = DC.QuarterString
LEFT OUTER JOIN V_RF_UserWorkingDays WD ON CUS.UserId = WD.UserId AND CUS.QuarterString = WD.QuarterString
)

select S.UserId, U.Name AS RepName, S.TerritoryId, ISNULL(T.Description, T.Name) AS Territory, 
	S.TargetType, CASE S.TargetType WHEN 'UT (Ultra Target)' THEN 1 WHEN 'ST (Super Target)' THEN 2 WHEN 'T (Target)' THEN 3 WHEN 'NT (Non Target)' THEN 4 END AS TargetTypeInteger,
	S.[#Targets], S.[#TargetCalled], S.[#Calls], S.DesiredCalls, 
	S.[% Reach], CEILING(S.[Freq Goal]) AS [Freq Goal per HCP], S.WorkDays, S.QuarterString, count(D.UserId) AS [#Targets FreqAchieved],
	count(D.UserId) * 100 / S.[#Targets] AS [Freq %], 
	CASE WHEN S.QuarterString = 'Previous' THEN 100 ELSE (SELECT [Req Freq %] FROM CTE_RequiredFrequency) END AS [Req Freq %],
	CAST(S.UserId AS VARCHAR(40)) + ',' + CAST(S.TerritoryId AS VARCHAR(40)) + ',' + S.TargetType + ',' + CASE WHEN S.QuarterString = 'Previous' THEN 'P' ELSE 'C' END AS PK
FROM cte S
INNER JOIN [User] U ON S.UserId = U.UserId AND U.EndDate IS NULL AND U.IsActive = 'True'
INNER JOIN [Territory] T ON S.TerritoryId = T.TerritoryId AND T.EndDate IS NULL --Consider only active territories
LEFT OUTER JOIN V_RF_UserTerritoryCallDetails D 
	ON S.UserId = D.UserId AND S.TerritoryId = D.TerritoryId AND S.TargetType = D.TargetType AND 
	S.[Freq Goal] <> 0 AND D.ActualCalls >= S.[Freq Goal] AND S.QuarterString = D.QuarterString
GROUP by S.UserId, U.Name, S.TerritoryId, ISNULL(T.Description, T.Name), S.TargetType, S.[#Targets], S.[#TargetCalled], 
	S.[#Calls], S.DesiredCalls, S.[% Reach], S.[Freq Goal], S.WorkDays, S.QuarterString


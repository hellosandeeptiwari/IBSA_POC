CREATE VIEW [dbo].[V_RF_UserTerritoryCallSummary]
AS
WITH cte AS(
SELECT CUS.UserId, CUS.TerritoryId, CUS.TargetType, CUS.[#Targets], CUS.[#TargetCalled], CUS.[#Calls], ISNULL(DC.DesiredCalls, 0) AS DesiredCalls, 
	FORMAT(CUS.[#TargetCalled] * 100.0 / CUS.[#Targets], 'N0') AS [% Reach],
	CASE WHEN CUS.[#Targets] = 0 THEN 0 ELSE ROUND((ISNULL(WD.WorkDays, 0) * ISNULL(DC.DesiredCalls, 0))/(CUS.[#Targets] * 12.0 * 5.0), 2) END AS [Freq Goal],
	ISNULL(WD.WorkDays, 0) AS WorkDays, CUS.QuarterString
from V_RF_CallUserSummary CUS 
LEFT OUTER JOIN V_RF_DesiredCalls DC ON CUS.UserId = DC.UserId AND CUS.TargetType = DC.TargetType AND CUS.QuarterString = DC.QuarterString
LEFT OUTER JOIN V_RF_UserWorkingDays WD ON CUS.UserId = WD.UserId AND DC.QuarterString = WD.QuarterString
)select S.UserId, S.TerritoryId, S.TargetType, S.[#Targets], S.[#TargetCalled], S.[#Calls], S.DesiredCalls, 
	S.[% Reach], S.[Freq Goal], S.WorkDays, S.QuarterString, count(D.UserId) AS [Freq Achieved],
	count(D.UserId) * 100 / S.[#Targets] AS [Freq %]
FROM cte S
LEFT OUTER JOIN V_RF_UserTerritoryCallDetails D 
	ON S.UserId = D.UserId AND S.TerritoryId = D.TerritoryId AND S.TargetType = D.TargetType AND 
	S.[Freq Goal] <> 0 AND D.ActualCalls >= S.[Freq Goal] AND S.QuarterString = D.QuarterString
GROUP by S.UserId, S.TerritoryId, S.TargetType, S.[#Targets], S.[#TargetCalled], S.[#Calls], 
	S.DesiredCalls, S.[% Reach], S.[Freq Goal], S.WorkDays, S.QuarterString


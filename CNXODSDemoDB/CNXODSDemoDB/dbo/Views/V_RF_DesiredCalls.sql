
CREATE   VIEW [dbo].[V_RF_DesiredCalls]
AS  
WITH cte AS
(
	select U.UserId, 
		CASE ISNULL(A.CNXTargetTypec, 'NT (Non Target)')
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			WHEN 'NT (Non Target)' THEN 'NT (Non Target)'
	END AS TargetType, 
	CASE ISNULL(A.CNXTargetTypec, 'NT (Non Target)') WHEN 'UT (Ultra Target)' THEN 12 WHEN 'ST (Super Target)' THEN 6 WHEN 'T (Target)' THEN 3 WHEN 'NT (Non Target)' THEN 0 END
	AS PlannedCalls
	from UserTerritory UT
	INNER JOIN [User] U ON UT.UserId = U.ExternalId1 AND U.EndDate IS NULL
	INNER JOIN ATL AT ON UT.TerritoryId = AT.Territory AND UT.EndDate IS NULL AND AT.EndDate IS NULL
	INNER JOIN Account A ON AT.Account = A.ExternalId1 AND A.EndDate IS NULL and A.IsPersonAccount = 'True'
	INNER JOIN Territory T ON AT.Territory = T.ExternalId1 AND T.EndDate IS NULL --Consider only active territories
)
SELECT UserId, TargetType, 'Current' AS QuarterString, SUM(PlannedCalls) AS DesiredCalls
FROM cte
GROUP by UserId, TargetType
UNION
SELECT UserId, TargetType, 'Previous' AS QuarterString, SUM(PlannedCalls) AS DesiredCalls
FROM cte
GROUP by UserId, TargetType


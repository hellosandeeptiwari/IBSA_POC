
CREATE   VIEW [dbo].[V_RF_CallUserSummary]
AS
WITH CTE_Account AS
(
	select 
		AccountId, ExternalId1,
		CASE ISNULL(CNXTargetTypec, 'NT (Non Target)')
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			WHEN 'NT (Non Target)' THEN 'NT (Non Target)'
		END AS TargetType,
		FormattedName,
		Specialty1 AS Specialty
	from Account where EndDate IS NULL and IsPersonAccount = 'True'
),  
cte AS
(
	select U.UserId, T.TerritoryId, A.TargetType, 'Current' AS QuarterString, 
	count(DISTINCT AT.Account) AS TargetCount, count(DISTINCT C.Account) AS TargetCalledCount, count(C.CallId) As CallCount
	from UserTerritory UT
	INNER JOIN [User] U ON UT.UserId = U.ExternalId1 AND U.EndDate IS NULL
	INNER JOIN ATL AT ON UT.TerritoryId = AT.Territory AND UT.EndDate IS NULL AND AT.EndDate IS NULL
	INNER JOIN Territory T ON AT.Territory = T.ExternalId1 AND T.EndDate IS NULL --Consider only active territories
	INNER JOIN CTE_Account A ON AT.Account = A.ExternalId1
	LEFT OUTER JOIN Call C ON UT.UserId = C.VeevaCreatedById AND AT.Account = C.Account AND UT.TerritoryId = T.ExternalId1 AND C.EndDate IS NULL -- Anis: 2019-01-27 -- AND C.ParentCallId IS NOT NULL
		AND C.CallDate >= dbo.fn_getQuarterStarteDate('Current')
	group by U.UserId, T.TerritoryId, TargetType
	UNION
	select U.UserId, T.TerritoryId, A.TargetType, 'Previous' AS QuarterString, 
	count(DISTINCT AT.Account) AS TargetCount, count(DISTINCT C.Account) AS TargetCalledCount, count(C.CallId) As CallCount
	from UserTerritory UT
	INNER JOIN [User] U ON UT.UserId = U.ExternalId1 AND U.EndDate IS NULL
	INNER JOIN ATL AT ON UT.TerritoryId = AT.Territory AND UT.EndDate IS NULL AND AT.EndDate IS NULL
	INNER JOIN Territory T ON AT.Territory = T.ExternalId1 AND T.EndDate IS NULL --Consider only active territories
	INNER JOIN CTE_Account A ON AT.Account = A.ExternalId1
	LEFT OUTER JOIN Call C ON UT.UserId = C.VeevaCreatedById AND AT.Account = C.Account AND UT.TerritoryId = T.ExternalId1  AND C.EndDate IS NULL  -- Anis: 2019-01-27 -- AND C.ParentCallId IS NOT NULL
		AND C.CallDate >= dbo.fn_getQuarterStarteDate('Previous') AND C.CallDate < dbo.fn_getQuarterStarteDate('Current')
	group by U.UserId, T.TerritoryId, TargetType
)
SELECT UserId, TerritoryId, TargetType, QuarterString, SUM(TargetCount) AS [#Targets], SUM(TargetCalledCount) AS [#TargetCalled], SUM(CallCount) AS [#Calls]
FROM cte 
GROUP by UserId, TerritoryId, TargetType, QuarterString


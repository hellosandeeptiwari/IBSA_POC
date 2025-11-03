CREATE   VIEW [dbo].[V_RF_UserTerritoryCallDetails]
AS
WITH CTE_Account AS
(
	select 
		AccountId, 
		ExternalId1,
		CASE ISNULL(CNXTargetTypec, 'NT (Non Target)')
			WHEN 'UT (Ultra Target)' THEN 'UT (Ultra Target)'
			WHEN 'ST (Super Target)' THEN 'ST (Super Target)'
			WHEN 'T (Target)' THEN 'T (Target)'
			WHEN 'NT (Non Target)' THEN 'NT (Non Target)'
		END AS TargetType,
		FormattedName,
		Specialty1 AS Specialty
	from Account where EndDate IS NULL and IsPersonAccount = 'True'
)
select 
U.UserId, T.TerritoryId, A.TargetType, A.FormattedName AS HCPName, A.Specialty, QuarterString,
MAX(CONVERT(date, C.CallDate)) AS LastCallDate, count(C.CallId) AS ActualCalls
from
(
	SELECT *, CASE WHEN CallDate >= dbo.fn_getQuarterStarteDate('Previous') AND CallDate < dbo.fn_getQuarterStarteDate('Current') THEN 'Previous' ELSE 'Current' END AS QuarterString 
	FROM Call WHERE CallDate >= dbo.fn_getQuarterStarteDate('Previous') AND EndDate IS NULL
) AS C 
INNER JOIN Territory T1 ON C.Territory = T1.Name AND T1.EndDate IS NULL
INNER JOIN [UserTerritory] UT ON C.VeevaCreatedById = UT.UserId AND T1.ExternalId1 = UT.TerritoryId AND UT.EndDate IS NULL
INNER JOIN [User] U ON UT.UserId = U.ExternalId1 AND U.EndDate IS NULL
INNER JOIN ATL AT ON C.Account = AT.Account AND T1.ExternalId1 = AT.Territory AND AT.EndDate IS NULL
INNER JOIN Territory T ON AT.Territory = T.ExternalId1 AND T.EndDate IS NULL --Consider only active territories
INNER JOIN CTE_Account A ON AT.Account = A.ExternalId1
group by U.UserId, T.TerritoryId, TargetType, A.FormattedName, A.Specialty, QuarterString


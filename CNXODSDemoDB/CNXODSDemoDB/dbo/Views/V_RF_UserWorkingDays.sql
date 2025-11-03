
CREATE   VIEW [dbo].[V_RF_UserWorkingDays]
AS
WITH cte AS
(
	SELECT U.UserId, CONVERT(date, C.CallDate) AS CallDate, 
		CASE WHEN CONVERT(date, C.CallDate) >= dbo.fn_getQuarterStarteDate('Previous') AND CONVERT(date, C.CallDate) < dbo.fn_getQuarterStarteDate('Current') THEN 'Previous' ELSE 'Current' END AS QuarterString
	from Call C
	INNER JOIN Account A ON C.Account = A.ExternalId1 AND A.EndDate IS NULL  and A.IsPersonAccount = 'True'
	INNER JOIN [User] U ON C.VeevaCreatedById = U.ExternalId1 AND U.EndDate IS NULL
	where C.CallDate >= dbo.fn_getQuarterStarteDate('Previous') AND C.EndDate IS NULL
	GROUP BY U.UserId, CONVERT(date, C.CallDate)
	HAVING count(C.VeevaCreatedById) >= 4
) SELECT cte.UserId, QuarterString, count(*) AS WorkDays
from cte
GROUP BY cte.UserId, QuarterString


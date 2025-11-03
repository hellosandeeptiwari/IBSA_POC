
CREATE   VIEW [dbo].[V_SCD_ActiveAccounts]
AS
	SELECT A.externalId1 VeevaAccountId, A.firstName, A.lastName, A.name 
	FROM account A 
	WHERE A.Enddate is NULL


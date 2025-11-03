
CREATE   VIEW [dbo].[V_SCD_ActiveAddresses] 
AS
	SELECT A.externalId1 VeevaAccountId, AD.externalId1 VeevaAddressId, AD.Name AS AddressLine1
	FROM accountAddress AD
	INNER JOIN account A ON AD.account = A.ExternalId1
	AND AD.EndDate IS NULL
	AND A.EndDate IS NULL


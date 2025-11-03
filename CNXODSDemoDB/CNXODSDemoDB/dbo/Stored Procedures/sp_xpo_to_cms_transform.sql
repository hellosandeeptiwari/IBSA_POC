
CREATE   PROCEDURE [dbo].[sp_xpo_to_cms_transform] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON	

INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_xpo_to_cms_transform', 'Started', GETUTCDATE());


INSERT INTO CMS_Account
(
	XPOPrescriberNo, Source, FirstName, LastName, Name, IsPerson, MENumber, NPINumber, CreatedUtcDate
)
SELECT
	A.IMSID, 'XPO', A.F_Name, A.L_Name, A.DisplayName, 1 AS IsPerson, A.ME, A.NPI, getutcdate()
FROM SalesAccount A
WHERE NOT EXISTS (SELECT 1 FROM CMS_Account C WHERE C.XPOPrescriberNo = A.IMSID AND C.Source = 'XPO');


INSERT INTO CMS_AccountAddress
	(CmsId, Source, PrimaryAddressIndicator, AddressLine1, City, State, ZipCode, CreatedUtcDate)
SELECT
	C.CmsId, 'XPO', 1, SA.Address, SA.City, SA.State, SA.ZipCode, GETUTCDATE()
FROM SalesAccount SA
INNER JOIN CMS_Account C ON SA.IMSID = C.XPOPrescriberNo AND C.Source = 'XPO' AND C.EndUtcDate IS NULL
WHERE NOT EXISTS (	SELECT 1 FROM CMS_AccountAddress CAA 
					INNER JOIN CMS_Account CA on CA.CmsId = CAA.CmsId AND CAA.Source = 'XPO'
					WHERE SA.IMSID = CA.XPOPrescriberNo);


INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_xpo_to_cms_transform', 'Completed', GETUTCDATE());

END



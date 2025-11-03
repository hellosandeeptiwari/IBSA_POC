
CREATE   PROCEDURE [dbo].[sp_ods_to_cms_transform] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON	

INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_ods_to_cms_transform', 'Started', GETUTCDATE());


insert into CMS_Account
(
	OdsId, VeevaId, XPOPrescriberNo, DDDOutletZipId, Source, AccountType, AccountSubType, 
	ExternalId2, ExternalId3, Status, ComputedStatus, FirstName, LastName, MiddleName, Name, 
	AlternateName, FormattedName, PreferredName, Suffix, Title, Salutation, Gender, DateOfBirth, 
	IsPerson, PracticeAtHospital, NumberOfDepartments, AccountDescription, IMSId, MENumber, 
	AHANumber, NPINumber, DEA, HIN, ClientAccountId, ClientExtraId, ClientExtraId2, 
	ProfessionalDesignation, PDRPOptOutFlag, RecordTypeId, IsLocked, MayEdit, IsDeleted, Phone, 
	Fax, Specialty1, Specialty2, PrimaryParentAccount_ExternalId1, CreatedUtcDate, 
	ExternalUpdatedUtcDate, VeevaUpdatedUtcDate, UpdatedBy, EndUtcDate, DoNotCall, Credentials, 
	GenText1, GenText2, GenText3, GenText4, GenText5, GenText6, GenText7, GenText8, GenText9, 
	GenText10, GenText11, GenText12, GenText13, GenText14, GenText15, GenText16, GenText17, 
	GenText18, GenText19, GenText20, GenInteger1, GenInteger2, GenInteger3, GenInteger4, 
	GenInteger5, GenBoolean1, GenBoolean2, GenBoolean3, GenBoolean4, GenBoolean5, GenBoolean6, 
	GenBoolean7, GenBoolean8, GenBoolean9, GenBoolean10, GenBoolean11, GenBoolean12, 
	GenBoolean13, GenBoolean14, GenBoolean15, GenBoolean16, GenBoolean17, GenBoolean18, 
	GenBoolean19, GenBoolean20, GenBoolean21, GenBoolean22, GenBoolean23, GenBoolean24, GenBoolean25, 
	GenDecimal1, GenDecimal2, GenDecimal3, GenDecimal4, GenDecimal5, GenDateTime1, GenDateTime2, 
	GenDateTime3, GenDateTime4, GenDateTime5
)
SELECT

-- Standard Fields
A.AccountId, A.ExternalId1, NULL, NULL, 'VEEV', A.AccountType, 
A.AccountSubType, A.ExternalId2, A.ExternalId3, A.Status, A.ComputedStatus, A.FirstName, A.LastName, 
A.MiddleName, A.Name, NULL, NULL, NULL, A.Suffix, A.Title, 
A.Salutation, A.Gender, A.DateOfBirth, A.IsPerson, A.PracticeAtHospital, NULL, A.AccountDescription, 
NULL, A.MENumber, A.AHANumber, A.NPINumber, NULL, NULL, A.ClientAccountId, 
NULL, A.ClientExtraId2, A.ProfessionalDesignation, A.PDRPOptOutFlag, A.RecordTypeId, A.IsLocked, 
A.MayEdit, A.IsDeleted, A.Phone, A.Fax, NULL as Specialty1, NULL as Specialty2, 
A.PrimaryParentAccountId, getutcdate(), NULL, NULL, NULL, NULL, A.DoNotCall, A.Credentials, 

-- Text fields
NULL, NULL, NULL, NULL, NULL, NULL, 
NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
NULL, NULL, NULL, NULL, NULL, NULL,
NULL,

-- Integer Fields
NULL, NULL, NULL, NULL, NULL, 

-- Boolean Fields
NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

-- Decimal Fields
NULL, NULL, NULL, NULL, NULL,

-- DateTime fields
NULL, NULL, NULL, NULL, NULL

FROM Account A
WHERE A.EndDate is null
AND NOT EXISTS (SELECT 1 FROM CMS_Account C WHERE C.VeevaId = A.ExternalId1);


INSERT INTO CMS_AccountAddress
(
	CmsId, McKessonId, OdsAddressId, VeevaAddressId, Source, AddressType, PrimaryAddressIndicator, 
	AddressDescription, ExternalId2, InActive, ComputedStatus, AddressLine1, AddressLine2, City, 
	State, Province, Country, ZipCode, ZipCodeExtension, Latitude, Longitude, MailingAddressIndicator, 
	BillingAddressIndicator, ShippingAddressIndicator, SamplingAddressIndicator, HomeAddressIndicator, 
	BusinessAddressIndicator, Comments, StateLicenseNumber, StateLicenseStatus, 
	StateLicenseExpirationDate, StateLicenseState, IsDeleted, IsLocked, MayEdit, 
	CreatedUtcDate, Phone, Fax, GenText1, GenText2, GenText3, GenText4, 
	GenText5, GenText6, GenText7, GenText8, GenText9, GenText10, GenText11, GenText12, GenText13, 
	GenText14, GenText15, GenInteger1, GenInteger2, GenInteger3, GenInteger4, GenInteger5, GenBoolean1, 
	GenBoolean2, GenBoolean3, GenBoolean4, GenBoolean5, GenDecimal1, GenDecimal2, GenDecimal3, 
	GenDecimal4, GenDecimal5, GenDateTime1, GenDateTime2, GenDateTime3, GenDateTime4, GenDateTime5
)
SELECT
	C.CmsId, null, AA.AccountAddressId, AA.ExternalId1, 'VEEV', null, AA.PrimaryAddressIndicator, 
	null, AA.ExternalId2, AA.InActive, AA.ComputedStatus, AA.AddressLine1, AA.AddressLine2, AA.City, 
	AA.State, null, AA.Country, AA.ZipCode, AA.ZipCodeExtension, AA.Latitude, AA.Longitude, AA.MailingAddressIndicator, 
	AA.BillingAddressIndicator, AA.	ShippingAddressIndicator, AA.SamplingAddressIndicator, AA.HomeAddressIndicator, 
	AA.BusinessAddressIndicator, AA.Comments, AA.StateLicenseNumber, AA.StateLicenseStatus, 
	AA.StateLicenseExpirationDate, null, AA.IsDeleted, AA.IsLocked, AA.MayEdit, 	
	GETUTCDATE(), AA.Phone, AA.Fax,
	
	-- Text fields
	NULL, NULL, NULL, NULL, NULL,  
	NULL, NULL, NULL, NULL, NULL,  
	NULL, NULL, NULL, NULL, NULL, 
	
	-- Integer Fields
	NULL, NULL, NULL, NULL, NULL, 

	-- Boolean Fields
	NULL, NULL, NULL, NULL, NULL,
	
	-- Decimal Fields
	NULL, NULL, NULL, NULL, NULL, 

	-- DateTime fields
	NULL, NULL, NULL, NULL, NULL
	
FROM AccountAddress AA
INNER JOIN CMS_Account C ON AA.AccountId = C.OdsId AND C.Source = 'VEEV' AND C.EndUtcDate IS NULL AND AA.EndDate IS NULL
WHERE NOT EXISTS (SELECT 1 FROM CMS_AccountAddress CAA WHERE CAA.VeevaAddressId = AA.ExternalId1 AND CAA.Source = 'VEEV')
AND AA.InActive = 0;


INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_ods_to_cms_transform', 'Completed', GETUTCDATE());

END



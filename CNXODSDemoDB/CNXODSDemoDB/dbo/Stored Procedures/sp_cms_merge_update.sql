
CREATE   PROCEDURE [dbo].[sp_cms_merge_update]
	@accountMergeId INT,
	@status AS NVARCHAR(4),
	@populateNullFields AS BIT,
	@winnerCmsId AS INT,
	@selectedAddressMergeIds AS NVARCHAR(100),
	@primaryAddressMergeId AS INT,
	@rejectComments AS NVARCHAR(250)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON

declare @looserCmsId AS INT, 
		@mergeType AS NVARCHAR(4), 
		@matchType AS NVARCHAR(4), 
		@winnerSource AS NVARCHAR(4), 
		@cmsAddressId1 AS INT, 
		@cmsAddressId2 AS INT, 
		@addressJWScore AS decimal(5,2), 
		@addressMergeId1 AS INT, 
		@addressMergeId2 AS INT, 
		@accountType AS NVARCHAR(4)

-- Log the input variables
INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate)
SELECT 
	'sp_cms_merge_update',
		'@accountMergeId = ' + cast(@accountMergeId as nvarchar(10)) +
		'; @status = ' + @status +
		'; @populateNullFields = ' + ISNULL(cast(@populateNullFields as nvarchar(5)), 'NULL') +
		'; @winnerCmsId = ' + ISNULL(cast(@winnerCmsId as nvarchar(10)), 'NULL') +
		'; @selectedAddressMergeIds = ' + ISNULL(@selectedAddressMergeIds, 'NULL') +
		'; @primaryAddressMergeId = ' + ISNULL(cast(@primaryAddressMergeId as nvarchar(100)), 'NULL') +
		'; @rejectComments = ' + ISNULL(@rejectComments, 'NULL') ,
	GETUTCDATE() ;
	

IF @accountMergeId IS NULL
BEGIN
	SELECT 0 AS SuccessFlag, 'AccountMergeId not provided for processing the merge.' AS ErrorMessage; -- SuccessFlag, ErrorMessage
	RETURN;
END

IF @status IS NULL OR (@status IS NOT NULL AND (@status <> 'ACPT' AND @status <> 'REJT'))
BEGIN
	SELECT 0 AS SuccessFlag, 'Invalid status for processing the merge.' AS ErrorMessage; -- SuccessFlag, ErrorMessage
	RETURN;
END


-- In case DDD account is chosen as winner, we are switching it to Veeva account. This is because multiple Veeva accounts can be mapped to a single DDD account.
-- If DDD account is winner for multiple merges, then latest merge VeevaId will replace the previous merge's VeevaId and the previous merge is lost forever.
SELECT @winnerCmsId = case when @winnerCmsId = CmsId2 then CmsId1 else @winnerCmsId end FROM CMS_AccountMerge 
WHERE AccountMergeId = @accountMergeId AND Status = 'PEND';


-- Populate all the required local variables for processing the merge for both Accept & Reject.
SELECT 
	@looserCmsId = CASE WHEN CmsId1 = @winnerCmsId THEN CmsId2 ELSE CmsId1 END,
	@mergeType = MergeType, @matchType = MatchType, @cmsAddressId1 = CmsAddressId1, @cmsAddressId2 = CmsAddressId2,
	@winnerSource = A.Source, @addressJWScore = M.JWScoreForAddress, @accountType = A.AccountType
FROM CMS_AccountMerge M
LEFT OUTER JOIN CMS_Account A ON A.CmsId = @winnerCmsId
WHERE AccountMergeId = @accountMergeId AND M.Status = 'PEND';

IF @status = 'ACPT' AND @mergeType IN ('DDVE', 'XPVE')
BEGIN 
	
	select @addressMergeId1 = AddressMergeId FROM CMS_AddressMerge WHERE CmsAddressId = @cmsAddressId1 and AccountMergeId = @accountMergeId;
	select @addressMergeId2 = AddressMergeId FROM CMS_AddressMerge WHERE CmsAddressId = @cmsAddressId2 and AccountMergeId = @accountMergeId;

	-- In NMZC, NMAD matches, if either the DDD/XPO address or the corresponding matched Veeva address is not selected,
	-- then merge cannot be accepted
	IF (@matchType = 'NMZC' OR @matchType = 'NMAD') 
			AND @addressMergeId1 NOT IN (select CAST(splitdata AS INT) from dbo.fn_splitString(@selectedAddressMergeIds, ','))
			AND @addressMergeId2 NOT IN (select CAST(splitdata AS INT) from dbo.fn_splitString(@selectedAddressMergeIds, ','))
	BEGIN
		-- SuccessFlag, ErrorMessage
		SELECT 0 AS SuccessFlag, 'Neither the DDD/XPO address nor the corresponding matched Veeva address are selected.' AS ErrorMessage;
		RETURN;
	END
	
	--Replace DDD/XPO address with Veeva address since Veeva address will have more details when compraed to DDD/XPO address
	IF (@matchType = 'NMZC' OR @matchType = 'NMAD')
			AND @addressMergeId1 NOT IN (select CAST(splitdata AS INT) from dbo.fn_splitString(@selectedAddressMergeIds, ','))
			AND @addressMergeId2 IN (select CAST(splitdata AS INT) from dbo.fn_splitString(@selectedAddressMergeIds, ','))
	BEGIN
		SELECT @selectedAddressMergeIds = REPLACE(@selectedAddressMergeIds, @addressMergeId2, @addressMergeId1);
	END
END

IF @looserCmsId IS NULL
BEGIN
	-- SuccessFlag, ErrorMessage
	SELECT 0 AS SuccessFlag, 'The merge record is not in pending status. So the merge cannot be completed.' AS ErrorMessage;
	RETURN;
END


BEGIN TRY

BEGIN TRAN

IF @status = 'ACPT'
BEGIN 

	IF @mergeType = 'VEVE'
	BEGIN
		IF @accountMergeId IS NULL OR @status IS NULL OR @winnerCmsId IS NULL OR @populateNullFields IS NULL OR @selectedAddressMergeIds IS NULL OR @primaryAddressMergeId IS NULL
		BEGIN
			SELECT 0 AS SuccessFlag, 'Required input parameters are not provided for accepting the merge.' AS ErrorMessage; -- SuccessFlag, ErrorMessage
			ROLLBACK TRAN;
			RETURN;
		END
	END
	ELSE
	BEGIN
		IF @accountMergeId IS NULL OR @status IS NULL OR @winnerCmsId IS NULL OR @populateNullFields IS NULL OR @selectedAddressMergeIds IS NULL
		BEGIN
			SELECT 0 AS SuccessFlag, 'Required input parameters are not provided for accepting the merge.' AS ErrorMessage; -- SuccessFlag, ErrorMessage
			ROLLBACK TRAN;
			RETURN;
		END
	END

	-- Make the Looser as InActive in CMS. 
	-- DDD account cannot be End dated since a single DDD account can be matched to multiple Veeva accounts.
	UPDATE CMS_Account SET EndUtcDate = GETUTCDATE(), ExternalUpdatedUtcDate = GETUTCDATE() WHERE CmsId = @looserCmsId AND Source <> 'DDD';


	IF @mergeType in ('DDVE', 'XPVE')
	BEGIN

		IF @populateNullFields = 1 OR @winnerSource <> 'VEEV'
		BEGIN
			-- Update Winner with data from Looser.
			UPDATE W SET
				OdsId = CASE WHEN W.OdsId IS NULL THEN L.OdsId ELSE W.OdsId END, 
				VeevaId = CASE WHEN W.VeevaId IS NULL THEN L.VeevaId ELSE W.VeevaId END, 
				XPOPrescriberNo = CASE WHEN W.XPOPrescriberNo IS NULL THEN L.XPOPrescriberNo ELSE W.XPOPrescriberNo END,
				DDDOutletZipId = CASE WHEN W.DDDOutletZipId IS NULL THEN L.DDDOutletZipId ELSE W.DDDOutletZipId END,
				AccountType = CASE WHEN W.AccountType IS NULL THEN L.AccountType ELSE W.AccountType END,
				AccountSubType = CASE WHEN W.AccountSubType IS NULL THEN L.AccountSubType ELSE W.AccountSubType END,
				ExternalId2 = CASE WHEN W.ExternalId2 IS NULL THEN L.ExternalId2 ELSE W.ExternalId2 END,
				ExternalId3 = CASE WHEN W.ExternalId3 IS NULL THEN L.ExternalId3 ELSE W.ExternalId3 END,
				Status = CASE WHEN W.Status IS NULL THEN L.Status ELSE W.Status END,
				ComputedStatus = CASE WHEN W.ComputedStatus IS NULL THEN L.ComputedStatus ELSE W.ComputedStatus END,
				FirstName = CASE WHEN W.FirstName IS NULL THEN L.FirstName ELSE W.FirstName END,
				LastName = CASE WHEN W.LastName IS NULL THEN L.LastName ELSE W.LastName END,
				MiddleName = CASE WHEN W.MiddleName IS NULL THEN L.MiddleName ELSE W.MiddleName END,
				Name = CASE WHEN W.Name IS NULL THEN L.Name ELSE W.Name END,
				AlternateName = CASE WHEN W.AlternateName IS NULL THEN L.AlternateName ELSE W.AlternateName END,
				FormattedName = CASE WHEN W.FormattedName IS NULL THEN L.FormattedName ELSE W.FormattedName END,
				PreferredName = CASE WHEN W.PreferredName IS NULL THEN L.PreferredName ELSE W.PreferredName END,
				Suffix = CASE WHEN W.Suffix IS NULL THEN L.Suffix ELSE W.Suffix END,
				Title = CASE WHEN W.Title IS NULL THEN L.Title ELSE W.Title END,
				Salutation = CASE WHEN W.Salutation IS NULL THEN L.Salutation ELSE W.Salutation END,
				Gender = CASE WHEN W.Gender IS NULL THEN L.Gender ELSE W.Gender END,
				DateOfBirth = CASE WHEN W.DateOfBirth IS NULL THEN L.DateOfBirth ELSE W.DateOfBirth END,
				IsPerson = CASE WHEN W.IsPerson IS NULL THEN L.IsPerson ELSE W.IsPerson END,
				PracticeAtHospital = CASE WHEN W.PracticeAtHospital IS NULL THEN L.PracticeAtHospital ELSE W.PracticeAtHospital END,
				AccountDescription = CASE WHEN W.AccountDescription IS NULL THEN L.AccountDescription ELSE W.AccountDescription END,
				MENumber = CASE WHEN W.MENumber IS NULL THEN L.MENumber ELSE W.MENumber END,
				AHANumber = CASE WHEN W.AHANumber IS NULL THEN L.AHANumber ELSE W.AHANumber END,
				NPINumber = CASE WHEN W.NPINumber IS NULL THEN L.NPINumber ELSE W.NPINumber END,
				HIN = CASE WHEN W.HIN IS NULL THEN L.HIN ELSE W.HIN END,
				ClientAccountId = CASE WHEN W.ClientAccountId IS NULL THEN L.ClientAccountId ELSE W.ClientAccountId END,
				ClientExtraId2 = CASE WHEN W.ClientExtraId2 IS NULL THEN L.ClientExtraId2 ELSE W.ClientExtraId2 END,
				ProfessionalDesignation = CASE WHEN W.ProfessionalDesignation IS NULL THEN L.ProfessionalDesignation ELSE W.ProfessionalDesignation END,
				PDRPOptOutFlag = CASE WHEN W.PDRPOptOutFlag IS NULL THEN L.PDRPOptOutFlag ELSE W.PDRPOptOutFlag END,
				RecordTypeId = CASE WHEN W.RecordTypeId IS NULL THEN L.RecordTypeId ELSE W.RecordTypeId END,				
				IsLocked = CASE WHEN W.IsLocked IS NULL THEN L.IsLocked ELSE W.IsLocked END,
				MayEdit = CASE WHEN W.MayEdit IS NULL THEN L.MayEdit ELSE W.MayEdit END,
				IsDeleted = CASE WHEN W.IsDeleted IS NULL THEN L.IsDeleted ELSE W.IsDeleted END,
				Phone = CASE WHEN W.Phone IS NULL THEN L.Phone ELSE W.Phone END,
				Fax = CASE WHEN W.Fax IS NULL THEN L.Fax ELSE W.Fax END,
				Specialty1 = CASE WHEN W.Specialty1 IS NULL THEN L.Specialty1 ELSE W.Specialty1 END,
				Specialty2 = CASE WHEN W.Specialty2 IS NULL THEN L.Specialty2 ELSE W.Specialty2 END,
				PrimaryParentAccount_ExternalId1 = CASE WHEN W.PrimaryParentAccount_ExternalId1 IS NULL THEN L.PrimaryParentAccount_ExternalId1 ELSE W.PrimaryParentAccount_ExternalId1 END,
				Credentials = CASE WHEN W.Credentials IS NULL THEN L.Credentials ELSE W.Credentials END,
				DoNotCall = CASE WHEN W.DoNotCall IS NULL THEN L.DoNotCall ELSE W.DoNotCall END,
				
				GenText1 = CASE WHEN W.GenText1 IS NULL THEN L.GenText1 ELSE W.GenText1 END,
				GenText2 = CASE WHEN W.GenText2 IS NULL THEN L.GenText2 ELSE W.GenText2 END,
				GenText3 = CASE WHEN W.GenText3 IS NULL THEN L.GenText3 ELSE W.GenText3 END,
				GenText4 = CASE WHEN W.GenText4 IS NULL THEN L.GenText4 ELSE W.GenText4 END,
				GenText5 = CASE WHEN W.GenText5 IS NULL THEN L.GenText5 ELSE W.GenText5 END,
				GenText6 = CASE WHEN W.GenText6 IS NULL THEN L.GenText6 ELSE W.GenText6 END,
				GenText7 = CASE WHEN W.GenText7 IS NULL THEN L.GenText7 ELSE W.GenText7 END,
				GenText8 = CASE WHEN W.GenText8 IS NULL THEN L.GenText8 ELSE W.GenText8 END,
				GenText9 = CASE WHEN W.GenText9 IS NULL THEN L.GenText9 ELSE W.GenText9 END,
				GenText10 = CASE WHEN W.GenText10 IS NULL THEN L.GenText10 ELSE W.GenText10 END,
				GenText11 = CASE WHEN W.GenText11 IS NULL THEN L.GenText11 ELSE W.GenText11 END,
				GenText12 = CASE WHEN W.GenText12 IS NULL THEN L.GenText12 ELSE W.GenText12 END,
				GenText13 = CASE WHEN W.GenText13 IS NULL THEN L.GenText13 ELSE W.GenText13 END,
				GenText14 = CASE WHEN W.GenText14 IS NULL THEN L.GenText14 ELSE W.GenText14 END,
				GenText15 = CASE WHEN W.GenText15 IS NULL THEN L.GenText15 ELSE W.GenText15 END,
				GenText16 = CASE WHEN W.GenText16 IS NULL THEN L.GenText16 ELSE W.GenText16 END,
				GenText17 = CASE WHEN W.GenText17 IS NULL THEN L.GenText17 ELSE W.GenText17 END,
				GenText18 = CASE WHEN W.GenText18 IS NULL THEN L.GenText18 ELSE W.GenText18 END,
				GenText19 = CASE WHEN W.GenText19 IS NULL THEN L.GenText19 ELSE W.GenText19 END,
				GenText20 = CASE WHEN W.GenText20 IS NULL THEN L.GenText20 ELSE W.GenText20 END,
				
				GenBoolean1 = CASE WHEN W.GenBoolean1 IS NULL THEN L.GenBoolean1 ELSE W.GenBoolean1 END,
				GenBoolean2 = CASE WHEN W.GenBoolean2 IS NULL THEN L.GenBoolean2 ELSE W.GenBoolean2 END,
				GenBoolean3 = CASE WHEN W.GenBoolean3 IS NULL THEN L.GenBoolean3 ELSE W.GenBoolean3 END,
				GenBoolean4 = CASE WHEN W.GenBoolean4 IS NULL THEN L.GenBoolean4 ELSE W.GenBoolean4 END,
				GenBoolean5 = CASE WHEN W.GenBoolean5 IS NULL THEN L.GenBoolean5 ELSE W.GenBoolean5 END,
				GenBoolean6 = CASE WHEN W.GenBoolean6 IS NULL THEN L.GenBoolean6 ELSE W.GenBoolean6 END,
				GenBoolean7 = CASE WHEN W.GenBoolean7 IS NULL THEN L.GenBoolean7 ELSE W.GenBoolean7 END,
				GenBoolean8 = CASE WHEN W.GenBoolean8 IS NULL THEN L.GenBoolean8 ELSE W.GenBoolean8 END,
				GenBoolean9 = CASE WHEN W.GenBoolean9 IS NULL THEN L.GenBoolean9 ELSE W.GenBoolean9 END,
				GenBoolean10 = CASE WHEN W.GenBoolean10 IS NULL THEN L.GenBoolean10 ELSE W.GenBoolean10 END,
				GenBoolean11 = CASE WHEN W.GenBoolean11 IS NULL THEN L.GenBoolean11 ELSE W.GenBoolean11 END,
				GenBoolean12 = CASE WHEN W.GenBoolean12 IS NULL THEN L.GenBoolean12 ELSE W.GenBoolean12 END,
				GenBoolean13 = CASE WHEN W.GenBoolean13 IS NULL THEN L.GenBoolean13 ELSE W.GenBoolean13 END,
				GenBoolean14 = CASE WHEN W.GenBoolean14 IS NULL THEN L.GenBoolean14 ELSE W.GenBoolean14 END,
				GenBoolean15 = CASE WHEN W.GenBoolean15 IS NULL THEN L.GenBoolean15 ELSE W.GenBoolean15 END,
				GenBoolean16 = CASE WHEN W.GenBoolean16 IS NULL THEN L.GenBoolean16 ELSE W.GenBoolean16 END,
				GenBoolean17 = CASE WHEN W.GenBoolean17 IS NULL THEN L.GenBoolean17 ELSE W.GenBoolean17 END,
				GenBoolean18 = CASE WHEN W.GenBoolean18 IS NULL THEN L.GenBoolean18 ELSE W.GenBoolean18 END,
				GenBoolean19 = CASE WHEN W.GenBoolean19 IS NULL THEN L.GenBoolean19 ELSE W.GenBoolean19 END,
				GenBoolean20 = CASE WHEN W.GenBoolean20 IS NULL THEN L.GenBoolean20 ELSE W.GenBoolean20 END,
				GenBoolean21 = CASE WHEN W.GenBoolean21 IS NULL THEN L.GenBoolean21 ELSE W.GenBoolean21 END,
				GenBoolean22 = CASE WHEN W.GenBoolean22 IS NULL THEN L.GenBoolean22 ELSE W.GenBoolean22 END,
				
				GenDecimal1 = CASE WHEN W.GenDecimal1 IS NULL THEN L.GenDecimal1 ELSE W.GenDecimal1 END,
				
				GenDateTime1 = CASE WHEN W.GenDateTime1 IS NULL THEN L.GenDateTime1 ELSE W.GenDateTime1 END,
				GenDateTime2 = CASE WHEN W.GenDateTime2 IS NULL THEN L.GenDateTime2 ELSE W.GenDateTime2 END,
				GenDateTime3 = CASE WHEN W.GenDateTime3 IS NULL THEN L.GenDateTime3 ELSE W.GenDateTime3 END,
				GenDateTime4 = CASE WHEN W.GenDateTime4 IS NULL THEN L.GenDateTime4 ELSE W.GenDateTime4 END,
				
				ExternalUpdatedUtcDate = GETUTCDATE()
			FROM CMS_Account W
			INNER JOIN CMS_AccountMerge M ON W.CmsId = @winnerCmsId AND M.AccountMergeId = @accountMergeId
			INNER JOIN CMS_Account L ON L.CmsId = @looserCmsId;
		END
		ELSE
		BEGIN
			-- Update Winner with data from Looser.
			UPDATE W SET
				XPOPrescriberNo = CASE WHEN W.XPOPrescriberNo IS NULL THEN L.XPOPrescriberNo ELSE W.XPOPrescriberNo END,
				DDDOutletZipId = CASE WHEN W.DDDOutletZipId IS NULL THEN L.DDDOutletZipId ELSE W.DDDOutletZipId END,
				
				ExternalUpdatedUtcDate = GETUTCDATE()
			FROM CMS_Account W
			INNER JOIN CMS_AccountMerge M ON W.CmsId = @winnerCmsId AND M.AccountMergeId = @accountMergeId
			INNER JOIN CMS_Account L ON L.CmsId = @looserCmsId;
		END

	END

	-- Accept the Merge
	UPDATE CMS_AccountMerge SET 
		Status = 'ACPT', 
		Winner = @winnerCmsId, 
		PopulateNullFields = @populateNullFields, 
		PrimaryAddressMergeId = @primaryAddressMergeId,
		UpdatedUtcDate = GETUTCDATE() 
	WHERE AccountMergeId = @accountMergeId;

	-- Accept all the selected addresses
	UPDATE CMS_AddressMerge SET Status = 'ACPT', UpdatedUtcDate = GETUTCDATE()
	WHERE AccountMergeId = @accountMergeId 
	AND AddressMergeId IN (select CAST(splitdata AS INT) from dbo.fn_splitString(@selectedAddressMergeIds, ','));

	-- Reject all the unselected addresses
	UPDATE CMS_AddressMerge SET Status = 'REJT', UpdatedUtcDate = GETUTCDATE()
	WHERE AccountMergeId = @accountMergeId 
	AND AddressMergeId NOT IN (select CAST(splitdata AS INT) from dbo.fn_splitString(@selectedAddressMergeIds, ','));
	

	-- Make the rejected addresses as InActive
	-- We are not End dating DDD addresses since multiple Veeva accounts can be matched to a single DDD account and the DDD addresses can
	-- become InActive when the first match is Accepted and all subsequent matches on the same DDD account will not have any active address.
	UPDATE CMS_AccountAddress SET 
		ExternalUpdatedUtcDate = GETUTCDATE(), 
		InActive = 1, 
		PrimaryAddressIndicator = 0
	WHERE Source <> 'DDD' AND CmsAddressId IN (SELECT CmsAddressId FROM CMS_AddressMerge WHERE Status = 'REJT' AND AccountMergeId = @accountMergeId);

	-- Move all the accepted address from Looser to Winner.
	/*UPDATE CMS_AccountAddress SET 
		CmsId = @winnerCmsId, 
		ExternalUpdatedUtcDate = GETUTCDATE(), 
		PrimaryAddressIndicator = 0
	WHERE CmsAddressId IN (SELECT CmsAddressId FROM CMS_AddressMerge WHERE Status = 'ACPT' AND AccountMergeId = @accountMergeId);*/
	--New record is inserted instead of above update so that multiple Veeva accounts can be merged with same DDD account in Version 1.1
	UPDATE  CAA SET 
		ExternalUpdatedUtcDate = GETUTCDATE(), 
		PrimaryAddressIndicator = 0
	FROM CMS_AccountAddress CAA
	INNER JOIN CMS_AddressMerge CAM
	ON CAA.CmsId = CAM.CMsId AND  CAA.CmsId = @winnerCmsId AND CAM.[Status] = 'ACPT' 
	AND CAM.AddressMergeId <> @primaryAddressMergeId;
	
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
		GenDecimal4, GenDecimal5, GenDateTime1, GenDateTime2, GenDateTime3, GenDateTime4, GenDateTime5,
		ExternalUpdatedUtcDate, IsAddressStandardized, IsSmartyStreetAPICalled
	)
	SELECT
		@winnerCmsId, AA.McKessonId, AA.OdsAddressId, AA.VeevaAddressId, AA.Source, AA.AddressType, 
		CASE WHEN AA.CmsAddressId IN (SELECT CmsAddressId FROM CMS_AddressMerge  WHERE [Status] = 'ACPT' AND AddressMergeId = @primaryAddressMergeId)
			THEN 1 ELSE 0 END AS PrimaryAddressIndicator,
		AA.AddressDescription, AA.ExternalId2, AA.InActive, AA.ComputedStatus, AA.AddressLine1, AA.AddressLine2, AA.City, 
		AA.State, AA.Province, AA.Country, AA.ZipCode, AA.ZipCodeExtension, AA.Latitude, AA.Longitude, AA.MailingAddressIndicator, 
		AA.BillingAddressIndicator, AA.	ShippingAddressIndicator, AA.SamplingAddressIndicator, AA.HomeAddressIndicator, 
		AA.BusinessAddressIndicator, AA.Comments, AA.StateLicenseNumber, AA.StateLicenseStatus, 
		AA.StateLicenseExpirationDate, AA.StateLicenseState, AA.IsDeleted, AA.IsLocked, AA.MayEdit, 	
		AA.CreatedUtcDate, AA.Phone, AA.Fax,
		AA.GenText1, AA.GenText2, AA.GenText3, AA.GenText4, AA.GenText5, 
		AA.GenText6, AA.GenText7, AA.GenText8, AA.GenText9, AA.GenText10, 
		AA.GenText11, AA.GenText12, AA.GenText13, AA.GenText14, AA.GenText15, 
		AA.GenInteger1, AA.GenInteger2, AA.GenInteger3, AA.GenInteger4, AA.GenInteger5, 
		AA.GenBoolean1, AA.GenBoolean2, AA.GenBoolean3, AA.GenBoolean4, AA.GenBoolean5,
		AA.GenDecimal1, AA.GenDecimal2, AA.GenDecimal3, AA.GenDecimal4, AA.GenDecimal5, 
		AA.GenDateTime1, AA.GenDateTime2, AA.GenDateTime3, AA.GenDateTime4, AA.GenDateTime5, GETUTCDATE(),
		AA.IsAddressStandardized, AA.IsSmartyStreetAPICalled
	FROM CMS_AccountAddress AA
	WHERE AA.CmsAddressId IN (SELECT CmsAddressId FROM CMS_AddressMerge WHERE Status = 'ACPT' AND AccountMergeId = @accountMergeId)
	AND CmsId = @LooserCmsId;
		
	-- Set the primary address.
	UPDATE CMS_AccountAddress SET 
		ExternalUpdatedUtcDate = GETUTCDATE(), 
		PrimaryAddressIndicator = 1
	WHERE CmsAddressId IN (SELECT CmsAddressId FROM CMS_AddressMerge WHERE AddressMergeId = @primaryAddressMergeId);

END

IF @status = 'REJT'
BEGIN

	UPDATE CMS_AccountMerge SET Status = 'REJT', RejectComments = @rejectComments, UpdatedUtcDate = GETUTCDATE() 
	WHERE AccountMergeId = @accountMergeId;
	
	UPDATE CMS_AddressMerge SET Status = 'REJT', UpdatedUtcDate = GETUTCDATE() WHERE AccountMergeId = @accountMergeId;
END

COMMIT TRAN

SELECT 1 AS SuccessFlag, NULL AS ErrorMessage; -- SuccessFlag, ErrorMessage

END TRY
BEGIN CATCH

ROLLBACK TRAN

DECLARE @ErrorMessage AS VARCHAR(500)
SET @ErrorMessage = ERROR_MESSAGE();
SELECT 0 AS SuccessFlag, @ErrorMessage AS ErrorMessage;  -- SuccessFlag, ErrorMessage

END CATCH

END
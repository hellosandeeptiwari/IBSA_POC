
CREATE   PROCEDURE [dbo].[sp_accountaddress_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_accountaddress_transform', 'Started', GETUTCDATE());


	UPDATE P SET 
		P.UpdatedDate = GETDATE(),
		P.ExternalId1 = S.Id,
		P.IsDeleted = S.IsDeleted,
		P.Name = S.Name,
		P.RecordTypeId = S.RecordTypeId,
		P.VeevaCreatedDate = S.CreatedDate,
		P.VeevaCreatedById = S.CreatedById,
		P.LastModifiedDate = S.LastModifiedDate,
		P.LastModifiedById = S.LastModifiedById,
		P.SystemModstamp = S.SystemModstamp,
		P.MayEdit = S.MayEdit,
		P.IsLocked = S.IsLocked,
		P.Account = S.Account_vod__c,
		P.Addressline2 = S.Address_line_2_vod__c,
		P.City = S.City_vod__c,
		P.ExternalID = S.External_ID_vod__c,
		P.DEA = S.DEA_vod__c,
		P.DEAExpirationDate = S.DEA_Expiration_Date_vod__c,
		P.DEALicenseAddress = S.DEA_License_Address_vod__c,
		P.Phone = S.Phone_vod__c,
		P.Fax = S.Fax_vod__c,
		P.Map = S.Map_vod__c,
		P.Shipping = S.Shipping_vod__c,
		P.[IsPrimary] = S.Primary_vod__c,
		P.License = S.License_vod__c,
		P.LicenseExpirationDate = S.License_Expiration_Date_vod__c,
		P.LicenseStatus = S.License_Status_vod__c,
		P.Zip4 = S.Zip_4_vod__c,
		P.Phone2 = S.Phone_2_vod__c,
		P.Fax2 = S.Fax_2_vod__c,
		P.LicenseValidToSample = S.License_Valid_To_Sample_vod__c,
		P.SampleStatus = S.Sample_Status_vod__c,
		P.IncludeinTerritoryAssignment = S.Include_in_Territory_Assignment_vod__c,
		P.MobileID = S.Mobile_ID_vod__c,
		P.Inactive = S.Inactive_vod__c,
		P.Lock = S.Lock_vod__c,
		P.Country = S.Country_vod__c,
		P.Zip = S.Zip_vod__c,
		P.Source = S.Source_vod__c,
		P.Brick = S.Brick_vod__c,
		P.ASSMCA = S.ASSMCA_vod__c,
		P.DEAAddress = S.DEA_Address_vod__c,
		P.DEASchedule = S.DEA_Schedule_vod__c,
		P.Business = S.Business_vod__c,
		P.Billing = S.Billing_vod__c,
		P.Home = S.Home_vod__c,
		P.Mailing = S.Mailing_vod__c,
		P.State = S.State_vod__c,
		P.DEAStatus = S.DEA_Status_vod__c,
		P.EntityReferenceId = S.Entity_Reference_Id_vod__c,
		P.ControllingAddress = S.Controlling_Address_vod__c,
		P.ControlledAddress = S.Controlled_Address_vod__c,
		P.NoAddressCopy = S.No_Address_Copy_vod__c,
		P.SampleSendStatus = S.Sample_Send_Status_vod__c,
		P.CRMIDc = S.CRM_ID__c
	FROM [dbo].[AccountAddress] P
	INNER JOIN [dbo].[Staging_AccountAddress] S ON S.[Id] = P.[ExternalId1] 
		AND S.SystemModstamp <> P.SystemModstamp AND P.EndDate IS NULL;
		
		

	INSERT INTO [dbo].[AccountAddress]
		([AccountAddressId], CreatedDate, 
		ExternalId1, IsDeleted, Name, RecordTypeId, VeevaCreatedDate, VeevaCreatedById, 
		LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, 
		Addressline2, City, ExternalID, DEA, DEAExpirationDate, DEALicenseAddress, Phone, 
		Fax, Map, Shipping, [IsPrimary], License, LicenseExpirationDate, LicenseStatus, 
		Zip4, Phone2, Fax2, LicenseValidToSample, SampleStatus, IncludeinTerritoryAssignment, 
		MobileID, Inactive, Lock, Country, Zip, Source, Brick, ASSMCA, DEAAddress, 
		DEASchedule, Business, Billing, Home, Mailing, State, DEAStatus, EntityReferenceId, 
		ControllingAddress, ControlledAddress, NoAddressCopy, SampleSendStatus, CRMIDc)
	SELECT
		NEWID() AS [AccountAddressId], GETDATE(),
		Id, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, 
		LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account_vod__c, 
		Address_line_2_vod__c, City_vod__c, External_ID_vod__c, DEA_vod__c, DEA_Expiration_Date_vod__c, DEA_License_Address_vod__c, Phone_vod__c, 
		Fax_vod__c, Map_vod__c, Shipping_vod__c, Primary_vod__c, License_vod__c, License_Expiration_Date_vod__c, License_Status_vod__c, 
		Zip_4_vod__c, Phone_2_vod__c, Fax_2_vod__c, License_Valid_To_Sample_vod__c, Sample_Status_vod__c, Include_in_Territory_Assignment_vod__c, 
		Mobile_ID_vod__c, Inactive_vod__c, Lock_vod__c, Country_vod__c, Zip_vod__c, Source_vod__c, Brick_vod__c, ASSMCA_vod__c, DEA_Address_vod__c,
		DEA_Schedule_vod__c, Business_vod__c, Billing_vod__c, Home_vod__c, Mailing_vod__c, State_vod__c, DEA_Status_vod__c, Entity_Reference_Id_vod__c, 
		Controlling_Address_vod__c, Controlled_Address_vod__c, No_Address_Copy_vod__c, Sample_Send_Status_vod__c, CRM_ID__c
	FROM [Staging_AccountAddress] AS S
	WHERE NOT EXISTS (SELECT 1 FROM [AccountAddress] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);
	
	
	ALTER TABLE AccountAddress DISABLE TRIGGER trg_AccountAddress;

	WITH cte_AccountAddress AS
	(
		SELECT ROW_NUMBER() OVER(PARTITION BY AccountAddressId ORDER BY Id DESC) AS RowNum, Id, StartDate, EndDate, AccountAddressId, VeevaCreatedDate
		FROM AccountAddress 
		--WHERE AccountId IN ( '42BF733B-C90D-47AF-AF0E-007241FDB70D', '534BD97C-B3A4-4B89-AB67-00D5D0C4D43F', 'FD0ABCDF-ABC9-4DED-975E-011F5AFE6CAD')
	)
	UPDATE A SET A.StartDate = ISNULL(A2.EndDate, CAST(REPLACE(A1.VeevaCreatedDate, '.0000000', '') AS DATETIME))--SELECT A.Id, A.EndDate, A.VeevaCreatedDate, A1.AccountAddressId, ISNULL(A2.EndDate, A1.VeevaCreatedDate) AS StartDate, A1.EndDate
	FROM AccountAddress A
	INNER JOIN cte_AccountAddress A1 ON A1.Id = A.Id
	LEFT OUTER JOIN cte_AccountAddress A2 ON A1.AccountAddressId = A2.AccountAddressId AND A1.RowNum + 1 = A2.RowNum;

	ALTER TABLE AccountAddress ENABLE TRIGGER trg_AccountAddress;


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_accountaddress_transform', 'Completed', GETUTCDATE());

END


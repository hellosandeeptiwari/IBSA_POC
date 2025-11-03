
CREATE   PROCEDURE [dbo].[sp_call_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_call_transform', 'Started', GETUTCDATE());

	-- When a merge happens either in CMS or Veeva, Call records will be updated moving all the calls from the loser to the winner.
	-- Below update to do the same change in ODS.
	UPDATE P SET
		P.UpdatedDate = GETDATE(),
		P.Account = S.Account_vod__c, 
		P.LastModifiedById = S.LastModifiedById,
		P.LastModifiedDate = S.LastModifiedDate, 
		P.SystemModstamp = S.SystemModstamp
	FROM [dbo].Call P
	INNER JOIN [dbo].[Staging_Call] S ON S.[Id] = P.[ExternalId1] 
		AND S.SystemModstamp <> P.SystemModstamp AND P.EndDate IS NULL;
		
		

	INSERT INTO [dbo].[Call]
		([CallId], CreatedDate, 
		ExternalId1, OwnerId, IsDeleted, Name, RecordTypeId, VeevaCreatedDate, VeevaCreatedById, 
		LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, MayEdit, IsLocked, 
		LastViewedDate, LastReferencedDate, CallComments, SampleCard, AddDetail, Property, 
		Account, Status, ParentAddress, AccountPlan, NextCallNotes, PreCallNotes, MobileID, 
		ActivityTypec, SignificantEventc, Location, Subject, Unlock, CallDatetime, DisbursedTo, 
		Disclaimer, RequestReceipt, SignatureDate, Territory, SubmittedByMobile, CallType, 
		AddKeyMessage, Address, Attendees, AttendeeType, CallDate, DetailedProducts, 
		NoDisbursement, ParentCall, [User], Contact, MedicalEvent, MobileVeevaCreatedDatetime, 
		MobileLastModifiedDatetime, License, IsParentCall, EntityDisplayName, OverrideLock, 
		LastDevice, ShipAddressLine1, ShipAddressLine2, ShipCity, ShipCountry, 
		ShipLicenseExpirationDate, ShipLicenseStatus, ShipLicense, ShipState, ShipToAddress, 
		ShipZip, ShipToAddressText, CLM, zvodCLMDetails, IsSampledCall, Presentations, 
		EntityReferenceId, ErrorReferenceCall, Duration, Color, AllowedProducts, zvodAttachments, 
		SampleCardReason, ASSMCA, AddressLine1, AddressLine2, City, DEAAddressLine1, 
		DEAAddressLine2, DEAAddress, DEACity, DEAExpirationDate, DEAState, DEAZip4, DEAZip, DEA, 
		ShipZip4, State, Zip4, Zip, SampleSendCard, Credentials, Salutation, ProductPriority1, 
		ProductPriority2, ProductPriority3, ProductPriority4, ProductPriority5, ExpenseAmount, 
		TotalExpenseAttendeesCount, Attendeelist, ExpensePostStatus, AttendeePostStatus, 
		ExpenseSystemExternalID, IncurredExpense, LocationServicesStatus, ParentCallMobileID, 
		RemoteMeeting, VeevaRemoteMeetingId, CNXChannelc, CNXDurationc)
	SELECT
		NEWID() AS [CallId], GETDATE(),
		Id, OwnerId, IsDeleted, Name, RecordTypeId, CreatedDate, CreatedById, 
		LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, MayEdit, IsLocked, 
		LastViewedDate, LastReferencedDate, Call_Comments_vod__c, Sample_Card_vod__c, Add_Detail_vod__c, Property_vod__c, 
		Account_vod__c, Status_vod__c, Parent_Address_vod__c, Account_Plan_vod__c, Next_Call_Notes_vod__c, Pre_Call_Notes_vod__c, Mobile_ID_vod__c, 
		Activity_Type__c, Significant_Event__c, Location_vod__c, Subject_vod__c, Unlock_vod__c, Call_Datetime_vod__c, Disbursed_To_vod__c, 
		Disclaimer_vod__c, Request_Receipt_vod__c, Signature_Date_vod__c, Territory_vod__c, Submitted_By_Mobile_vod__c, Call_Type_vod__c, 
		Add_Key_Message_vod__c, Address_vod__c, Attendees_vod__c, Attendee_Type_vod__c, Call_Date_vod__c, Detailed_Products_vod__c, 
		No_Disbursement_vod__c, Parent_Call_vod__c, User_vod__c, Contact_vod__c, Medical_Event_vod__c, Mobile_Created_Datetime_vod__c, 
		Mobile_Last_Modified_Datetime_vod__c, License_vod__c, Is_Parent_Call_vod__c, Entity_Display_Name_vod__c, Override_Lock_vod__c, 
		Last_Device_vod__c, Ship_Address_Line_1_vod__c, Ship_Address_Line_2_vod__c, Ship_City_vod__c, Ship_Country_vod__c, 
		Ship_License_Expiration_Date_vod__c, Ship_License_Status_vod__c, Ship_License_vod__c, Ship_State_vod__c, Ship_To_Address_vod__c, 
		Ship_Zip_vod__c, Ship_To_Address_Text_vod__c, CLM_vod__c, zvod_CLMDetails_vod__c, Is_Sampled_Call_vod__c, Presentations_vod__c, 
		Entity_Reference_Id_vod__c, Error_Reference_Call_vod__c, Duration_vod__c, Color_vod__c, Allowed_Products_vod__c, zvod_Attachments_vod__c, 
		Sample_Card_Reason_vod__c, ASSMCA_vod__c, Address_Line_1_vod__c, Address_Line_2_vod__c, City_vod__c, DEA_Address_Line_1_vod__c, 
		DEA_Address_Line_2_vod__c, DEA_Address_vod__c, DEA_City_vod__c, DEA_Expiration_Date_vod__c, DEA_State_vod__c, DEA_Zip_4_vod__c, DEA_Zip_vod__c, DEA_vod__c, 
		Ship_Zip_4_vod__c, State_vod__c, Zip_4_vod__c, Zip_vod__c, Sample_Send_Card_vod__c, Credentials_vod__c, Salutation_vod__c, Product_Priority_1_vod__c, 
		Product_Priority_2_vod__c, Product_Priority_3_vod__c, Product_Priority_4_vod__c, Product_Priority_5_vod__c, Expense_Amount_vod__c, 
		Total_Expense_Attendees_Count_vod__c, Attendee_list_vod__c, Expense_Post_Status_vod__c, Attendee_Post_Status_vod__c, 
		Expense_System_External_ID_vod__c, Incurred_Expense_vod__c, Location_Services_Status_vod__c, Parent_Call_Mobile_ID_vod__c, 
		Remote_Meeting_vod__c, Veeva_Remote_Meeting_Id_vod__c, CNX_Channel__c, CNX_Duration__c
	FROM [Staging_Call] AS S
	WHERE NOT EXISTS (SELECT 1 FROM [Call] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL)
	AND S.Status_vod__c IN ('Submitted_vod', 'Submitted_vod__c');


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_call_transform', 'Completed', GETUTCDATE());

END


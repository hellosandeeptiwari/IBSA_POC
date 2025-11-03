



CREATE   PROCEDURE [dbo].[sp_callsample_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_callsample_transform', 'Started', GETUTCDATE());


	INSERT INTO [dbo].[CallSample]
		([CallSampleId], CreatedDate, 
		ExternalId1, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, 
		LastModifiedById, SystemModstamp, LastActivityDate, MayEdit, IsLocked, 
		LastViewedDate, LastReferencedDate, Account, CallDate, IsParentCall, Quantity, 
		Lot, MobileID, Call2, Product, OverrideLock, Distributor, AttendeeType, 
		EntityReferenceId, DeliveryStatus, ApplyLimit, LimitApplied, Manufacturer, 
		Call2MobileID)
	SELECT
		NEWID() AS [CallSampleId], GETDATE(),
		S.Id, S.IsDeleted, S.Name, S.CreatedDate, S.CreatedById, S.LastModifiedDate, 
		S.LastModifiedById, S.SystemModstamp, S.LastActivityDate, S.MayEdit, S.IsLocked, 
		S.LastViewedDate, S.LastReferencedDate, S.Account_vod__c, S.Call_Date_vod__c, S.Is_Parent_Call_vod__c, S.Quantity_vod__c, 
		S.Lot_vod__c, S.Mobile_ID_vod__c, S.Call2_vod__c, S.Product_vod__c, S.Override_Lock_vod__c, S.Distributor_vod__c, S.Attendee_Type_vod__c, 
		S.Entity_Reference_Id_vod__c, S.Delivery_Status_vod__c, S.Apply_Limit_vod__c, S.Limit_Applied_vod__c, S.Manufacturer_vod__c, 
		S.Call2_Mobile_ID_vod__c
	FROM [Staging_CallSample] AS S
	INNER JOIN [dbo].[Call] C ON C.[ExternalId1] = S.[Call2_vod__c] AND C.EndDate IS NULL
	WHERE NOT EXISTS (SELECT 1 FROM [CallSample] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_callsample_transform', 'Completed', GETUTCDATE());

END


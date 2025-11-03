



CREATE   PROCEDURE [dbo].[sp_calldetail_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_calldetail_transform', 'Started', GETUTCDATE());


	INSERT INTO [dbo].[CallDetail]
		([CallDetailId], CreatedDate, 
		ExternalId1, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, 
		LastModifiedById, SystemModstamp, MayEdit, IsLocked, IsParentCall, Call2, Product, 
		DetailPriority, MobileID, OverrideLock, Type, DetailGroup)
	SELECT
		NEWID() AS [CallDetailId], GETDATE(),
		S.Id, S.IsDeleted, S.Name, S.CreatedDate, S.CreatedById, S.LastModifiedDate, 
		S.LastModifiedById, S.SystemModstamp, S.MayEdit, S.IsLocked, Is_Parent_Call_vod__c, Call2_vod__c, Product_vod__c, 
		Detail_Priority_vod__c, Mobile_ID_vod__c, Override_Lock_vod__c, Type_vod__c, Detail_Group_vod__c
	FROM [Staging_CallDetail] AS S
	INNER JOIN [dbo].[Call] C ON C.[ExternalId1] = S.[Call2_vod__c] AND C.EndDate IS NULL
	WHERE NOT EXISTS (SELECT 1 FROM [CallDetail] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_calldetail_transform', 'Completed', GETUTCDATE());

END


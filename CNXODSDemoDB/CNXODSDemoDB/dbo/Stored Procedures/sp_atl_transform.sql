
CREATE   PROCEDURE [dbo].[sp_atl_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_atl_transform', 'Started', GETUTCDATE());


	-- Split the TerritoryName's since the same Account can be aligned to multiple territories and 
	-- extract the respective TerritoryId's for each territory.
	SELECT S.ExternalId1, T.ExternalId1 AS Territory
	INTO #ATL
	FROM 
	(
		SELECT temp.Id AS ExternalId1, Data
		FROM Staging_ATL temp
		CROSS APPLY [dbo].[Split](Territory_vod__c, ';') SplitTerr
	) AS S
	INNER JOIN [Territory] T ON S.Data = T.Name AND T.EndDate IS NULL;
	
	UPDATE P SET 
		P.UpdatedDate = GETDATE(),
		P.ExternalId1 = S.Id,
		P.OwnerId = S.OwnerId,
		P.IsDeleted = S.IsDeleted,
		P.Name = S.Name,
		P.VeevaCreatedDate = S.CreatedDate,
		P.VeevaCreatedById = S.CreatedById,
		P.LastModifiedDate = S.LastModifiedDate,
		P.LastModifiedById = S.LastModifiedById,
		P.SystemModstamp = S.SystemModstamp,
		P.MayEdit = S.MayEdit,
		P.IsLocked = S.IsLocked,
		P.Account = S.Account_vod__c,
		P.ExternalID = S.External_ID_vod__c,
		P.Territory = S.Territory_vod__c,
		P.MobileID = S.Mobile_ID_vod__c,
		P.TerritoryToAdd = S.Territory_To_Add_vod__c,
		P.TerritorytoDrop = S.Territory_to_Drop_vod__c
	FROM [dbo].[ATL] P
	INNER JOIN #ATL T ON T.ExternalId1 = P.ExternalId1 AND T.Territory = P.Territory
	INNER JOIN [dbo].[Staging_ATL] S ON S.[Id] = P.[ExternalId1] 
		AND S.SystemModstamp <> P.SystemModstamp AND P.EndDate IS NULL
	INNER JOIN [Account] A ON S.Account_vod__c = A.ExternalId1 AND A.EndDate IS NULL;
		
		
	-- If the account is aligned to any territories in ODS but that account-territory alignment does not exist in Veeva,
	-- then delete those territory alignments.
	DELETE P FROM [ATL] P
	WHERE NOT EXISTS (SELECT 1 FROM #ATL T WHERE T.ExternalId1 = P.ExternalId1 AND P.Territory = T.Territory)
	AND EXISTS (SELECT 1 FROM #ATL T WHERE T.ExternalId1 = P.ExternalId1);
		
		

	INSERT INTO [dbo].[ATL]
		([ATLId], CreatedDate, 
		ExternalId1, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, 
		SystemModstamp, MayEdit, IsLocked, Account, ExternalID, Territory, MobileID, TerritoryToAdd, TerritorytoDrop)
	SELECT
		NEWID() AS [ATLId], GETDATE(),
		S.Id, S.OwnerId, S.IsDeleted, S.Name, S.CreatedDate, S.CreatedById, S.LastModifiedDate, S.LastModifiedById, 
		S.SystemModstamp, S.MayEdit, S.IsLocked, S.Account_vod__c, S.External_ID_vod__c, T.Territory, S.Mobile_ID_vod__c, 
		S.Territory_To_Add_vod__c, S.Territory_to_Drop_vod__c
	FROM [Staging_ATL] AS S
	INNER JOIN #ATL T On S.Id = T.[ExternalId1]
	INNER JOIN [Account] A ON S.Account_vod__c = A.ExternalId1 AND A.EndDate IS NULL
	WHERE NOT EXISTS (SELECT 1 FROM [ATL] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_atl_transform', 'Completed', GETUTCDATE());

END


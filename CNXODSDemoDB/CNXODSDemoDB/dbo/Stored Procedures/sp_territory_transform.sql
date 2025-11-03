

CREATE   PROCEDURE [dbo].[sp_territory_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_territory_transform', 'Started', GETUTCDATE());


	UPDATE P SET 
		P.UpdatedDate = GETDATE(),
		P.ExternalId1 = S.Id,
		P.Name = S.Name,
		P.ParentTerritoryId = S.ParentTerritoryId,
		P.Description = S.Description,
		P.LastModifiedDate = S.LastModifiedDate,
		P.LastModifiedById = S.LastModifiedById,
		P.SystemModstamp = S.SystemModstamp,
		P.MasterAlignId = S.Master_Align_Id_vod__c
	FROM [dbo].[Territory] P
	INNER JOIN [dbo].[Staging_Territory] S ON S.[Id] = P.[ExternalId1] 
		AND S.SystemModstamp <> P.SystemModstamp AND P.EndDate IS NULL;
		
		

	INSERT INTO [dbo].[Territory]
		([TerritoryId], CreatedDate, ExternalId1, Name, ParentTerritoryId, Description, 
		LastModifiedDate, LastModifiedById, SystemModstamp, MasterAlignId)
	SELECT
		NEWID() AS [TerritoryId], GETDATE(),
		Id, Name, ParentTerritoryId, Description, 
		LastModifiedDate, LastModifiedById, SystemModstamp, Master_Align_Id_vod__c
	FROM [Staging_Territory] AS S
	WHERE NOT EXISTS (SELECT 1 FROM [Territory] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_territory_transform', 'Completed', GETUTCDATE());

END


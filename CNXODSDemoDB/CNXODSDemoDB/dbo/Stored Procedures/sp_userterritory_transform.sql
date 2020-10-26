

CREATE   PROCEDURE [dbo].[sp_userterritory_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_userterritory_transform', 'Started', GETUTCDATE());


	UPDATE P SET 
		P.UpdatedDate = GETDATE(),
		P.ExternalId1 = S.Id,
		P.UserId = S.UserId,
		P.TerritoryId = S.TerritoryId,
		P.IsActive = S.IsActive,
		P.LastModifiedDate = S.LastModifiedDate,
		P.LastModifiedById = S.LastModifiedById,
		P.SystemModstamp = S.SystemModstamp
	FROM [dbo].[UserTerritory] P
	INNER JOIN [dbo].[Staging_UserTerritory] S ON S.[Id] = P.[ExternalId1] 
		AND S.SystemModstamp <> P.SystemModstamp AND P.EndDate IS NULL;
		
		

	INSERT INTO [dbo].[UserTerritory]
		([UserTerritoryId], CreatedDate, ExternalId1, UserId, TerritoryId, IsActive, 
		LastModifiedDate, LastModifiedById, SystemModstamp)
	SELECT
		NEWID() AS [UserTerritoryId], GETDATE(),
		Id, UserId, TerritoryId, IsActive, LastModifiedDate, LastModifiedById, SystemModstamp
	FROM [Staging_UserTerritory] AS S
	WHERE NOT EXISTS (SELECT 1 FROM [UserTerritory] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_userterritory_transform', 'Completed', GETUTCDATE());

END


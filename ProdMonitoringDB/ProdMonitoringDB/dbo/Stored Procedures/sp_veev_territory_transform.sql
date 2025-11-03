CREATE OR ALTER PROCEDURE [dbo].[sp_veev_territory_transform]
AS
BEGIN

	UPDATE T
	SET	T.[DeveloperName] = ST.[DeveloperName],
		T.[LastModifiedById] = ST.[LastModifiedById],
		T.[LastModifiedDate] = ST.[LastModifiedDate],
		T.[TerritoryName] = ST.[Name],
		T.[ParentTerritoryId] = ST.[ParentTerritoryId],
		T.[SystemModstamp] = ST.[SystemModstamp]
		FROM VEEV_Territory T
		INNER JOIN Staging_VEEV_Territory ST ON T.ExternalId1 = ST.Id AND T.EndDate IS NULL
		INNER JOIN ConexusCustomer CC ON CC.CustomerId = T.CustomerId

INSERT INTO [dbo].[VEEV_Territory]
           ([TerritoryId]
           ,[Description]
           ,[DeveloperName]
           ,[ExternalId1]
           ,[LastModifiedById]
           ,[LastModifiedDate]
           ,[TerritoryName]
           ,[ParentTerritoryId]
           ,[SystemModstamp]
           ,[CustomerId])
     
SELECT NEWID() AS TerritoryId,SVT.[Description],SVT.DeveloperName,SVT.Id,SVT.LastModifiedById,SVT.LastModifiedDate,SVT.[Name], SVT.ParentTerritoryId,
		  SVT.SystemModstamp,CC.CustomerId  FROM Staging_VEEV_Territory SVT 
		  INNER JOIN ConexusCustomer CC ON SVT.CustomerId = CC.CustomerId
		  WHERE NOT EXISTS(SELECT 1 FROM VEEV_Territory VT WHERE SVT.Id = VT.ExternalId1 AND SVT.CustomerId = VT.CustomerId AND VT.EndDate IS NULL);
END


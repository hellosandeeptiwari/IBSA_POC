CREATE OR ALTER PROC [dbo].[sp_veev_userterritory_transform]
AS
BEGIN
	UPDATE UT
	SET UT.[IsActive] = CASE WHEN SUT.IsActive='True' THEN 'ACTV' ELSE 'False' END,
		UT.[LastModifiedById] = SUT.[LastModifiedById],
		UT.[LastModifiedDate] = SUT.[LastModifiedDate],
		UT.[SystemModstamp] = SUT.[SystemModstamp],
		UT.[TerritoryId] = SUT.[TerritoryId],
		UT.[UserId] = SUT.[UserId]
		FROM VEEV_UserTerritory UT
		INNER JOIN Staging_VEEV_UserTerritory SUT ON SUT.Id = UT.ExternalId1 AND UT.EndDate IS NULL

INSERT INTO [dbo].[VEEV_UserTerritory]
           ([UserTerritoryId]
           ,[ExternalId1]
           ,[IsActive]
           ,[LastModifiedById]
           ,[LastModifiedDate]
           ,[SystemModstamp]
           ,[TerritoryId]
           ,[UserId]
           ,[CustomerId])

SELECT  NEWID() AS [UserTerritoryId]
	  ,SVUT.[Id]
      ,CASE WHEN SVUT.IsActive='True' THEN 'ACTV' ELSE 'False' END
      ,SVUT.[LastModifiedById]
      ,SVUT.[LastModifiedDate]
      ,SVUT.[SystemModstamp]
      ,VT.[ExternalId1]
      ,VU.[ExternalId1]
      ,CC.[CustomerId]
  FROM [dbo].[Staging_VEEV_UserTerritory] SVUT
  INNER JOIN ConexusCustomer CC ON SVUT.CustomerId = CC.CustomerId
  INNER JOIN VEEV_User VU ON VU.ExternalId1 = SVUT.UserId
  INNER JOIN VEEV_Territory VT ON VT.ExternalId1 = SVUT.TerritoryId
  WHERE NOT EXISTS(SELECT 1 FROM VEEV_UserTerritory VUT WHERE SVUT.Id = VUT.ExternalId1 AND SVUT.CustomerId = VUT.CustomerId AND VUT.EndDate IS NULL)
END
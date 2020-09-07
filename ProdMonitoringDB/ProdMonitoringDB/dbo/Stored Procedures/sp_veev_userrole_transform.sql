CREATE PROCEDURE [dbo].[sp_veev_userrole_transform]
AS
BEGIN
	UPDATE UR
	SET	UR.[DeveloperName] = SUR.[DeveloperName],
		UR.[ForecastUserId] = SUR.[ForecastUserId],
		UR.[LastModifiedById] = SUR.[LastModifiedById],
		UR.[LastModifiedDate] = SUR.[LastModifiedDate],
		UR.[UserRoleName] = SUR.[Name],
		UR.[ParentRoleId] = SUR.[ParentRoleId],
		UR.[RollupDescription] = SUR.[RollupDescription],
		UR.[SystemModstamp] = SUR.[SystemModstamp]
		FROM VEEV_UserRole UR
		INNER JOIN Staging_VEEV_UserRole SUR ON UR.ExternalId1 = SUR.Id --AND UR.SystemModstamp <> SUR.SystemModstamp AND UR.EndDate IS NULL
		INNER JOIN ConexusCustomer CC ON CC.CustomerId = UR.CustomerId


INSERT INTO [dbo].[VEEV_UserRole]
           ([UserRoleId]
           ,[DeveloperName]
           ,[ForecastUserId]
           ,[ExternalId1]
           ,[LastModifiedById]
           ,[LastModifiedDate]
           ,[UserRoleName]
           ,[ParentRoleId]
           ,[RollupDescription]
           ,[SystemModstamp]
           ,[CustomerId])

SELECT NEWID() AS UserRoleId
      ,SVUR.[DeveloperName]
      ,SVUR.[ForecastUserId]
      ,SVUR.[Id]
      ,SVUR.[LastModifiedById]
      ,SVUR.[LastModifiedDate]
      ,SVUR.[Name]
      ,SVUR.[ParentRoleId]
      ,SVUR.[RollupDescription]
      ,SVUR.[SystemModstamp]
      ,CC.[CustomerId]
  FROM [dbo].[Staging_VEEV_UserRole] SVUR
  INNER JOIN ConexusCustomer CC ON SVUR.CustomerId = CC.CustomerId
  WHERE NOT EXISTS(SELECT 1 FROM VEEV_UserRole UR WHERE SVUR.Id = UR.ExternalId1 AND SVUR.CustomerId = UR.CustomerId AND UR.EndDate IS NULL)

  END
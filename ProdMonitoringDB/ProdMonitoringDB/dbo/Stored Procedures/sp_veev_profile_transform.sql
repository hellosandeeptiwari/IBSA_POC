CREATE OR ALTER PROCEDURE [dbo].[sp_veev_profile_transform]
AS
BEGIN
	UPDATE P
	SET P.[CreatedById]=SP.[CreatedById],
		P.[CreatedDate]=SP.[CreatedDate],
		P.[Description]=SP.[Description],
		P.[LastModifiedById]=SP.[LastModifiedById],
		P.[LastModifiedDate]=SP.[LastModifiedDate],
		P.[ProfileName]=SP.[Name],
		P.[Type]=SP.[Type],
		P.[UserLicenseId]=SP.[UserLicenseId],
		P.[UserType]=SP.[UserType],
		P.[SystemModstamp] = SP.[SystemModstamp]
		FROM VEEV_Profile P
		INNER JOIN Staging_VEEV_Profile SP ON P.ExternalId1 = SP.Id AND P.EndDate IS NULL
		INNER JOIN ConexusCustomer CC ON CC.CustomerId = P.CustomerId

INSERT INTO [dbo].[VEEV_Profile]
           ([ProfileId]
           ,[CreatedById]
           ,[CreatedDate]
           ,[Description]
           ,[ExternalId1]
           ,[LastModifiedById]
           ,[LastModifiedDate]
           ,[ProfileName]
           ,[SystemModstamp]
           ,[Type]
           ,[UserLicenseId]
           ,[UserType]
           ,[CustomerId])
     
SELECT NEWID() AS ProfileId,
		SVP.CreatedById,SVP.CreatedDate,SVP.[Description],SVP.Id,SVP.LastModifiedById,SVP.LastModifiedDate,SVP.[Name],
		SVP.SystemModstamp,SVP.[Type],SVP.UserLicenseId,SVP.UserType,
		cc.CustomerId FROM Staging_VEEV_Profile SVP
		INNER JOIN ConexusCustomer CC ON SVP.CustomerId = CC.CustomerId
		WHERE NOT EXISTS(SELECT 1 FROM VEEV_Profile VP WHERE VP.ExternalId1 = SVP.Id AND SVP.CustomerId = VP.CustomerId AND VP.EndDate IS NULL)

END
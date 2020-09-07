CREATE PROCEDURE [dbo].[sp_reporting_sync_and_other_userinfo_extract_transform]
AS
BEGIN

TRUNCATE TABLE [Reporting_Sync_And_Other_UserInfo_Extract];

INSERT INTO [Reporting_Sync_And_Other_UserInfo_Extract](
					[Territory Name],
					[Profile],
					[Role],
					[18 Digit User Id],
					[Full Name],
					[First Name],
					[Last Name],
					[User Name],
					[Last Login],
					[Last iPad Connect],
					[Last iPad Connect version],
					[Last iPad IOS Version],
					[Last iPad Sync],
					[Time Zone],
					[CustomerId],
					[ReportDate])

			SELECT VT.[TerritoryName],VP.[ProfileName],VR.[UserRoleName],
			VU.ExternalId1,VU.[Name],VU.FirstName,VU.LastName,VU.Username,VU.LastLoginDate
			,VU.LastiPadConnect,VU.LastiPadConnectVersion,VU.LastiPadiOSVersion,VU.LastiPadSync
			,VU.TimeZone,CC.CustomerId,GETUTCDATE() FROM VEEV_User VU
			INNER JOIN VEEV_Profile VP ON VU.ProfileId = VP.ExternalId1 AND VP.EndDate IS NULL
			INNER JOIN VEEV_UserRole VR ON VU.UserRoleId = VR.ExternalId1 AND VR.EndDate IS NULL
			INNER JOIN VEEV_UserTerritory VUT ON VU.ExternalId1 = VUT.UserId AND VUT.EndDate IS NULL
			INNER JOIN VEEV_Territory VT ON VT.ExternalId1 = VUT.TerritoryId AND VT.EndDate IS NULL
			INNER JOIN ConexusCustomer CC ON VU.CustomerId = CC.CustomerId
			WHERE VU.IsActive = 'ACTV' AND VU.EndDate IS NULL;

END

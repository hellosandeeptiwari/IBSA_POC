CREATE OR ALTER PROCEDURE [dbo].[sp_veev_user_transform]

AS
BEGIN

	UPDATE U 
	SET U.[City] = SU.[City],
		U.[Country] = SU.[Country],
		U.[CreatedById] = SU.[CreatedById],
		U.[CreatedDate] = SU.[CreatedDate],
		U.[Email] = SU.[Email],
		U.[Fax] = SU.[Fax],
		U.[FirstName] = SU.[FirstName],
		U.[IsActive] = CASE WHEN SU.IsActive='True' THEN 'ACTV'
				WHEN SU.IsActive='False' THEN 'INAC' ELSE NULL END,
		U.[LastLoginDate] = SU.[LastLoginDate],
		U.[LastModifiedById] = SU.[LastModifiedById],
		U.[LastModifiedDate] = SU.[LastModifiedDate],
		U.[LastName] = SU.[LastName],
		U.[LastiPadConnectVersion] = SU.[LastiPadConnectVersion],
		U.[LastiPadConnect] = SU.[LastiPadConnect],
		U.[LastiPadiOSVersion] = SU.[LastiPadiOSVersion],
		U.[LastiPadSync] = SU.[LastiPadSync],
		U.[ManagerId] = SU.[ManagerId],
		U.[MobilePhone] = SU.[MobilePhone],
		U.[Name] = SU.[Name],
		U.[Phone] = SU.[Phone],
		U.[PostalCode] = SU.[PostalCode],
		U.[PrimaryTerritory] = SU.[PrimaryTerritory],
		U.[ProfileId] = SU.[ProfileId],
		U.[ProfileName] = SU.[ProfileName],
		U.[State] = SU.[State],
		U.[Street] = SU.[Street],
		U.[SystemModstamp] = SU.[SystemModstamp],
		U.[TimeZone] = SU.[TimeZone],
		U.[Title] = SU.[Title],
		U.[Username] = SU.[Username],
		U.[UserRoleId] = SU.[UserRoleId],
		U.[UserType] = SU.[UserType]
		FROM VEEV_User U
	INNER JOIN Staging_VEEV_User SU ON U.[ExternalId1]=SU.Id AND U.EndDate IS NULL
	INNER JOIN ConexusCustomer CC ON CC.CustomerId = U.CustomerId ;

INSERT INTO [dbo].[VEEV_User]
				([UserId]
				,[City]
				,[Country]
				,[CreatedById]
				,[CreatedDate]
				,[Email]
				,[Fax]
				,[FirstName]
				,[ExternalId1]
				,[IsActive]
				,[LastLoginDate]
				,[LastModifiedById]
				,[LastModifiedDate]
				,[LastName]
				,[LastiPadConnectVersion]
				,[LastiPadConnect]
				,[LastiPadiOSVersion]
				,[LastiPadSync]
				,[ManagerId]
				,[MobilePhone]
				,[Name]
				,[Phone]
				,[PostalCode]
				,[PrimaryTerritory]
				,[ProfileId]
				,[ProfileName]
				,[State]
				,[Street]
				,[SystemModstamp]
				,[TimeZone]
				,[Title]
				,[Username]
				,[UserRoleId]
				,[UserType]
				,[CustomerId])
SELECT NEWID() AS UserId,SVU.City,SVU.Country,SVU.CreatedById,SVU.CreatedDate,SVU.Email,SVU.Fax,SVU.FirstName,SVU.Id,
				CASE WHEN SVU.IsActive='True' THEN 'ACTV'
				WHEN SVU.IsActive='False' THEN 'INAC' ELSE NULL END, SVU.LastLoginDate,SVU.LastModifiedById,SVU.LastModifiedDate,SVU.LastName,
				SVU.LastiPadConnectVersion,SVU.LastiPadConnect,SVU.LastiPadiOSVersion,SVU.LastiPadSync,SVU.ManagerId,SVU.MobilePhone,SVU.[Name],
				SVU.Phone,SVU.PostalCode,SVU.PrimaryTerritory,
				VP.ExternalId1,SVU.ProfileName,SVU.[State],
				SVU.Street,SVU.SystemModstamp,SVU.TimeZone,SVU.Title,SVU.Username,VUR.ExternalId1,SVU.UserType,CC.CustomerId
				FROM Staging_VEEV_User SVU
				INNER JOIN ConexusCustomer CC ON SVU.CustomerId = CC.CustomerId 
				INNER JOIN VEEV_UserRole VUR ON SVU.UserRoleId = VUR.ExternalId1 AND VUR.EndDate IS NULL
				INNER JOIN VEEV_Profile VP ON SVU.ProfileId = VP.ExternalId1 AND VP.EndDate IS NULL
				WHERE NOT EXISTS(SELECT 1 FROM VEEV_User VU WHERE VU.ExternalId1 = SVU.Id AND SVU.CustomerId = VU.CustomerId AND VU.EndDate IS NULL);

				WITH cte_Shift AS (
				  SELECT UserId, Email,FirstName,LastName,Name,MobilePhone,Phone,Street,Username, ROW_NUMBER() OVER(ORDER BY UserId) AS RowNum FROM VEEV_User
				)
				SELECT t1.UserId, t1.RowNum, 
				t2.FirstName + t2.LastName + '@demo.com' AS DemoEmail,t1.FirstName AS DemoFirstName, t2.LastName AS DemoLastName,
				t2.FirstName + t2.LastName AS [DemoName],
				LEFT(t2.MobilePhone, NULLIF(LEN(t2.MobilePhone)-2,-2)) AS DemoMobilePhone,
				LEFT(t2.Phone, NULLIF(LEN(t2.Phone)-2,-2)) AS DemoPhone,
				LEFT(t2.Street, NULLIF(LEN(t2.Street)-3,-3)) AS DemoStreet, 
				t2.LastName + t1.FirstName + '@demoorg.com' AS DemoUsername
				INTO #temp_ShiftedData
				from cte_Shift t1
				LEFT OUTER JOIN cte_Shift t2 ON t2.RowNum = t1.RowNum - 1
				ORDER BY t1.UserId;


				UPDATE T1
				SET T1.DemoEmail = T2.DemoFirstName + T2.DemoLastName + '@demo.com',
					T1.DemoLastName = T2.DemoLastName,
					T1.[DemoName] = T2.DemoFirstName + T2.DemoLastName,
					T1.DemoMobilePhone = LEFT(T2.DemoMobilePhone, NULLIF(LEN(T2.DemoMobilePhone)-2,-2)),
					T1.DemoPhone = LEFT(T2.DemoPhone, NULLIF(LEN(T2.DemoPhone)-2,-2)),
					T1.DemoStreet = LEFT(T2.DemoStreet, NULLIF(LEN(T2.DemoStreet)-3,-3)), 
					T1.DemoUsername = T2.DemoLastName + T1.DemoFirstName + '@demoorg.com'
				FROM #temp_ShiftedData T1
				LEFT OUTER JOIN #temp_ShiftedData T2 ON T2.RowNum = T1.RowNum + 1
				WHERE T1.RowNum = 1

				UPDATE U
				SET 
				U.Demo_Email = T.DemoEmail,
				U.Demo_FirstName = T.DemoFirstName,
				U.Demo_LastName = T.DemoLastName,
				U.Demo_MobilePhone = T.DemoMobilePhone,
				U.Demo_Name = T.DemoName,
				U.Demo_Phone = T.DemoPhone,
				U.Demo_Street = T.DemoStreet,
				U.Demo_Username = T.DemoUsername
				FROM VEEV_User U
				INNER JOIN #temp_ShiftedData T ON U.UserId = T.UserId

END

CREATE   PROCEDURE [dbo].[sp_user_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_user_transform', 'Started', GETUTCDATE());


	UPDATE P SET 
		P.UpdatedDate = GETDATE(),
		P.ExternalId1 = S.Id,
		P.Username = S.Username,
		P.LastName = S.LastName,
		P.FirstName = S.FirstName,
		P.Name = S.Name,
		P.CompanyName = S.CompanyName,
		P.Division = S.Division,
		P.Department = S.Department,
		P.Title = S.Title,
		P.Street = S.Street,
		P.City = S.City,
		P.State = S.State,
		P.PostalCode = S.PostalCode,
		P.Country = S.Country,
		P.Email = S.Email,
		P.Phone = S.Phone,
		P.Fax = S.Fax,
		P.MobilePhone = S.MobilePhone,
		P.Alias = S.Alias,
		P.IsActive = S.IsActive,
		P.UserRoleId = S.UserRoleId,
		P.ProfileId = S.ProfileId,
		P.UserType = S.UserType,
		P.LanguageLocaleKey = S.LanguageLocaleKey,
		P.EmployeeNumber = S.EmployeeNumber,
		P.DelegatedApproverId = S.DelegatedApproverId,
		P.ManagerId = S.ManagerId,
		P.LastLoginDate = S.LastLoginDate,
		P.LastPasswordChangeDate = S.LastPasswordChangeDate,
		P.VeevaCreatedDate = S.CreatedDate,
		P.VeevaCreatedById = S.CreatedById,
		P.LastModifiedDate = S.LastModifiedDate,
		P.LastModifiedById = S.LastModifiedById,
		P.SystemModstamp = S.SystemModstamp,
		P.ContactId = S.ContactId,
		P.AccountId = S.AccountId,
		P.LastViewedDate = S.LastViewedDate,
		P.LastReferencedDate = S.LastReferencedDate,
		P.LastMobileConnect = S.Last_Mobile_Connect_vod__c,
		P.LastTabletConnect = S.Last_Tablet_Connect_vod__c,
		P.LastMobileConnectVersion = S.Last_Mobile_Connect_Version_vod__c,
		P.LastTabletConnectVersion = S.Last_Tablet_Connect_Version_vod__c,
		P.LastMobileSync = S.Last_Mobile_Sync_vod__c,
		P.LastTabletSync = S.Last_Tablet_Sync_vod__c,
		P.ForceFullRefresh = S.Force_Full_Refresh_vod__c,
		P.FacetimeEmail = S.Facetime_Email_vod__c,
		P.FacetimePhone = S.Facetime_Phone_vod__c,
		P.ProductExpertise = S.Product_Expertise_vod__c,
		P.Available = S.Available_vod__c,
		P.AvailableLastUpdate = S.Available_Last_Update_vod__c,
		P.LastiPadConnectVersion = S.Last_iPad_Connect_Version_vod__c,
		P.LastiPadConnect = S.Last_iPad_Connect_vod__c,
		P.LastiPadSync = S.Last_iPad_Sync_vod__c,
		P.LastiPadiOSVersion = S.Last_iPad_iOS_Version_vod__c,
		P.LastWinModernConnectVersion = S.Last_WinModern_Connect_Version_vod__c,
		P.LastWinModernConnect = S.Last_WinModern_Connect_vod__c,
		P.LastWinModernSync = S.Last_WinModern_Sync_vod__c,
		P.PrimaryTerritory = S.Primary_Territory_vod__c,
		P.LastWinModernWindowsVersion = S.Last_WinModern_Windows_Version_vod__c,
		P.LastiPhoneConnectVersion = S.Last_iPhone_Connect_Version_vod__c,
		P.LastiPhoneConnect = S.Last_iPhone_Connect_vod__c,
		P.LastiPhoneSync = S.Last_iPhone_Sync_vod__c,
		P.LastiPhoneiOSVersion = S.Last_iPhone_iOS_Version_vod__c
	FROM [dbo].[User] P
	INNER JOIN [dbo].[Staging_User] S ON S.[Id] = P.[ExternalId1] 
		AND S.SystemModstamp <> P.SystemModstamp AND P.EndDate IS NULL;


	INSERT INTO [dbo].[User]
		([UserId], CreatedDate, ExternalId1, Username, LastName, FirstName, Name, CompanyName, Division, 
		Department, Title, Street, City, State, PostalCode, Country, Email, Phone, Fax, MobilePhone, Alias, 
		IsActive, UserRoleId, ProfileId, UserType, LanguageLocaleKey, EmployeeNumber, DelegatedApproverId, 
		ManagerId, LastLoginDate, LastPasswordChangeDate, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, 
		LastModifiedById, SystemModstamp, ContactId, AccountId, LastViewedDate, LastReferencedDate, 
		LastMobileConnect, LastTabletConnect, LastMobileConnectVersion, LastTabletConnectVersion, 
		LastMobileSync, LastTabletSync, ForceFullRefresh, FacetimeEmail, FacetimePhone, 
		ProductExpertise, Available, AvailableLastUpdate, LastiPadConnectVersion, LastiPadConnect, 
		LastiPadSync, LastiPadiOSVersion, LastWinModernConnectVersion, LastWinModernConnect, 
		LastWinModernSync, PrimaryTerritory, LastWinModernWindowsVersion,  
		LastiPhoneConnectVersion, LastiPhoneConnect, LastiPhoneSync, LastiPhoneiOSVersion)
	SELECT
		NEWID() AS [UserId], GETDATE(),
		Id, Username, LastName, FirstName, Name, CompanyName, Division, 
		Department, Title, Street, City, State, PostalCode, Country, Email, Phone, Fax, MobilePhone, Alias, 
		IsActive, UserRoleId, ProfileId, UserType, LanguageLocaleKey, EmployeeNumber, DelegatedApproverId, 
		ManagerId, LastLoginDate, LastPasswordChangeDate, CreatedDate, CreatedById, LastModifiedDate, 
		LastModifiedById, SystemModstamp, ContactId, AccountId, LastViewedDate, LastReferencedDate, 
		Last_Mobile_Connect_vod__c, Last_Tablet_Connect_vod__c, Last_Mobile_Connect_Version_vod__c, Last_Tablet_Connect_Version_vod__c,
		Last_Mobile_Sync_vod__c, Last_Tablet_Sync_vod__c, Force_Full_Refresh_vod__c, Facetime_Email_vod__c, Facetime_Phone_vod__c, 
		Product_Expertise_vod__c, Available_vod__c, Available_Last_Update_vod__c, Last_iPad_Connect_Version_vod__c, 
		Last_iPad_Connect_vod__c, 
		Last_iPad_Sync_vod__c, Last_iPad_iOS_Version_vod__c, Last_WinModern_Connect_Version_vod__c, Last_WinModern_Connect_vod__c, 
		Last_WinModern_Sync_vod__c, Primary_Territory_vod__c, Last_WinModern_Windows_Version_vod__c,  
		Last_iPhone_Connect_Version_vod__c, Last_iPhone_Connect_vod__c, Last_iPhone_Sync_vod__c, Last_iPhone_iOS_Version_vod__c
	FROM [Staging_User] AS S
	WHERE NOT EXISTS (SELECT 1 FROM [User] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_user_transform', 'Completed', GETUTCDATE());

END


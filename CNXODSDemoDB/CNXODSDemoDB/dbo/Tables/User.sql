CREATE TABLE [dbo].[User] (
    [Id]                          INT              IDENTITY (1, 1) NOT NULL,
    [EndDate]                     DATETIME         NULL,
    [CreatedDate]                 DATETIME         NULL,
    [UpdatedDate]                 DATETIME         NULL,
    [ExternalId1]                 VARCHAR (400)    NULL,
    [UserId]                      UNIQUEIDENTIFIER NULL,
    [Username]                    VARCHAR (400)    NULL,
    [LastName]                    VARCHAR (400)    NULL,
    [FirstName]                   VARCHAR (400)    NULL,
    [Name]                        VARCHAR (400)    NULL,
    [CompanyName]                 VARCHAR (400)    NULL,
    [Division]                    VARCHAR (400)    NULL,
    [Department]                  VARCHAR (400)    NULL,
    [Title]                       VARCHAR (400)    NULL,
    [Street]                      VARCHAR (400)    NULL,
    [City]                        VARCHAR (400)    NULL,
    [State]                       VARCHAR (400)    NULL,
    [PostalCode]                  VARCHAR (400)    NULL,
    [Country]                     VARCHAR (400)    NULL,
    [Email]                       VARCHAR (400)    NULL,
    [Phone]                       VARCHAR (400)    NULL,
    [Fax]                         VARCHAR (400)    NULL,
    [MobilePhone]                 VARCHAR (400)    NULL,
    [Alias]                       VARCHAR (400)    NULL,
    [IsActive]                    VARCHAR (400)    NULL,
    [UserRoleId]                  VARCHAR (400)    NULL,
    [ProfileId]                   VARCHAR (400)    NULL,
    [UserType]                    VARCHAR (400)    NULL,
    [LanguageLocaleKey]           VARCHAR (400)    NULL,
    [EmployeeNumber]              VARCHAR (400)    NULL,
    [DelegatedApproverId]         VARCHAR (400)    NULL,
    [ManagerId]                   VARCHAR (400)    NULL,
    [LastLoginDate]               VARCHAR (400)    NULL,
    [LastPasswordChangeDate]      VARCHAR (400)    NULL,
    [VeevaCreatedDate]            VARCHAR (400)    NULL,
    [VeevaCreatedById]            VARCHAR (400)    NULL,
    [LastModifiedDate]            VARCHAR (400)    NULL,
    [LastModifiedById]            VARCHAR (400)    NULL,
    [SystemModstamp]              VARCHAR (400)    NULL,
    [ContactId]                   VARCHAR (400)    NULL,
    [AccountId]                   VARCHAR (400)    NULL,
    [LastViewedDate]              VARCHAR (400)    NULL,
    [LastReferencedDate]          VARCHAR (400)    NULL,
    [LastMobileConnect]           VARCHAR (400)    NULL,
    [LastTabletConnect]           VARCHAR (400)    NULL,
    [LastMobileConnectVersion]    VARCHAR (400)    NULL,
    [LastTabletConnectVersion]    VARCHAR (400)    NULL,
    [LastMobileSync]              VARCHAR (400)    NULL,
    [LastTabletSync]              VARCHAR (400)    NULL,
    [ForceFullRefresh]            VARCHAR (400)    NULL,
    [FacetimeEmail]               VARCHAR (400)    NULL,
    [FacetimePhone]               VARCHAR (400)    NULL,
    [ProductExpertise]            VARCHAR (400)    NULL,
    [Available]                   VARCHAR (400)    NULL,
    [AvailableLastUpdate]         VARCHAR (400)    NULL,
    [LastiPadConnectVersion]      VARCHAR (400)    NULL,
    [LastiPadConnect]             VARCHAR (400)    NULL,
    [LastiPadSync]                VARCHAR (400)    NULL,
    [LastiPadiOSVersion]          VARCHAR (400)    NULL,
    [LastWinModernConnectVersion] VARCHAR (400)    NULL,
    [LastWinModernConnect]        VARCHAR (400)    NULL,
    [LastWinModernSync]           VARCHAR (400)    NULL,
    [PrimaryTerritory]            VARCHAR (400)    NULL,
    [LastWinModernWindowsVersion] VARCHAR (400)    NULL,
    [LastiPhoneConnectVersion]    VARCHAR (400)    NULL,
    [LastiPhoneConnect]           VARCHAR (400)    NULL,
    [LastiPhoneSync]              VARCHAR (400)    NULL,
    [LastiPhoneiOSVersion]        VARCHAR (400)    NULL,
    CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE TRIGGER [dbo].[trg_User] on [dbo].[User] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT UserId, Username, LastName, FirstName, Name, Title, Street, City, State, PostalCode, Email, Phone, IsActive, UserRoleId, ProfileId, UserType, EmployeeNumber, ManagerId into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare @UsernameINSERT varchar(400), @LastNameINSERT varchar(400), @FirstNameINSERT varchar(400), @NameINSERT varchar(400), @TitleINSERT varchar(400), @StreetINSERT varchar(400), @CityINSERT varchar(400), @StateINSERT varchar(400), @PostalCodeINSERT varchar(400), @EmailINSERT varchar(400), @PhoneINSERT varchar(400), @IsActiveINSERT varchar(400), @UserRoleIdINSERT varchar(400), @ProfileIdINSERT varchar(400), @UserTypeINSERT varchar(400), @EmployeeNumberINSERT varchar(400), @ManagerIdINSERT varchar(400),  
				@UsernameDELETE varchar(400), @LastNameDELETE varchar(400), @FirstNameDELETE varchar(400), @NameDELETE varchar(400), @TitleDELETE varchar(400), @StreetDELETE varchar(400), @CityDELETE varchar(400), @StateDELETE varchar(400), @PostalCodeDELETE varchar(400), @EmailDELETE varchar(400), @PhoneDELETE varchar(400), @IsActiveDELETE varchar(400), @UserRoleIdDELETE varchar(400), @ProfileIdDELETE varchar(400), @UserTypeDELETE varchar(400), @EmployeeNumberDELETE varchar(400), @ManagerIdDELETE varchar(400), 
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = UserId, @UsernameINSERT = Username, @LastNameINSERT = LastName, @FirstNameINSERT = FirstName, @NameINSERT = Name, @TitleINSERT = Title, @StreetINSERT = Street, @CityINSERT = City, @StateINSERT = State, @PostalCodeINSERT = PostalCode, @EmailINSERT = Email, @PhoneINSERT = Phone, @IsActiveINSERT = IsActive, @UserRoleIdINSERT = UserRoleId, @ProfileIdINSERT = ProfileId, @UserTypeINSERT = UserType, @EmployeeNumberINSERT = EmployeeNumber, @ManagerIdINSERT = ManagerId
				from #insertedUPDATE;

				SELECT
					@UsernameDELETE = Username, @LastNameDELETE = LastName, @FirstNameDELETE = FirstName, @NameDELETE = Name, @TitleDELETE = Title, @StreetDELETE = Street, @CityDELETE = City, @StateDELETE = State, @PostalCodeDELETE = PostalCode, @EmailDELETE = Email, @PhoneDELETE = Phone, @IsActiveDELETE = IsActive, @UserRoleIdDELETE = UserRoleId, @ProfileIdDELETE = ProfileId, @UserTypeDELETE = UserType, @EmployeeNumberDELETE = EmployeeNumber, @ManagerIdDELETE = ManagerId
				from #deleted WHERE UserId = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					@UsernameINSERT <> @UsernameDELETE OR (@UsernameINSERT IS NULL AND @UsernameDELETE IS NOT NULL) OR (@UsernameINSERT IS NOT NULL AND @UsernameDELETE IS NULL) OR @LastNameINSERT <> @LastNameDELETE OR (@LastNameINSERT IS NULL AND @LastNameDELETE IS NOT NULL) OR (@LastNameINSERT IS NOT NULL AND @LastNameDELETE IS NULL) OR @FirstNameINSERT <> @FirstNameDELETE OR (@FirstNameINSERT IS NULL AND @FirstNameDELETE IS NOT NULL) OR (@FirstNameINSERT IS NOT NULL AND @FirstNameDELETE IS NULL) OR @NameINSERT <> @NameDELETE OR (@NameINSERT IS NULL AND @NameDELETE IS NOT NULL) OR (@NameINSERT IS NOT NULL AND @NameDELETE IS NULL) OR @TitleINSERT <> @TitleDELETE OR (@TitleINSERT IS NULL AND @TitleDELETE IS NOT NULL) OR (@TitleINSERT IS NOT NULL AND @TitleDELETE IS NULL) OR @StreetINSERT <> @StreetDELETE OR (@StreetINSERT IS NULL AND @StreetDELETE IS NOT NULL) OR (@StreetINSERT IS NOT NULL AND @StreetDELETE IS NULL) OR @CityINSERT <> @CityDELETE OR (@CityINSERT IS NULL AND @CityDELETE IS NOT NULL) OR (@CityINSERT IS NOT NULL AND @CityDELETE IS NULL) OR @StateINSERT <> @StateDELETE OR (@StateINSERT IS NULL AND @StateDELETE IS NOT NULL) OR (@StateINSERT IS NOT NULL AND @StateDELETE IS NULL) OR @PostalCodeINSERT <> @PostalCodeDELETE OR (@PostalCodeINSERT IS NULL AND @PostalCodeDELETE IS NOT NULL) OR (@PostalCodeINSERT IS NOT NULL AND @PostalCodeDELETE IS NULL) OR @EmailINSERT <> @EmailDELETE OR (@EmailINSERT IS NULL AND @EmailDELETE IS NOT NULL) OR (@EmailINSERT IS NOT NULL AND @EmailDELETE IS NULL) OR @PhoneINSERT <> @PhoneDELETE OR (@PhoneINSERT IS NULL AND @PhoneDELETE IS NOT NULL) OR (@PhoneINSERT IS NOT NULL AND @PhoneDELETE IS NULL) OR @IsActiveINSERT <> @IsActiveDELETE OR (@IsActiveINSERT IS NULL AND @IsActiveDELETE IS NOT NULL) OR (@IsActiveINSERT IS NOT NULL AND @IsActiveDELETE IS NULL) OR @UserRoleIdINSERT <> @UserRoleIdDELETE OR (@UserRoleIdINSERT IS NULL AND @UserRoleIdDELETE IS NOT NULL) OR (@UserRoleIdINSERT IS NOT NULL AND @UserRoleIdDELETE IS NULL) OR @ProfileIdINSERT <> @ProfileIdDELETE OR (@ProfileIdINSERT IS NULL AND @ProfileIdDELETE IS NOT NULL) OR (@ProfileIdINSERT IS NOT NULL AND @ProfileIdDELETE IS NULL) OR @UserTypeINSERT <> @UserTypeDELETE OR (@UserTypeINSERT IS NULL AND @UserTypeDELETE IS NOT NULL) OR (@UserTypeINSERT IS NOT NULL AND @UserTypeDELETE IS NULL) OR @EmployeeNumberINSERT <> @EmployeeNumberDELETE OR (@EmployeeNumberINSERT IS NULL AND @EmployeeNumberDELETE IS NOT NULL) OR (@EmployeeNumberINSERT IS NOT NULL AND @EmployeeNumberDELETE IS NULL) OR @ManagerIdINSERT <> @ManagerIdDELETE OR (@ManagerIdINSERT IS NULL AND @ManagerIdDELETE IS NOT NULL) OR (@ManagerIdINSERT IS NOT NULL AND @ManagerIdDELETE IS NULL)
					BEGIN
						UPDATE [User] SET EndDate = GETDATE() WHERE UserId = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [User](CreatedDate, UpdatedDate, ExternalId1, UserId, Username, LastName, FirstName, Name, CompanyName, Division, Department, Title, Street, City, State, PostalCode, Country, Email, Phone, Fax, MobilePhone, Alias, IsActive, UserRoleId, ProfileId, UserType, LanguageLocaleKey, EmployeeNumber, DelegatedApproverId, ManagerId, LastLoginDate, LastPasswordChangeDate, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ContactId, AccountId, LastViewedDate, LastReferencedDate, LastMobileConnect, LastTabletConnect, LastMobileConnectVersion, LastTabletConnectVersion, LastMobileSync, LastTabletSync, ForceFullRefresh, FacetimeEmail, FacetimePhone, ProductExpertise, Available, AvailableLastUpdate, LastiPadConnectVersion, LastiPadConnect, LastiPadSync, LastiPadiOSVersion, LastWinModernConnectVersion, LastWinModernConnect, LastWinModernSync, PrimaryTerritory, LastWinModernWindowsVersion, LastiPhoneConnectVersion, LastiPhoneConnect, LastiPhoneSync, LastiPhoneiOSVersion)
						SELECT CreatedDate, UpdatedDate, ExternalId1, UserId, Username, LastName, FirstName, Name, CompanyName, Division, Department, Title, Street, City, State, PostalCode, Country, Email, Phone, Fax, MobilePhone, Alias, IsActive, UserRoleId, ProfileId, UserType, LanguageLocaleKey, EmployeeNumber, DelegatedApproverId, ManagerId, LastLoginDate, LastPasswordChangeDate, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ContactId, AccountId, LastViewedDate, LastReferencedDate, LastMobileConnect, LastTabletConnect, LastMobileConnectVersion, LastTabletConnectVersion, LastMobileSync, LastTabletSync, ForceFullRefresh, FacetimeEmail, FacetimePhone, ProductExpertise, Available, AvailableLastUpdate, LastiPadConnectVersion, LastiPadConnect, LastiPadSync, LastiPadiOSVersion, LastWinModernConnectVersion, LastWinModernConnect, LastWinModernSync, PrimaryTerritory, LastWinModernWindowsVersion, LastiPhoneConnectVersion, LastiPhoneConnect, LastiPhoneSync, LastiPhoneiOSVersion
						FROM #insertedUPDATE WHERE UserId = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET T.CreatedDate = I.CreatedDate
						 , T.UpdatedDate = I.UpdatedDate
						 , T.ExternalId1 = I.ExternalId1
						 , T.CompanyName = I.CompanyName
						 , T.Division = I.Division
						 , T.Department = I.Department
						 , T.Country = I.Country
						 , T.Fax = I.Fax
						 , T.MobilePhone = I.MobilePhone
						 , T.Alias = I.Alias
						 , T.LanguageLocaleKey = I.LanguageLocaleKey
						 , T.DelegatedApproverId = I.DelegatedApproverId
						 , T.LastLoginDate = I.LastLoginDate
						 , T.LastPasswordChangeDate = I.LastPasswordChangeDate
						 , T.VeevaCreatedDate = I.VeevaCreatedDate
						 , T.VeevaCreatedById = I.VeevaCreatedById
						 , T.LastModifiedDate = I.LastModifiedDate
						 , T.LastModifiedById = I.LastModifiedById
						 , T.SystemModstamp = I.SystemModstamp
						 , T.ContactId = I.ContactId
						 , T.AccountId = I.AccountId
						 , T.LastViewedDate = I.LastViewedDate
						 , T.LastReferencedDate = I.LastReferencedDate
						 , T.LastMobileConnect = I.LastMobileConnect
						 , T.LastTabletConnect = I.LastTabletConnect
						 , T.LastMobileConnectVersion = I.LastMobileConnectVersion
						 , T.LastTabletConnectVersion = I.LastTabletConnectVersion
						 , T.LastMobileSync = I.LastMobileSync
						 , T.LastTabletSync = I.LastTabletSync
						 , T.ForceFullRefresh = I.ForceFullRefresh
						 , T.FacetimeEmail = I.FacetimeEmail
						 , T.FacetimePhone = I.FacetimePhone
						 , T.ProductExpertise = I.ProductExpertise
						 , T.Available = I.Available
						 , T.AvailableLastUpdate = I.AvailableLastUpdate
						 , T.LastiPadConnectVersion = I.LastiPadConnectVersion
						 , T.LastiPadConnect = I.LastiPadConnect
						 , T.LastiPadSync = I.LastiPadSync
						 , T.LastiPadiOSVersion = I.LastiPadiOSVersion
						 , T.LastWinModernConnectVersion = I.LastWinModernConnectVersion
						 , T.LastWinModernConnect = I.LastWinModernConnect
						 , T.LastWinModernSync = I.LastWinModernSync
						 , T.PrimaryTerritory = I.PrimaryTerritory
						 , T.LastWinModernWindowsVersion = I.LastWinModernWindowsVersion
						 , T.LastiPhoneConnectVersion = I.LastiPhoneConnectVersion
						 , T.LastiPhoneConnect = I.LastiPhoneConnect
						 , T.LastiPhoneSync = I.LastiPhoneSync
						 , T.LastiPhoneiOSVersion = I.LastiPhoneiOSVersion
					FROM [User] T INNER JOIN #insertedUPDATE I ON T.UserId = I.UserId AND I.UserId = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where UserId = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [User](CreatedDate, UpdatedDate, ExternalId1, UserId, Username, LastName, FirstName, Name, CompanyName, Division, Department, Title, Street, City, State, PostalCode, Country, Email, Phone, Fax, MobilePhone, Alias, IsActive, UserRoleId, ProfileId, UserType, LanguageLocaleKey, EmployeeNumber, DelegatedApproverId, ManagerId, LastLoginDate, LastPasswordChangeDate, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ContactId, AccountId, LastViewedDate, LastReferencedDate, LastMobileConnect, LastTabletConnect, LastMobileConnectVersion, LastTabletConnectVersion, LastMobileSync, LastTabletSync, ForceFullRefresh, FacetimeEmail, FacetimePhone, ProductExpertise, Available, AvailableLastUpdate, LastiPadConnectVersion, LastiPadConnect, LastiPadSync, LastiPadiOSVersion, LastWinModernConnectVersion, LastWinModernConnect, LastWinModernSync, PrimaryTerritory, LastWinModernWindowsVersion, LastiPhoneConnectVersion, LastiPhoneConnect, LastiPhoneSync, LastiPhoneiOSVersion)
				SELECT CreatedDate, UpdatedDate, ExternalId1, UserId, Username, LastName, FirstName, Name, CompanyName, Division, Department, Title, Street, City, State, PostalCode, Country, Email, Phone, Fax, MobilePhone, Alias, IsActive, UserRoleId, ProfileId, UserType, LanguageLocaleKey, EmployeeNumber, DelegatedApproverId, ManagerId, LastLoginDate, LastPasswordChangeDate, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ContactId, AccountId, LastViewedDate, LastReferencedDate, LastMobileConnect, LastTabletConnect, LastMobileConnectVersion, LastTabletConnectVersion, LastMobileSync, LastTabletSync, ForceFullRefresh, FacetimeEmail, FacetimePhone, ProductExpertise, Available, AvailableLastUpdate, LastiPadConnectVersion, LastiPadConnect, LastiPadSync, LastiPadiOSVersion, LastWinModernConnectVersion, LastWinModernConnect, LastWinModernSync, PrimaryTerritory, LastWinModernWindowsVersion, LastiPhoneConnectVersion, LastiPhoneConnect, LastiPhoneSync, LastiPhoneiOSVersion FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [User] SET EndDate = GETDATE() WHERE UserId IN (SELECT UserId FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END


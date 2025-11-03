CREATE TABLE [dbo].[Account] (
    [Id]                             INT              IDENTITY (1, 1) NOT NULL,
    [EndDate]                        DATETIME         NULL,
    [CreatedDate]                    DATETIME         NULL,
    [UpdatedDate]                    DATETIME         NULL,
    [ExternalId1]                    VARCHAR (400)    NULL,
    [AccountId]                      UNIQUEIDENTIFIER NULL,
    [IsDeleted]                      VARCHAR (400)    NULL,
    [MasterRecordId]                 VARCHAR (400)    NULL,
    [Name]                           VARCHAR (400)    NULL,
    [LastName]                       VARCHAR (400)    NULL,
    [FirstName]                      VARCHAR (400)    NULL,
    [Salutation]                     VARCHAR (400)    NULL,
    [RecordTypeId]                   VARCHAR (400)    NULL,
    [ParentId]                       VARCHAR (400)    NULL,
    [Phone]                          VARCHAR (400)    NULL,
    [Fax]                            VARCHAR (400)    NULL,
    [Website]                        VARCHAR (400)    NULL,
    [NumberOfEmployees]              VARCHAR (400)    NULL,
    [Ownership]                      VARCHAR (400)    NULL,
    [OwnerId]                        VARCHAR (400)    NULL,
    [VeevaCreatedDate]               VARCHAR (400)    NULL,
    [VeevaCreatedById]               VARCHAR (400)    NULL,
    [LastModifiedDate]               VARCHAR (400)    NULL,
    [LastModifiedById]               VARCHAR (400)    NULL,
    [SystemModstamp]                 VARCHAR (400)    NULL,
    [LastActivityDate]               VARCHAR (400)    NULL,
    [MayEdit]                        VARCHAR (400)    NULL,
    [IsLocked]                       VARCHAR (400)    NULL,
    [LastViewedDate]                 VARCHAR (400)    NULL,
    [LastReferencedDate]             VARCHAR (400)    NULL,
    [PersonContactId]                VARCHAR (400)    NULL,
    [IsPersonAccount]                VARCHAR (400)    NULL,
    [PersonMailingStreet]            VARCHAR (400)    NULL,
    [PersonMailingCity]              VARCHAR (400)    NULL,
    [PersonMailingState]             VARCHAR (400)    NULL,
    [PersonMailingPostalCode]        VARCHAR (400)    NULL,
    [PersonMailingCountry]           VARCHAR (400)    NULL,
    [PersonOtherStreet]              VARCHAR (400)    NULL,
    [PersonOtherCity]                VARCHAR (400)    NULL,
    [PersonOtherState]               VARCHAR (400)    NULL,
    [PersonOtherPostalCode]          VARCHAR (400)    NULL,
    [PersonOtherCountry]             VARCHAR (400)    NULL,
    [PersonMobilePhone]              VARCHAR (400)    NULL,
    [PersonHomePhone]                VARCHAR (400)    NULL,
    [PersonOtherPhone]               VARCHAR (400)    NULL,
    [PersonAssistantPhone]           VARCHAR (400)    NULL,
    [PersonEmail]                    VARCHAR (400)    NULL,
    [PersonTitle]                    VARCHAR (400)    NULL,
    [PersonDepartment]               VARCHAR (400)    NULL,
    [PersonAssistantName]            VARCHAR (400)    NULL,
    [PersonBirthdate]                VARCHAR (400)    NULL,
    [PersonHasOptedOutOfEmail]       VARCHAR (400)    NULL,
    [PersonHasOptedOutOfFax]         VARCHAR (400)    NULL,
    [PersonDoNotCall]                VARCHAR (400)    NULL,
    [PersonLastCURequestDate]        VARCHAR (400)    NULL,
    [PersonLastCUUpdateDate]         VARCHAR (400)    NULL,
    [PersonEmailBouncedReason]       VARCHAR (400)    NULL,
    [PersonEmailBouncedDate]         VARCHAR (400)    NULL,
    [PersonIndividualId]             VARCHAR (400)    NULL,
    [AccountSource]                  VARCHAR (400)    NULL,
    [ExternalID]                     VARCHAR (400)    NULL,
    [Credentials]                    VARCHAR (400)    NULL,
    [Territory]                      VARCHAR (400)    NULL,
    [ExcludefromZiptoTerrProcessing] VARCHAR (400)    NULL,
    [GroupSpecialty1]                VARCHAR (400)    NULL,
    [GroupSpecialty2]                VARCHAR (400)    NULL,
    [Specialty1]                     VARCHAR (400)    NULL,
    [Specialty2]                     VARCHAR (400)    NULL,
    [FormattedName]                  VARCHAR (400)    NULL,
    [TerritoryTest]                  VARCHAR (400)    NULL,
    [MobileID]                       VARCHAR (400)    NULL,
    [Gender]                         VARCHAR (400)    NULL,
    [ExternalId2]                    VARCHAR (400)    NULL,
    [DoNotSyncSalesData]             VARCHAR (400)    NULL,
    [ID2]                            VARCHAR (400)    NULL,
    [PreferredName]                  VARCHAR (400)    NULL,
    [SampleDefault]                  VARCHAR (400)    NULL,
    [Segmentations]                  VARCHAR (400)    NULL,
    [RestrictedProducts]             VARCHAR (400)    NULL,
    [PayerId]                        VARCHAR (400)    NULL,
    [AlternateName]                  VARCHAR (400)    NULL,
    [DoNotCall]                      VARCHAR (400)    NULL,
    [Bedsc]                          VARCHAR (400)    NULL,
    [SpendAmountc]                   VARCHAR (400)    NULL,
    [PDRPOptOut]                     VARCHAR (400)    NULL,
    [SpendStatusValue]               VARCHAR (400)    NULL,
    [PDRPOptOutDate]                 VARCHAR (400)    NULL,
    [SpendStatus]                    VARCHAR (400)    NULL,
    [EnableRestrictedProducts]       VARCHAR (400)    NULL,
    [CallReminder]                   VARCHAR (400)    NULL,
    [AccountGroup]                   VARCHAR (400)    NULL,
    [PrimaryParent]                  VARCHAR (400)    NULL,
    [Color]                          VARCHAR (400)    NULL,
    [Middle]                         VARCHAR (400)    NULL,
    [Suffix]                         VARCHAR (400)    NULL,
    [NoOrders]                       VARCHAR (400)    NULL,
    [AccountIdentifier]              VARCHAR (400)    NULL,
    [ApprovedEmailOptType]           VARCHAR (400)    NULL,
    [AccountSearchFirstLast]         VARCHAR (400)    NULL,
    [AccountSearchLastFirst]         VARCHAR (400)    NULL,
    [Language]                       VARCHAR (400)    NULL,
    [PracticeatHospital]             VARCHAR (400)    NULL,
    [PracticeNearHospital]           VARCHAR (400)    NULL,
    [DoNotCreateChildAccount]        VARCHAR (400)    NULL,
    [TotalMDsDOsc]                   VARCHAR (400)    NULL,
    [AHAc]                           VARCHAR (400)    NULL,
    [OrderType]                      VARCHAR (400)    NULL,
    [NPI]                            VARCHAR (400)    NULL,
    [MEc]                            VARCHAR (400)    NULL,
    [Speakerc]                       VARCHAR (400)    NULL,
    [Investigator]                   VARCHAR (400)    NULL,
    [DefaultOrderType]               VARCHAR (400)    NULL,
    [TaxStatusc]                     VARCHAR (400)    NULL,
    [Modelc]                         VARCHAR (400)    NULL,
    [Offeringsc]                     VARCHAR (400)    NULL,
    [Departmentsc]                   VARCHAR (400)    NULL,
    [AccountTypec]                   VARCHAR (400)    NULL,
    [AccountSearchBusiness]          VARCHAR (400)    NULL,
    [BusinessProfessionalPerson]     VARCHAR (400)    NULL,
    [HospitalType]                   VARCHAR (400)    NULL,
    [AccountClass]                   VARCHAR (400)    NULL,
    [Furigana]                       VARCHAR (400)    NULL,
    [TotalRevenue000c]               VARCHAR (400)    NULL,
    [NetIncomeLoss000c]              VARCHAR (400)    NULL,
    [PMPMIncomeLoss000c]             VARCHAR (400)    NULL,
    [CommercialPremiumsPMPMc]        VARCHAR (400)    NULL,
    [MedicalLossRatioc]              VARCHAR (400)    NULL,
    [MedicalExpensesPMPMc]           VARCHAR (400)    NULL,
    [CommercialPatientDays1000c]     VARCHAR (400)    NULL,
    [HMOMarketShrc]                  VARCHAR (400)    NULL,
    [HMOc]                           VARCHAR (400)    NULL,
    [HMOPOSc]                        VARCHAR (400)    NULL,
    [PPOc]                           VARCHAR (400)    NULL,
    [PPOPOSc]                        VARCHAR (400)    NULL,
    [Medicarec]                      VARCHAR (400)    NULL,
    [Medicaidc]                      VARCHAR (400)    NULL,
    [BusinessDescriptionc]           VARCHAR (400)    NULL,
    [RegionalStrategyc]              VARCHAR (400)    NULL,
    [ContractsProcessc]              VARCHAR (400)    NULL,
    [Targetc]                        VARCHAR (400)    NULL,
    [KOL]                            VARCHAR (400)    NULL,
    [TotalLivesc]                    VARCHAR (400)    NULL,
    [TotalPhysiciansEnrolledc]       VARCHAR (400)    NULL,
    [TotalPharmacistsc]              VARCHAR (400)    NULL,
    [CNXAddressc]                    VARCHAR (400)    NULL,
    [CNXCRMIDc]                      VARCHAR (400)    NULL,
    [CNXDecilec]                     VARCHAR (400)    NULL,
    [CNXFieldEmailc]                 VARCHAR (400)    NULL,
    [CNXFieldPhonec]                 VARCHAR (400)    NULL,
    [CNXPreferredMethodOfContactc]   VARCHAR (400)    NULL,
    [CNXRolec]                       VARCHAR (400)    NULL,
    [CNXTargetMSLc]                  VARCHAR (400)    NULL,
    [CNXTargetSSc]                   VARCHAR (400)    NULL,
    [CNXTargetTypec]                 VARCHAR (400)    NULL,
    [MobileIDvodpc]                  VARCHAR (400)    NULL,
    [StartDate]                      DATETIME         NULL,
    CONSTRAINT [PK_Account] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Account_EndDate]
    ON [dbo].[Account]([EndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Account_ExternalId1]
    ON [dbo].[Account]([ExternalId1] ASC);


GO
CREATE TRIGGER [dbo].[trg_Account] on [dbo].[Account] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT AccountId, Name, LastName, FirstName, Salutation, RecordTypeId, ParentId, Phone, Website, PersonContactId, IsPersonAccount, PersonEmail, PersonBirthdate, AccountSource, Territory, GroupSpecialty1, GroupSpecialty2, Specialty1, Specialty2, ID2, DoNotCall, PDRPOptOut, PDRPOptOutDate, PrimaryParent, Middle, Suffix, NPI, MEc, AccountTypec, HospitalType, AccountClass, CNXAddressc, CNXCRMIDc, CNXDecilec, CNXFieldPhonec, CNXRolec, CNXTargetTypec into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare @NameINSERT varchar(400), @LastNameINSERT varchar(400), @FirstNameINSERT varchar(400), @SalutationINSERT varchar(400), @RecordTypeIdINSERT varchar(400), @ParentIdINSERT varchar(400), @PhoneINSERT varchar(400), @WebsiteINSERT varchar(400), @PersonContactIdINSERT varchar(400), @IsPersonAccountINSERT varchar(400), @PersonEmailINSERT varchar(400), @PersonBirthdateINSERT varchar(400), @AccountSourceINSERT varchar(400), @TerritoryINSERT varchar(400), @GroupSpecialty1INSERT varchar(400), @GroupSpecialty2INSERT varchar(400), @Specialty1INSERT varchar(400), @Specialty2INSERT varchar(400), @ID2INSERT varchar(400), @DoNotCallINSERT varchar(400), @PDRPOptOutINSERT varchar(400), @PDRPOptOutDateINSERT varchar(400), @PrimaryParentINSERT varchar(400), @MiddleINSERT varchar(400), @SuffixINSERT varchar(400), @NPIINSERT varchar(400), @MEcINSERT varchar(400), @AccountTypecINSERT varchar(400), @HospitalTypeINSERT varchar(400), @AccountClassINSERT varchar(400), @CNXAddresscINSERT varchar(400), @CNXCRMIDcINSERT varchar(400), @CNXDecilecINSERT varchar(400), @CNXFieldPhonecINSERT varchar(400), @CNXRolecINSERT varchar(400), @CNXTargetTypecINSERT varchar(400),  
				@NameDELETE varchar(400), @LastNameDELETE varchar(400), @FirstNameDELETE varchar(400), @SalutationDELETE varchar(400), @RecordTypeIdDELETE varchar(400), @ParentIdDELETE varchar(400), @PhoneDELETE varchar(400), @WebsiteDELETE varchar(400), @PersonContactIdDELETE varchar(400), @IsPersonAccountDELETE varchar(400), @PersonEmailDELETE varchar(400), @PersonBirthdateDELETE varchar(400), @AccountSourceDELETE varchar(400), @TerritoryDELETE varchar(400), @GroupSpecialty1DELETE varchar(400), @GroupSpecialty2DELETE varchar(400), @Specialty1DELETE varchar(400), @Specialty2DELETE varchar(400), @ID2DELETE varchar(400), @DoNotCallDELETE varchar(400), @PDRPOptOutDELETE varchar(400), @PDRPOptOutDateDELETE varchar(400), @PrimaryParentDELETE varchar(400), @MiddleDELETE varchar(400), @SuffixDELETE varchar(400), @NPIDELETE varchar(400), @MEcDELETE varchar(400), @AccountTypecDELETE varchar(400), @HospitalTypeDELETE varchar(400), @AccountClassDELETE varchar(400), @CNXAddresscDELETE varchar(400), @CNXCRMIDcDELETE varchar(400), @CNXDecilecDELETE varchar(400), @CNXFieldPhonecDELETE varchar(400), @CNXRolecDELETE varchar(400), @CNXTargetTypecDELETE varchar(400), 
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = AccountId, @NameINSERT = Name, @LastNameINSERT = LastName, @FirstNameINSERT = FirstName, @SalutationINSERT = Salutation, @RecordTypeIdINSERT = RecordTypeId, @ParentIdINSERT = ParentId, @PhoneINSERT = Phone, @WebsiteINSERT = Website, @PersonContactIdINSERT = PersonContactId, @IsPersonAccountINSERT = IsPersonAccount, @PersonEmailINSERT = PersonEmail, @PersonBirthdateINSERT = PersonBirthdate, @AccountSourceINSERT = AccountSource, @TerritoryINSERT = Territory, @GroupSpecialty1INSERT = GroupSpecialty1, @GroupSpecialty2INSERT = GroupSpecialty2, @Specialty1INSERT = Specialty1, @Specialty2INSERT = Specialty2, @ID2INSERT = ID2, @DoNotCallINSERT = DoNotCall, @PDRPOptOutINSERT = PDRPOptOut, @PDRPOptOutDateINSERT = PDRPOptOutDate, @PrimaryParentINSERT = PrimaryParent, @MiddleINSERT = Middle, @SuffixINSERT = Suffix, @NPIINSERT = NPI, @MEcINSERT = MEc, @AccountTypecINSERT = AccountTypec, @HospitalTypeINSERT = HospitalType, @AccountClassINSERT = AccountClass, @CNXAddresscINSERT = CNXAddressc, @CNXCRMIDcINSERT = CNXCRMIDc, @CNXDecilecINSERT = CNXDecilec, @CNXFieldPhonecINSERT = CNXFieldPhonec, @CNXRolecINSERT = CNXRolec, @CNXTargetTypecINSERT = CNXTargetTypec
				from #insertedUPDATE;

				SELECT
					@NameDELETE = Name, @LastNameDELETE = LastName, @FirstNameDELETE = FirstName, @SalutationDELETE = Salutation, @RecordTypeIdDELETE = RecordTypeId, @ParentIdDELETE = ParentId, @PhoneDELETE = Phone, @WebsiteDELETE = Website, @PersonContactIdDELETE = PersonContactId, @IsPersonAccountDELETE = IsPersonAccount, @PersonEmailDELETE = PersonEmail, @PersonBirthdateDELETE = PersonBirthdate, @AccountSourceDELETE = AccountSource, @TerritoryDELETE = Territory, @GroupSpecialty1DELETE = GroupSpecialty1, @GroupSpecialty2DELETE = GroupSpecialty2, @Specialty1DELETE = Specialty1, @Specialty2DELETE = Specialty2, @ID2DELETE = ID2, @DoNotCallDELETE = DoNotCall, @PDRPOptOutDELETE = PDRPOptOut, @PDRPOptOutDateDELETE = PDRPOptOutDate, @PrimaryParentDELETE = PrimaryParent, @MiddleDELETE = Middle, @SuffixDELETE = Suffix, @NPIDELETE = NPI, @MEcDELETE = MEc, @AccountTypecDELETE = AccountTypec, @HospitalTypeDELETE = HospitalType, @AccountClassDELETE = AccountClass, @CNXAddresscDELETE = CNXAddressc, @CNXCRMIDcDELETE = CNXCRMIDc, @CNXDecilecDELETE = CNXDecilec, @CNXFieldPhonecDELETE = CNXFieldPhonec, @CNXRolecDELETE = CNXRolec, @CNXTargetTypecDELETE = CNXTargetTypec
				from #deleted WHERE AccountId = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					@NameINSERT <> @NameDELETE OR (@NameINSERT IS NULL AND @NameDELETE IS NOT NULL) OR (@NameINSERT IS NOT NULL AND @NameDELETE IS NULL) OR @LastNameINSERT <> @LastNameDELETE OR (@LastNameINSERT IS NULL AND @LastNameDELETE IS NOT NULL) OR (@LastNameINSERT IS NOT NULL AND @LastNameDELETE IS NULL) OR @FirstNameINSERT <> @FirstNameDELETE OR (@FirstNameINSERT IS NULL AND @FirstNameDELETE IS NOT NULL) OR (@FirstNameINSERT IS NOT NULL AND @FirstNameDELETE IS NULL) OR @SalutationINSERT <> @SalutationDELETE OR (@SalutationINSERT IS NULL AND @SalutationDELETE IS NOT NULL) OR (@SalutationINSERT IS NOT NULL AND @SalutationDELETE IS NULL) OR @RecordTypeIdINSERT <> @RecordTypeIdDELETE OR (@RecordTypeIdINSERT IS NULL AND @RecordTypeIdDELETE IS NOT NULL) OR (@RecordTypeIdINSERT IS NOT NULL AND @RecordTypeIdDELETE IS NULL) OR @ParentIdINSERT <> @ParentIdDELETE OR (@ParentIdINSERT IS NULL AND @ParentIdDELETE IS NOT NULL) OR (@ParentIdINSERT IS NOT NULL AND @ParentIdDELETE IS NULL) OR @PhoneINSERT <> @PhoneDELETE OR (@PhoneINSERT IS NULL AND @PhoneDELETE IS NOT NULL) OR (@PhoneINSERT IS NOT NULL AND @PhoneDELETE IS NULL) OR @WebsiteINSERT <> @WebsiteDELETE OR (@WebsiteINSERT IS NULL AND @WebsiteDELETE IS NOT NULL) OR (@WebsiteINSERT IS NOT NULL AND @WebsiteDELETE IS NULL) OR @PersonContactIdINSERT <> @PersonContactIdDELETE OR (@PersonContactIdINSERT IS NULL AND @PersonContactIdDELETE IS NOT NULL) OR (@PersonContactIdINSERT IS NOT NULL AND @PersonContactIdDELETE IS NULL) OR @IsPersonAccountINSERT <> @IsPersonAccountDELETE OR (@IsPersonAccountINSERT IS NULL AND @IsPersonAccountDELETE IS NOT NULL) OR (@IsPersonAccountINSERT IS NOT NULL AND @IsPersonAccountDELETE IS NULL) OR @PersonEmailINSERT <> @PersonEmailDELETE OR (@PersonEmailINSERT IS NULL AND @PersonEmailDELETE IS NOT NULL) OR (@PersonEmailINSERT IS NOT NULL AND @PersonEmailDELETE IS NULL) OR @PersonBirthdateINSERT <> @PersonBirthdateDELETE OR (@PersonBirthdateINSERT IS NULL AND @PersonBirthdateDELETE IS NOT NULL) OR (@PersonBirthdateINSERT IS NOT NULL AND @PersonBirthdateDELETE IS NULL) OR @AccountSourceINSERT <> @AccountSourceDELETE OR (@AccountSourceINSERT IS NULL AND @AccountSourceDELETE IS NOT NULL) OR (@AccountSourceINSERT IS NOT NULL AND @AccountSourceDELETE IS NULL) OR @TerritoryINSERT <> @TerritoryDELETE OR (@TerritoryINSERT IS NULL AND @TerritoryDELETE IS NOT NULL) OR (@TerritoryINSERT IS NOT NULL AND @TerritoryDELETE IS NULL) OR @GroupSpecialty1INSERT <> @GroupSpecialty1DELETE OR (@GroupSpecialty1INSERT IS NULL AND @GroupSpecialty1DELETE IS NOT NULL) OR (@GroupSpecialty1INSERT IS NOT NULL AND @GroupSpecialty1DELETE IS NULL) OR @GroupSpecialty2INSERT <> @GroupSpecialty2DELETE OR (@GroupSpecialty2INSERT IS NULL AND @GroupSpecialty2DELETE IS NOT NULL) OR (@GroupSpecialty2INSERT IS NOT NULL AND @GroupSpecialty2DELETE IS NULL) OR @Specialty1INSERT <> @Specialty1DELETE OR (@Specialty1INSERT IS NULL AND @Specialty1DELETE IS NOT NULL) OR (@Specialty1INSERT IS NOT NULL AND @Specialty1DELETE IS NULL) OR @Specialty2INSERT <> @Specialty2DELETE OR (@Specialty2INSERT IS NULL AND @Specialty2DELETE IS NOT NULL) OR (@Specialty2INSERT IS NOT NULL AND @Specialty2DELETE IS NULL) OR @ID2INSERT <> @ID2DELETE OR (@ID2INSERT IS NULL AND @ID2DELETE IS NOT NULL) OR (@ID2INSERT IS NOT NULL AND @ID2DELETE IS NULL) OR @DoNotCallINSERT <> @DoNotCallDELETE OR (@DoNotCallINSERT IS NULL AND @DoNotCallDELETE IS NOT NULL) OR (@DoNotCallINSERT IS NOT NULL AND @DoNotCallDELETE IS NULL) OR @PDRPOptOutINSERT <> @PDRPOptOutDELETE OR (@PDRPOptOutINSERT IS NULL AND @PDRPOptOutDELETE IS NOT NULL) OR (@PDRPOptOutINSERT IS NOT NULL AND @PDRPOptOutDELETE IS NULL) OR @PDRPOptOutDateINSERT <> @PDRPOptOutDateDELETE OR (@PDRPOptOutDateINSERT IS NULL AND @PDRPOptOutDateDELETE IS NOT NULL) OR (@PDRPOptOutDateINSERT IS NOT NULL AND @PDRPOptOutDateDELETE IS NULL) OR @PrimaryParentINSERT <> @PrimaryParentDELETE OR (@PrimaryParentINSERT IS NULL AND @PrimaryParentDELETE IS NOT NULL) OR (@PrimaryParentINSERT IS NOT NULL AND @PrimaryParentDELETE IS NULL) OR @MiddleINSERT <> @MiddleDELETE OR (@MiddleINSERT IS NULL AND @MiddleDELETE IS NOT NULL) OR (@MiddleINSERT IS NOT NULL AND @MiddleDELETE IS NULL) OR @SuffixINSERT <> @SuffixDELETE OR (@SuffixINSERT IS NULL AND @SuffixDELETE IS NOT NULL) OR (@SuffixINSERT IS NOT NULL AND @SuffixDELETE IS NULL) OR @NPIINSERT <> @NPIDELETE OR (@NPIINSERT IS NULL AND @NPIDELETE IS NOT NULL) OR (@NPIINSERT IS NOT NULL AND @NPIDELETE IS NULL) OR @MEcINSERT <> @MEcDELETE OR (@MEcINSERT IS NULL AND @MEcDELETE IS NOT NULL) OR (@MEcINSERT IS NOT NULL AND @MEcDELETE IS NULL) OR @AccountTypecINSERT <> @AccountTypecDELETE OR (@AccountTypecINSERT IS NULL AND @AccountTypecDELETE IS NOT NULL) OR (@AccountTypecINSERT IS NOT NULL AND @AccountTypecDELETE IS NULL) OR @HospitalTypeINSERT <> @HospitalTypeDELETE OR (@HospitalTypeINSERT IS NULL AND @HospitalTypeDELETE IS NOT NULL) OR (@HospitalTypeINSERT IS NOT NULL AND @HospitalTypeDELETE IS NULL) OR @AccountClassINSERT <> @AccountClassDELETE OR (@AccountClassINSERT IS NULL AND @AccountClassDELETE IS NOT NULL) OR (@AccountClassINSERT IS NOT NULL AND @AccountClassDELETE IS NULL) OR @CNXAddresscINSERT <> @CNXAddresscDELETE OR (@CNXAddresscINSERT IS NULL AND @CNXAddresscDELETE IS NOT NULL) OR (@CNXAddresscINSERT IS NOT NULL AND @CNXAddresscDELETE IS NULL) OR @CNXCRMIDcINSERT <> @CNXCRMIDcDELETE OR (@CNXCRMIDcINSERT IS NULL AND @CNXCRMIDcDELETE IS NOT NULL) OR (@CNXCRMIDcINSERT IS NOT NULL AND @CNXCRMIDcDELETE IS NULL) OR @CNXDecilecINSERT <> @CNXDecilecDELETE OR (@CNXDecilecINSERT IS NULL AND @CNXDecilecDELETE IS NOT NULL) OR (@CNXDecilecINSERT IS NOT NULL AND @CNXDecilecDELETE IS NULL) OR @CNXFieldPhonecINSERT <> @CNXFieldPhonecDELETE OR (@CNXFieldPhonecINSERT IS NULL AND @CNXFieldPhonecDELETE IS NOT NULL) OR (@CNXFieldPhonecINSERT IS NOT NULL AND @CNXFieldPhonecDELETE IS NULL) OR @CNXRolecINSERT <> @CNXRolecDELETE OR (@CNXRolecINSERT IS NULL AND @CNXRolecDELETE IS NOT NULL) OR (@CNXRolecINSERT IS NOT NULL AND @CNXRolecDELETE IS NULL) OR @CNXTargetTypecINSERT <> @CNXTargetTypecDELETE OR (@CNXTargetTypecINSERT IS NULL AND @CNXTargetTypecDELETE IS NOT NULL) OR (@CNXTargetTypecINSERT IS NOT NULL AND @CNXTargetTypecDELETE IS NULL)
					BEGIN
						UPDATE [Account] SET EndDate = GETDATE() WHERE AccountId = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [Account](CreatedDate, UpdatedDate, ExternalId1, AccountId, IsDeleted, MasterRecordId, Name, LastName, FirstName, Salutation, RecordTypeId, ParentId, Phone, Fax, Website, NumberOfEmployees, Ownership, OwnerId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, PersonContactId, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonOtherStreet, PersonOtherCity, PersonOtherState, PersonOtherPostalCode, PersonOtherCountry, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, PersonAssistantPhone, PersonEmail, PersonTitle, PersonDepartment, PersonAssistantName, PersonBirthdate, PersonHasOptedOutOfEmail, PersonHasOptedOutOfFax, PersonDoNotCall, PersonLastCURequestDate, PersonLastCUUpdateDate, PersonEmailBouncedReason, PersonEmailBouncedDate, PersonIndividualId, AccountSource, ExternalID, Credentials, Territory, ExcludefromZiptoTerrProcessing, GroupSpecialty1, GroupSpecialty2, Specialty1, Specialty2, FormattedName, TerritoryTest, MobileID, Gender, ExternalId2, DoNotSyncSalesData, ID2, PreferredName, SampleDefault, Segmentations, RestrictedProducts, PayerId, AlternateName, DoNotCall, Bedsc, SpendAmountc, PDRPOptOut, SpendStatusValue, PDRPOptOutDate, SpendStatus, EnableRestrictedProducts, CallReminder, AccountGroup, PrimaryParent, Color, Middle, Suffix, NoOrders, AccountIdentifier, ApprovedEmailOptType, AccountSearchFirstLast, AccountSearchLastFirst, Language, PracticeatHospital, PracticeNearHospital, DoNotCreateChildAccount, TotalMDsDOsc, AHAc, OrderType, NPI, MEc, Speakerc, Investigator, DefaultOrderType, TaxStatusc, Modelc, Offeringsc, Departmentsc, AccountTypec, AccountSearchBusiness, BusinessProfessionalPerson, HospitalType, AccountClass, Furigana, TotalRevenue000c, NetIncomeLoss000c, PMPMIncomeLoss000c, CommercialPremiumsPMPMc, MedicalLossRatioc, MedicalExpensesPMPMc, CommercialPatientDays1000c, HMOMarketShrc, HMOc, HMOPOSc, PPOc, PPOPOSc, Medicarec, Medicaidc, BusinessDescriptionc, RegionalStrategyc, ContractsProcessc, Targetc, KOL, TotalLivesc, TotalPhysiciansEnrolledc, TotalPharmacistsc, CNXAddressc, CNXCRMIDc, CNXDecilec, CNXFieldEmailc, CNXFieldPhonec, CNXPreferredMethodOfContactc, CNXRolec, CNXTargetMSLc, CNXTargetSSc, CNXTargetTypec, MobileIDvodpc, EndDate)
						SELECT CreatedDate, UpdatedDate, ExternalId1, AccountId, IsDeleted, MasterRecordId, Name, LastName, FirstName, Salutation, RecordTypeId, ParentId, Phone, Fax, Website, NumberOfEmployees, Ownership, OwnerId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, PersonContactId, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonOtherStreet, PersonOtherCity, PersonOtherState, PersonOtherPostalCode, PersonOtherCountry, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, PersonAssistantPhone, PersonEmail, PersonTitle, PersonDepartment, PersonAssistantName, PersonBirthdate, PersonHasOptedOutOfEmail, PersonHasOptedOutOfFax, PersonDoNotCall, PersonLastCURequestDate, PersonLastCUUpdateDate, PersonEmailBouncedReason, PersonEmailBouncedDate, PersonIndividualId, AccountSource, ExternalID, Credentials, Territory, ExcludefromZiptoTerrProcessing, GroupSpecialty1, GroupSpecialty2, Specialty1, Specialty2, FormattedName, TerritoryTest, MobileID, Gender, ExternalId2, DoNotSyncSalesData, ID2, PreferredName, SampleDefault, Segmentations, RestrictedProducts, PayerId, AlternateName, DoNotCall, Bedsc, SpendAmountc, PDRPOptOut, SpendStatusValue, PDRPOptOutDate, SpendStatus, EnableRestrictedProducts, CallReminder, AccountGroup, PrimaryParent, Color, Middle, Suffix, NoOrders, AccountIdentifier, ApprovedEmailOptType, AccountSearchFirstLast, AccountSearchLastFirst, Language, PracticeatHospital, PracticeNearHospital, DoNotCreateChildAccount, TotalMDsDOsc, AHAc, OrderType, NPI, MEc, Speakerc, Investigator, DefaultOrderType, TaxStatusc, Modelc, Offeringsc, Departmentsc, AccountTypec, AccountSearchBusiness, BusinessProfessionalPerson, HospitalType, AccountClass, Furigana, TotalRevenue000c, NetIncomeLoss000c, PMPMIncomeLoss000c, CommercialPremiumsPMPMc, MedicalLossRatioc, MedicalExpensesPMPMc, CommercialPatientDays1000c, HMOMarketShrc, HMOc, HMOPOSc, PPOc, PPOPOSc, Medicarec, Medicaidc, BusinessDescriptionc, RegionalStrategyc, ContractsProcessc, Targetc, KOL, TotalLivesc, TotalPhysiciansEnrolledc, TotalPharmacistsc, CNXAddressc, CNXCRMIDc, CNXDecilec, CNXFieldEmailc, CNXFieldPhonec, CNXPreferredMethodOfContactc, CNXRolec, CNXTargetMSLc, CNXTargetSSc, CNXTargetTypec, MobileIDvodpc, CASE WHEN IsDeleted = 'True' THEN GETDATE() END
						FROM #insertedUPDATE WHERE AccountId = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET T.CreatedDate = I.CreatedDate
						 , T.UpdatedDate = I.UpdatedDate
						 , T.ExternalId1 = I.ExternalId1
						 , T.IsDeleted = I.IsDeleted
						 , T.MasterRecordId = I.MasterRecordId
						 , T.Fax = I.Fax
						 , T.NumberOfEmployees = I.NumberOfEmployees
						 , T.Ownership = I.Ownership
						 , T.OwnerId = I.OwnerId
						 , T.VeevaCreatedDate = I.VeevaCreatedDate
						 , T.VeevaCreatedById = I.VeevaCreatedById
						 , T.LastModifiedDate = I.LastModifiedDate
						 , T.LastModifiedById = I.LastModifiedById
						 , T.SystemModstamp = I.SystemModstamp
						 , T.LastActivityDate = I.LastActivityDate
						 , T.MayEdit = I.MayEdit
						 , T.IsLocked = I.IsLocked
						 , T.LastViewedDate = I.LastViewedDate
						 , T.LastReferencedDate = I.LastReferencedDate
						 , T.PersonMailingStreet = I.PersonMailingStreet
						 , T.PersonMailingCity = I.PersonMailingCity
						 , T.PersonMailingState = I.PersonMailingState
						 , T.PersonMailingPostalCode = I.PersonMailingPostalCode
						 , T.PersonMailingCountry = I.PersonMailingCountry
						 , T.PersonOtherStreet = I.PersonOtherStreet
						 , T.PersonOtherCity = I.PersonOtherCity
						 , T.PersonOtherState = I.PersonOtherState
						 , T.PersonOtherPostalCode = I.PersonOtherPostalCode
						 , T.PersonOtherCountry = I.PersonOtherCountry
						 , T.PersonMobilePhone = I.PersonMobilePhone
						 , T.PersonHomePhone = I.PersonHomePhone
						 , T.PersonOtherPhone = I.PersonOtherPhone
						 , T.PersonAssistantPhone = I.PersonAssistantPhone
						 , T.PersonTitle = I.PersonTitle
						 , T.PersonDepartment = I.PersonDepartment
						 , T.PersonAssistantName = I.PersonAssistantName
						 , T.PersonHasOptedOutOfEmail = I.PersonHasOptedOutOfEmail
						 , T.PersonHasOptedOutOfFax = I.PersonHasOptedOutOfFax
						 , T.PersonDoNotCall = I.PersonDoNotCall
						 , T.PersonLastCURequestDate = I.PersonLastCURequestDate
						 , T.PersonLastCUUpdateDate = I.PersonLastCUUpdateDate
						 , T.PersonEmailBouncedReason = I.PersonEmailBouncedReason
						 , T.PersonEmailBouncedDate = I.PersonEmailBouncedDate
						 , T.PersonIndividualId = I.PersonIndividualId
						 , T.ExternalID = I.ExternalID
						 , T.Credentials = I.Credentials
						 , T.ExcludefromZiptoTerrProcessing = I.ExcludefromZiptoTerrProcessing
						 , T.FormattedName = I.FormattedName
						 , T.TerritoryTest = I.TerritoryTest
						 , T.MobileID = I.MobileID
						 , T.Gender = I.Gender
						 , T.ExternalId2 = I.ExternalId2
						 , T.DoNotSyncSalesData = I.DoNotSyncSalesData
						 , T.PreferredName = I.PreferredName
						 , T.SampleDefault = I.SampleDefault
						 , T.Segmentations = I.Segmentations
						 , T.RestrictedProducts = I.RestrictedProducts
						 , T.PayerId = I.PayerId
						 , T.AlternateName = I.AlternateName
						 , T.Bedsc = I.Bedsc
						 , T.SpendAmountc = I.SpendAmountc
						 , T.SpendStatusValue = I.SpendStatusValue
						 , T.SpendStatus = I.SpendStatus
						 , T.EnableRestrictedProducts = I.EnableRestrictedProducts
						 , T.CallReminder = I.CallReminder
						 , T.AccountGroup = I.AccountGroup
						 , T.Color = I.Color
						 , T.NoOrders = I.NoOrders
						 , T.AccountIdentifier = I.AccountIdentifier
						 , T.ApprovedEmailOptType = I.ApprovedEmailOptType
						 , T.AccountSearchFirstLast = I.AccountSearchFirstLast
						 , T.AccountSearchLastFirst = I.AccountSearchLastFirst
						 , T.Language = I.Language
						 , T.PracticeatHospital = I.PracticeatHospital
						 , T.PracticeNearHospital = I.PracticeNearHospital
						 , T.DoNotCreateChildAccount = I.DoNotCreateChildAccount
						 , T.TotalMDsDOsc = I.TotalMDsDOsc
						 , T.AHAc = I.AHAc
						 , T.OrderType = I.OrderType
						 , T.Speakerc = I.Speakerc
						 , T.Investigator = I.Investigator
						 , T.DefaultOrderType = I.DefaultOrderType
						 , T.TaxStatusc = I.TaxStatusc
						 , T.Modelc = I.Modelc
						 , T.Offeringsc = I.Offeringsc
						 , T.Departmentsc = I.Departmentsc
						 , T.AccountSearchBusiness = I.AccountSearchBusiness
						 , T.BusinessProfessionalPerson = I.BusinessProfessionalPerson
						 , T.Furigana = I.Furigana
						 , T.TotalRevenue000c = I.TotalRevenue000c
						 , T.NetIncomeLoss000c = I.NetIncomeLoss000c
						 , T.PMPMIncomeLoss000c = I.PMPMIncomeLoss000c
						 , T.CommercialPremiumsPMPMc = I.CommercialPremiumsPMPMc
						 , T.MedicalLossRatioc = I.MedicalLossRatioc
						 , T.MedicalExpensesPMPMc = I.MedicalExpensesPMPMc
						 , T.CommercialPatientDays1000c = I.CommercialPatientDays1000c
						 , T.HMOMarketShrc = I.HMOMarketShrc
						 , T.HMOc = I.HMOc
						 , T.HMOPOSc = I.HMOPOSc
						 , T.PPOc = I.PPOc
						 , T.PPOPOSc = I.PPOPOSc
						 , T.Medicarec = I.Medicarec
						 , T.Medicaidc = I.Medicaidc
						 , T.BusinessDescriptionc = I.BusinessDescriptionc
						 , T.RegionalStrategyc = I.RegionalStrategyc
						 , T.ContractsProcessc = I.ContractsProcessc
						 , T.Targetc = I.Targetc
						 , T.KOL = I.KOL
						 , T.TotalLivesc = I.TotalLivesc
						 , T.TotalPhysiciansEnrolledc = I.TotalPhysiciansEnrolledc
						 , T.TotalPharmacistsc = I.TotalPharmacistsc
						 , T.CNXFieldEmailc = I.CNXFieldEmailc
						 , T.CNXPreferredMethodOfContactc = I.CNXPreferredMethodOfContactc
						 , T.CNXTargetMSLc = I.CNXTargetMSLc
						 , T.CNXTargetSSc = I.CNXTargetSSc
						 , T.MobileIDvodpc = I.MobileIDvodpc, T.EndDate = CASE WHEN I.IsDeleted = 'True' THEN GETDATE() END 
					FROM [Account] T INNER JOIN #insertedUPDATE I ON T.AccountId = I.AccountId AND I.AccountId = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where AccountId = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [Account](CreatedDate, UpdatedDate, ExternalId1, AccountId, IsDeleted, MasterRecordId, Name, LastName, FirstName, Salutation, RecordTypeId, ParentId, Phone, Fax, Website, NumberOfEmployees, Ownership, OwnerId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, PersonContactId, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonOtherStreet, PersonOtherCity, PersonOtherState, PersonOtherPostalCode, PersonOtherCountry, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, PersonAssistantPhone, PersonEmail, PersonTitle, PersonDepartment, PersonAssistantName, PersonBirthdate, PersonHasOptedOutOfEmail, PersonHasOptedOutOfFax, PersonDoNotCall, PersonLastCURequestDate, PersonLastCUUpdateDate, PersonEmailBouncedReason, PersonEmailBouncedDate, PersonIndividualId, AccountSource, ExternalID, Credentials, Territory, ExcludefromZiptoTerrProcessing, GroupSpecialty1, GroupSpecialty2, Specialty1, Specialty2, FormattedName, TerritoryTest, MobileID, Gender, ExternalId2, DoNotSyncSalesData, ID2, PreferredName, SampleDefault, Segmentations, RestrictedProducts, PayerId, AlternateName, DoNotCall, Bedsc, SpendAmountc, PDRPOptOut, SpendStatusValue, PDRPOptOutDate, SpendStatus, EnableRestrictedProducts, CallReminder, AccountGroup, PrimaryParent, Color, Middle, Suffix, NoOrders, AccountIdentifier, ApprovedEmailOptType, AccountSearchFirstLast, AccountSearchLastFirst, Language, PracticeatHospital, PracticeNearHospital, DoNotCreateChildAccount, TotalMDsDOsc, AHAc, OrderType, NPI, MEc, Speakerc, Investigator, DefaultOrderType, TaxStatusc, Modelc, Offeringsc, Departmentsc, AccountTypec, AccountSearchBusiness, BusinessProfessionalPerson, HospitalType, AccountClass, Furigana, TotalRevenue000c, NetIncomeLoss000c, PMPMIncomeLoss000c, CommercialPremiumsPMPMc, MedicalLossRatioc, MedicalExpensesPMPMc, CommercialPatientDays1000c, HMOMarketShrc, HMOc, HMOPOSc, PPOc, PPOPOSc, Medicarec, Medicaidc, BusinessDescriptionc, RegionalStrategyc, ContractsProcessc, Targetc, KOL, TotalLivesc, TotalPhysiciansEnrolledc, TotalPharmacistsc, CNXAddressc, CNXCRMIDc, CNXDecilec, CNXFieldEmailc, CNXFieldPhonec, CNXPreferredMethodOfContactc, CNXRolec, CNXTargetMSLc, CNXTargetSSc, CNXTargetTypec, MobileIDvodpc, EndDate)
				SELECT CreatedDate, UpdatedDate, ExternalId1, AccountId, IsDeleted, MasterRecordId, Name, LastName, FirstName, Salutation, RecordTypeId, ParentId, Phone, Fax, Website, NumberOfEmployees, Ownership, OwnerId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, PersonContactId, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonOtherStreet, PersonOtherCity, PersonOtherState, PersonOtherPostalCode, PersonOtherCountry, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, PersonAssistantPhone, PersonEmail, PersonTitle, PersonDepartment, PersonAssistantName, PersonBirthdate, PersonHasOptedOutOfEmail, PersonHasOptedOutOfFax, PersonDoNotCall, PersonLastCURequestDate, PersonLastCUUpdateDate, PersonEmailBouncedReason, PersonEmailBouncedDate, PersonIndividualId, AccountSource, ExternalID, Credentials, Territory, ExcludefromZiptoTerrProcessing, GroupSpecialty1, GroupSpecialty2, Specialty1, Specialty2, FormattedName, TerritoryTest, MobileID, Gender, ExternalId2, DoNotSyncSalesData, ID2, PreferredName, SampleDefault, Segmentations, RestrictedProducts, PayerId, AlternateName, DoNotCall, Bedsc, SpendAmountc, PDRPOptOut, SpendStatusValue, PDRPOptOutDate, SpendStatus, EnableRestrictedProducts, CallReminder, AccountGroup, PrimaryParent, Color, Middle, Suffix, NoOrders, AccountIdentifier, ApprovedEmailOptType, AccountSearchFirstLast, AccountSearchLastFirst, Language, PracticeatHospital, PracticeNearHospital, DoNotCreateChildAccount, TotalMDsDOsc, AHAc, OrderType, NPI, MEc, Speakerc, Investigator, DefaultOrderType, TaxStatusc, Modelc, Offeringsc, Departmentsc, AccountTypec, AccountSearchBusiness, BusinessProfessionalPerson, HospitalType, AccountClass, Furigana, TotalRevenue000c, NetIncomeLoss000c, PMPMIncomeLoss000c, CommercialPremiumsPMPMc, MedicalLossRatioc, MedicalExpensesPMPMc, CommercialPatientDays1000c, HMOMarketShrc, HMOc, HMOPOSc, PPOc, PPOPOSc, Medicarec, Medicaidc, BusinessDescriptionc, RegionalStrategyc, ContractsProcessc, Targetc, KOL, TotalLivesc, TotalPhysiciansEnrolledc, TotalPharmacistsc, CNXAddressc, CNXCRMIDc, CNXDecilec, CNXFieldEmailc, CNXFieldPhonec, CNXPreferredMethodOfContactc, CNXRolec, CNXTargetMSLc, CNXTargetSSc, CNXTargetTypec, MobileIDvodpc, CASE WHEN IsDeleted = 'True' THEN GETDATE() END FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [Account] SET EndDate = GETDATE() WHERE AccountId IN (SELECT AccountId FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END


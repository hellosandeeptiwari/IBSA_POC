CREATE TABLE [dbo].[AccountAddress] (
    [Id]                           INT              IDENTITY (1, 1) NOT NULL,
    [EndDate]                      DATETIME         NULL,
    [CreatedDate]                  DATETIME         NULL,
    [UpdatedDate]                  DATETIME         NULL,
    [ExternalId1]                  VARCHAR (400)    NULL,
    [AccountAddressId]             UNIQUEIDENTIFIER NULL,
    [IsDeleted]                    VARCHAR (400)    NULL,
    [Name]                         VARCHAR (400)    NULL,
    [RecordTypeId]                 VARCHAR (400)    NULL,
    [VeevaCreatedDate]             VARCHAR (400)    NULL,
    [VeevaCreatedById]             VARCHAR (400)    NULL,
    [LastModifiedDate]             VARCHAR (400)    NULL,
    [LastModifiedById]             VARCHAR (400)    NULL,
    [SystemModstamp]               VARCHAR (400)    NULL,
    [MayEdit]                      VARCHAR (400)    NULL,
    [IsLocked]                     VARCHAR (400)    NULL,
    [Account]                      VARCHAR (400)    NULL,
    [Addressline2]                 VARCHAR (400)    NULL,
    [City]                         VARCHAR (400)    NULL,
    [ExternalID]                   VARCHAR (400)    NULL,
    [DEA]                          VARCHAR (400)    NULL,
    [DEAExpirationDate]            VARCHAR (400)    NULL,
    [DEALicenseAddress]            VARCHAR (400)    NULL,
    [Phone]                        VARCHAR (400)    NULL,
    [Fax]                          VARCHAR (400)    NULL,
    [Map]                          VARCHAR (400)    NULL,
    [Shipping]                     VARCHAR (400)    NULL,
    [IsPrimary]                    VARCHAR (400)    NULL,
    [License]                      VARCHAR (400)    NULL,
    [LicenseExpirationDate]        VARCHAR (400)    NULL,
    [LicenseStatus]                VARCHAR (400)    NULL,
    [Zip4]                         VARCHAR (400)    NULL,
    [Phone2]                       VARCHAR (400)    NULL,
    [Fax2]                         VARCHAR (400)    NULL,
    [LicenseValidToSample]         VARCHAR (400)    NULL,
    [SampleStatus]                 VARCHAR (400)    NULL,
    [IncludeinTerritoryAssignment] VARCHAR (400)    NULL,
    [MobileID]                     VARCHAR (400)    NULL,
    [Inactive]                     VARCHAR (400)    NULL,
    [Lock]                         VARCHAR (400)    NULL,
    [Country]                      VARCHAR (400)    NULL,
    [Zip]                          VARCHAR (400)    NULL,
    [Source]                       VARCHAR (400)    NULL,
    [Brick]                        VARCHAR (400)    NULL,
    [ASSMCA]                       VARCHAR (400)    NULL,
    [DEAAddress]                   VARCHAR (400)    NULL,
    [DEASchedule]                  VARCHAR (400)    NULL,
    [Business]                     VARCHAR (400)    NULL,
    [Billing]                      VARCHAR (400)    NULL,
    [Home]                         VARCHAR (400)    NULL,
    [Mailing]                      VARCHAR (400)    NULL,
    [State]                        VARCHAR (400)    NULL,
    [DEAStatus]                    VARCHAR (400)    NULL,
    [EntityReferenceId]            VARCHAR (400)    NULL,
    [ControllingAddress]           VARCHAR (400)    NULL,
    [ControlledAddress]            VARCHAR (400)    NULL,
    [NoAddressCopy]                VARCHAR (400)    NULL,
    [SampleSendStatus]             VARCHAR (400)    NULL,
    [CRMIDc]                       VARCHAR (400)    NULL,
    [StartDate]                    DATETIME         NULL,
    CONSTRAINT [PK_AccountAddress] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AccountAddress_EndDate]
    ON [dbo].[AccountAddress]([EndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AccountAddress_Account]
    ON [dbo].[AccountAddress]([Account] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AccountAddress_ExternalId1]
    ON [dbo].[AccountAddress]([ExternalId1] ASC);


GO
CREATE TRIGGER [dbo].[trg_AccountAddress] on [dbo].[AccountAddress] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT AccountAddressId, Name, Account, Addressline2, City, DEA, DEAExpirationDate, DEALicenseAddress, Phone, Fax, IsPrimary, License, LicenseExpirationDate, LicenseStatus, Zip4, Phone2, Fax2, LicenseValidToSample, SampleStatus, Inactive, Zip, State, DEAStatus into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare @NameINSERT varchar(400), @AccountINSERT varchar(400), @Addressline2INSERT varchar(400), @CityINSERT varchar(400), @DEAINSERT varchar(400), @DEAExpirationDateINSERT varchar(400), @DEALicenseAddressINSERT varchar(400), @PhoneINSERT varchar(400), @FaxINSERT varchar(400), @IsPrimaryINSERT varchar(400), @LicenseINSERT varchar(400), @LicenseExpirationDateINSERT varchar(400), @LicenseStatusINSERT varchar(400), @Zip4INSERT varchar(400), @Phone2INSERT varchar(400), @Fax2INSERT varchar(400), @LicenseValidToSampleINSERT varchar(400), @SampleStatusINSERT varchar(400), @InactiveINSERT varchar(400), @ZipINSERT varchar(400), @StateINSERT varchar(400), @DEAStatusINSERT varchar(400),  
				@NameDELETE varchar(400), @AccountDELETE varchar(400), @Addressline2DELETE varchar(400), @CityDELETE varchar(400), @DEADELETE varchar(400), @DEAExpirationDateDELETE varchar(400), @DEALicenseAddressDELETE varchar(400), @PhoneDELETE varchar(400), @FaxDELETE varchar(400), @IsPrimaryDELETE varchar(400), @LicenseDELETE varchar(400), @LicenseExpirationDateDELETE varchar(400), @LicenseStatusDELETE varchar(400), @Zip4DELETE varchar(400), @Phone2DELETE varchar(400), @Fax2DELETE varchar(400), @LicenseValidToSampleDELETE varchar(400), @SampleStatusDELETE varchar(400), @InactiveDELETE varchar(400), @ZipDELETE varchar(400), @StateDELETE varchar(400), @DEAStatusDELETE varchar(400), 
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = AccountAddressId, @NameINSERT = Name, @AccountINSERT = Account, @Addressline2INSERT = Addressline2, @CityINSERT = City, @DEAINSERT = DEA, @DEAExpirationDateINSERT = DEAExpirationDate, @DEALicenseAddressINSERT = DEALicenseAddress, @PhoneINSERT = Phone, @FaxINSERT = Fax, @IsPrimaryINSERT = IsPrimary, @LicenseINSERT = License, @LicenseExpirationDateINSERT = LicenseExpirationDate, @LicenseStatusINSERT = LicenseStatus, @Zip4INSERT = Zip4, @Phone2INSERT = Phone2, @Fax2INSERT = Fax2, @LicenseValidToSampleINSERT = LicenseValidToSample, @SampleStatusINSERT = SampleStatus, @InactiveINSERT = Inactive, @ZipINSERT = Zip, @StateINSERT = State, @DEAStatusINSERT = DEAStatus
				from #insertedUPDATE;

				SELECT
					@NameDELETE = Name, @AccountDELETE = Account, @Addressline2DELETE = Addressline2, @CityDELETE = City, @DEADELETE = DEA, @DEAExpirationDateDELETE = DEAExpirationDate, @DEALicenseAddressDELETE = DEALicenseAddress, @PhoneDELETE = Phone, @FaxDELETE = Fax, @IsPrimaryDELETE = IsPrimary, @LicenseDELETE = License, @LicenseExpirationDateDELETE = LicenseExpirationDate, @LicenseStatusDELETE = LicenseStatus, @Zip4DELETE = Zip4, @Phone2DELETE = Phone2, @Fax2DELETE = Fax2, @LicenseValidToSampleDELETE = LicenseValidToSample, @SampleStatusDELETE = SampleStatus, @InactiveDELETE = Inactive, @ZipDELETE = Zip, @StateDELETE = State, @DEAStatusDELETE = DEAStatus
				from #deleted WHERE AccountAddressId = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					@NameINSERT <> @NameDELETE OR (@NameINSERT IS NULL AND @NameDELETE IS NOT NULL) OR (@NameINSERT IS NOT NULL AND @NameDELETE IS NULL) OR @AccountINSERT <> @AccountDELETE OR (@AccountINSERT IS NULL AND @AccountDELETE IS NOT NULL) OR (@AccountINSERT IS NOT NULL AND @AccountDELETE IS NULL) OR @Addressline2INSERT <> @Addressline2DELETE OR (@Addressline2INSERT IS NULL AND @Addressline2DELETE IS NOT NULL) OR (@Addressline2INSERT IS NOT NULL AND @Addressline2DELETE IS NULL) OR @CityINSERT <> @CityDELETE OR (@CityINSERT IS NULL AND @CityDELETE IS NOT NULL) OR (@CityINSERT IS NOT NULL AND @CityDELETE IS NULL) OR @DEAINSERT <> @DEADELETE OR (@DEAINSERT IS NULL AND @DEADELETE IS NOT NULL) OR (@DEAINSERT IS NOT NULL AND @DEADELETE IS NULL) OR @DEAExpirationDateINSERT <> @DEAExpirationDateDELETE OR (@DEAExpirationDateINSERT IS NULL AND @DEAExpirationDateDELETE IS NOT NULL) OR (@DEAExpirationDateINSERT IS NOT NULL AND @DEAExpirationDateDELETE IS NULL) OR @DEALicenseAddressINSERT <> @DEALicenseAddressDELETE OR (@DEALicenseAddressINSERT IS NULL AND @DEALicenseAddressDELETE IS NOT NULL) OR (@DEALicenseAddressINSERT IS NOT NULL AND @DEALicenseAddressDELETE IS NULL) OR @PhoneINSERT <> @PhoneDELETE OR (@PhoneINSERT IS NULL AND @PhoneDELETE IS NOT NULL) OR (@PhoneINSERT IS NOT NULL AND @PhoneDELETE IS NULL) OR @FaxINSERT <> @FaxDELETE OR (@FaxINSERT IS NULL AND @FaxDELETE IS NOT NULL) OR (@FaxINSERT IS NOT NULL AND @FaxDELETE IS NULL) OR @IsPrimaryINSERT <> @IsPrimaryDELETE OR (@IsPrimaryINSERT IS NULL AND @IsPrimaryDELETE IS NOT NULL) OR (@IsPrimaryINSERT IS NOT NULL AND @IsPrimaryDELETE IS NULL) OR @LicenseINSERT <> @LicenseDELETE OR (@LicenseINSERT IS NULL AND @LicenseDELETE IS NOT NULL) OR (@LicenseINSERT IS NOT NULL AND @LicenseDELETE IS NULL) OR @LicenseExpirationDateINSERT <> @LicenseExpirationDateDELETE OR (@LicenseExpirationDateINSERT IS NULL AND @LicenseExpirationDateDELETE IS NOT NULL) OR (@LicenseExpirationDateINSERT IS NOT NULL AND @LicenseExpirationDateDELETE IS NULL) OR @LicenseStatusINSERT <> @LicenseStatusDELETE OR (@LicenseStatusINSERT IS NULL AND @LicenseStatusDELETE IS NOT NULL) OR (@LicenseStatusINSERT IS NOT NULL AND @LicenseStatusDELETE IS NULL) OR @Zip4INSERT <> @Zip4DELETE OR (@Zip4INSERT IS NULL AND @Zip4DELETE IS NOT NULL) OR (@Zip4INSERT IS NOT NULL AND @Zip4DELETE IS NULL) OR @Phone2INSERT <> @Phone2DELETE OR (@Phone2INSERT IS NULL AND @Phone2DELETE IS NOT NULL) OR (@Phone2INSERT IS NOT NULL AND @Phone2DELETE IS NULL) OR @Fax2INSERT <> @Fax2DELETE OR (@Fax2INSERT IS NULL AND @Fax2DELETE IS NOT NULL) OR (@Fax2INSERT IS NOT NULL AND @Fax2DELETE IS NULL) OR @LicenseValidToSampleINSERT <> @LicenseValidToSampleDELETE OR (@LicenseValidToSampleINSERT IS NULL AND @LicenseValidToSampleDELETE IS NOT NULL) OR (@LicenseValidToSampleINSERT IS NOT NULL AND @LicenseValidToSampleDELETE IS NULL) OR @SampleStatusINSERT <> @SampleStatusDELETE OR (@SampleStatusINSERT IS NULL AND @SampleStatusDELETE IS NOT NULL) OR (@SampleStatusINSERT IS NOT NULL AND @SampleStatusDELETE IS NULL) OR @InactiveINSERT <> @InactiveDELETE OR (@InactiveINSERT IS NULL AND @InactiveDELETE IS NOT NULL) OR (@InactiveINSERT IS NOT NULL AND @InactiveDELETE IS NULL) OR @ZipINSERT <> @ZipDELETE OR (@ZipINSERT IS NULL AND @ZipDELETE IS NOT NULL) OR (@ZipINSERT IS NOT NULL AND @ZipDELETE IS NULL) OR @StateINSERT <> @StateDELETE OR (@StateINSERT IS NULL AND @StateDELETE IS NOT NULL) OR (@StateINSERT IS NOT NULL AND @StateDELETE IS NULL) OR @DEAStatusINSERT <> @DEAStatusDELETE OR (@DEAStatusINSERT IS NULL AND @DEAStatusDELETE IS NOT NULL) OR (@DEAStatusINSERT IS NOT NULL AND @DEAStatusDELETE IS NULL)
					BEGIN
						UPDATE [AccountAddress] SET EndDate = GETDATE() WHERE AccountAddressId = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [AccountAddress](CreatedDate, UpdatedDate, ExternalId1, AccountAddressId, IsDeleted, Name, RecordTypeId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, Addressline2, City, ExternalID, DEA, DEAExpirationDate, DEALicenseAddress, Phone, Fax, Map, Shipping, IsPrimary, License, LicenseExpirationDate, LicenseStatus, Zip4, Phone2, Fax2, LicenseValidToSample, SampleStatus, IncludeinTerritoryAssignment, MobileID, Inactive, Lock, Country, Zip, Source, Brick, ASSMCA, DEAAddress, DEASchedule, Business, Billing, Home, Mailing, State, DEAStatus, EntityReferenceId, ControllingAddress, ControlledAddress, NoAddressCopy, SampleSendStatus, CRMIDc, EndDate)
						SELECT CreatedDate, UpdatedDate, ExternalId1, AccountAddressId, IsDeleted, Name, RecordTypeId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, Addressline2, City, ExternalID, DEA, DEAExpirationDate, DEALicenseAddress, Phone, Fax, Map, Shipping, IsPrimary, License, LicenseExpirationDate, LicenseStatus, Zip4, Phone2, Fax2, LicenseValidToSample, SampleStatus, IncludeinTerritoryAssignment, MobileID, Inactive, Lock, Country, Zip, Source, Brick, ASSMCA, DEAAddress, DEASchedule, Business, Billing, Home, Mailing, State, DEAStatus, EntityReferenceId, ControllingAddress, ControlledAddress, NoAddressCopy, SampleSendStatus, CRMIDc, CASE WHEN IsDeleted = 'True' THEN GETDATE() END
						FROM #insertedUPDATE WHERE AccountAddressId = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET T.CreatedDate = I.CreatedDate
						 , T.UpdatedDate = I.UpdatedDate
						 , T.ExternalId1 = I.ExternalId1
						 , T.IsDeleted = I.IsDeleted
						 , T.RecordTypeId = I.RecordTypeId
						 , T.VeevaCreatedDate = I.VeevaCreatedDate
						 , T.VeevaCreatedById = I.VeevaCreatedById
						 , T.LastModifiedDate = I.LastModifiedDate
						 , T.LastModifiedById = I.LastModifiedById
						 , T.SystemModstamp = I.SystemModstamp
						 , T.MayEdit = I.MayEdit
						 , T.IsLocked = I.IsLocked
						 , T.ExternalID = I.ExternalID
						 , T.Map = I.Map
						 , T.Shipping = I.Shipping
						 , T.IncludeinTerritoryAssignment = I.IncludeinTerritoryAssignment
						 , T.MobileID = I.MobileID
						 , T.Lock = I.Lock
						 , T.Country = I.Country
						 , T.Source = I.Source
						 , T.Brick = I.Brick
						 , T.ASSMCA = I.ASSMCA
						 , T.DEAAddress = I.DEAAddress
						 , T.DEASchedule = I.DEASchedule
						 , T.Business = I.Business
						 , T.Billing = I.Billing
						 , T.Home = I.Home
						 , T.Mailing = I.Mailing
						 , T.EntityReferenceId = I.EntityReferenceId
						 , T.ControllingAddress = I.ControllingAddress
						 , T.ControlledAddress = I.ControlledAddress
						 , T.NoAddressCopy = I.NoAddressCopy
						 , T.SampleSendStatus = I.SampleSendStatus
						 , T.CRMIDc = I.CRMIDc, T.EndDate = CASE WHEN I.IsDeleted = 'True' THEN GETDATE() END 
					FROM [AccountAddress] T INNER JOIN #insertedUPDATE I ON T.AccountAddressId = I.AccountAddressId AND I.AccountAddressId = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where AccountAddressId = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [AccountAddress](CreatedDate, UpdatedDate, ExternalId1, AccountAddressId, IsDeleted, Name, RecordTypeId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, Addressline2, City, ExternalID, DEA, DEAExpirationDate, DEALicenseAddress, Phone, Fax, Map, Shipping, IsPrimary, License, LicenseExpirationDate, LicenseStatus, Zip4, Phone2, Fax2, LicenseValidToSample, SampleStatus, IncludeinTerritoryAssignment, MobileID, Inactive, Lock, Country, Zip, Source, Brick, ASSMCA, DEAAddress, DEASchedule, Business, Billing, Home, Mailing, State, DEAStatus, EntityReferenceId, ControllingAddress, ControlledAddress, NoAddressCopy, SampleSendStatus, CRMIDc, EndDate)
				SELECT CreatedDate, UpdatedDate, ExternalId1, AccountAddressId, IsDeleted, Name, RecordTypeId, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, Account, Addressline2, City, ExternalID, DEA, DEAExpirationDate, DEALicenseAddress, Phone, Fax, Map, Shipping, IsPrimary, License, LicenseExpirationDate, LicenseStatus, Zip4, Phone2, Fax2, LicenseValidToSample, SampleStatus, IncludeinTerritoryAssignment, MobileID, Inactive, Lock, Country, Zip, Source, Brick, ASSMCA, DEAAddress, DEASchedule, Business, Billing, Home, Mailing, State, DEAStatus, EntityReferenceId, ControllingAddress, ControlledAddress, NoAddressCopy, SampleSendStatus, CRMIDc, CASE WHEN IsDeleted = 'True' THEN GETDATE() END FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [AccountAddress] SET EndDate = GETDATE() WHERE AccountAddressId IN (SELECT AccountAddressId FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END


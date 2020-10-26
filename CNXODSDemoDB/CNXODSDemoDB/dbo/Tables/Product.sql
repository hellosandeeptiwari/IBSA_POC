CREATE TABLE [dbo].[Product] (
    [Id]                       INT              IDENTITY (1, 1) NOT NULL,
    [EndDate]                  DATETIME         NULL,
    [CreatedDate]              DATETIME         NULL,
    [UpdatedDate]              DATETIME         NULL,
    [ExternalId1]              VARCHAR (400)    NULL,
    [ProductId]                UNIQUEIDENTIFIER NULL,
    [OwnerId]                  VARCHAR (400)    NULL,
    [IsDeleted]                VARCHAR (400)    NULL,
    [Name]                     VARCHAR (400)    NULL,
    [VeevaCreatedDate]         VARCHAR (400)    NULL,
    [VeevaCreatedById]         VARCHAR (400)    NULL,
    [LastModifiedDate]         VARCHAR (400)    NULL,
    [LastModifiedById]         VARCHAR (400)    NULL,
    [SystemModstamp]           VARCHAR (400)    NULL,
    [MayEdit]                  VARCHAR (400)    NULL,
    [IsLocked]                 VARCHAR (400)    NULL,
    [LastViewedDate]           VARCHAR (400)    NULL,
    [LastReferencedDate]       VARCHAR (400)    NULL,
    [Consumersitec]            VARCHAR (400)    NULL,
    [Productinfoc]             VARCHAR (400)    NULL,
    [TherapeuticClass]         VARCHAR (400)    NULL,
    [ParentProduct]            VARCHAR (400)    NULL,
    [TherapeuticArea]          VARCHAR (400)    NULL,
    [ProductType]              VARCHAR (400)    NULL,
    [RequireKeyMessage]        VARCHAR (400)    NULL,
    [Cost]                     VARCHAR (400)    NULL,
    [ExternalID]               VARCHAR (400)    NULL,
    [Manufacturer]             VARCHAR (400)    NULL,
    [CompanyProduct]           VARCHAR (400)    NULL,
    [ControlledSubstance]      VARCHAR (400)    NULL,
    [Description]              VARCHAR (400)    NULL,
    [SampleQuantityPicklist]   VARCHAR (400)    NULL,
    [DisplayOrder]             VARCHAR (400)    NULL,
    [NoMetrics]                VARCHAR (400)    NULL,
    [Distributor]              VARCHAR (400)    NULL,
    [SampleQuantityBound]      VARCHAR (400)    NULL,
    [SampleUM]                 VARCHAR (400)    NULL,
    [NoDetails]                VARCHAR (400)    NULL,
    [QuantityPerCase]          VARCHAR (400)    NULL,
    [Schedule]                 VARCHAR (400)    NULL,
    [Restricted]               VARCHAR (400)    NULL,
    [PricingRuleQuantityBound] VARCHAR (400)    NULL,
    [NoPromoItems]             VARCHAR (400)    NULL,
    [UserAligned]              VARCHAR (400)    NULL,
    [RestrictedStates]         VARCHAR (400)    NULL,
    [SortCode]                 VARCHAR (400)    NULL,
    [NoCyclePlans]             VARCHAR (400)    NULL,
    [InventoryOrderUOM]        VARCHAR (400)    NULL,
    [InventoryQuantityPerCase] VARCHAR (400)    NULL,
    [VExternalId]              VARCHAR (400)    NULL,
    CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE TRIGGER [dbo].[trg_Product] on [dbo].[Product] INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN

	-- To suppress messages from the trigger
	SET NOCOUNT ON

	-- Filter out all archived rows & unwanted columns to improve performance
	SELECT ProductId, Name, TherapeuticClass, ParentProduct, TherapeuticArea, ProductType, Cost, Manufacturer, CompanyProduct, Description into #deleted from DELETED where EndDate IS NULL;

	IF EXISTS (select 1 from INSERTED)
	BEGIN
		IF exists (select 1 from #deleted) -- Check if an active row is updated
		BEGIN -- Update block

			-- Filter out all archived rows to improve performance
			select * into #insertedUPDATE from INSERTED where EndDate IS NULL;

			--declare necessary variables to store temporary values
			declare @NameINSERT varchar(400), @TherapeuticClassINSERT varchar(400), @ParentProductINSERT varchar(400), @TherapeuticAreaINSERT varchar(400), @ProductTypeINSERT varchar(400), @CostINSERT varchar(400), @ManufacturerINSERT varchar(400), @CompanyProductINSERT varchar(400), @DescriptionINSERT varchar(400),  
				@NameDELETE varchar(400), @TherapeuticClassDELETE varchar(400), @ParentProductDELETE varchar(400), @TherapeuticAreaDELETE varchar(400), @ProductTypeDELETE varchar(400), @CostDELETE varchar(400), @ManufacturerDELETE varchar(400), @CompanyProductDELETE varchar(400), @DescriptionDELETE varchar(400), 
				@PrimaryKeyValue NVARCHAR(100), @loopCount INT;
			
			SELECT @loopCount = count(*) from #insertedUPDATE;
			While @loopCount > 0
			BEGIN
				SELECT TOP 1 
					@PrimaryKeyValue = ProductId, @NameINSERT = Name, @TherapeuticClassINSERT = TherapeuticClass, @ParentProductINSERT = ParentProduct, @TherapeuticAreaINSERT = TherapeuticArea, @ProductTypeINSERT = ProductType, @CostINSERT = Cost, @ManufacturerINSERT = Manufacturer, @CompanyProductINSERT = CompanyProduct, @DescriptionINSERT = Description
				from #insertedUPDATE;

				SELECT
					@NameDELETE = Name, @TherapeuticClassDELETE = TherapeuticClass, @ParentProductDELETE = ParentProduct, @TherapeuticAreaDELETE = TherapeuticArea, @ProductTypeDELETE = ProductType, @CostDELETE = Cost, @ManufacturerDELETE = Manufacturer, @CompanyProductDELETE = CompanyProduct, @DescriptionDELETE = Description
				from #deleted WHERE ProductId = @PrimaryKeyValue;

				-- If at least one of the auditable fields is modified, then set the EndDate on the current active row 
				-- and create a new row with the latest values.
				IF 
					@NameINSERT <> @NameDELETE OR (@NameINSERT IS NULL AND @NameDELETE IS NOT NULL) OR (@NameINSERT IS NOT NULL AND @NameDELETE IS NULL) OR @TherapeuticClassINSERT <> @TherapeuticClassDELETE OR (@TherapeuticClassINSERT IS NULL AND @TherapeuticClassDELETE IS NOT NULL) OR (@TherapeuticClassINSERT IS NOT NULL AND @TherapeuticClassDELETE IS NULL) OR @ParentProductINSERT <> @ParentProductDELETE OR (@ParentProductINSERT IS NULL AND @ParentProductDELETE IS NOT NULL) OR (@ParentProductINSERT IS NOT NULL AND @ParentProductDELETE IS NULL) OR @TherapeuticAreaINSERT <> @TherapeuticAreaDELETE OR (@TherapeuticAreaINSERT IS NULL AND @TherapeuticAreaDELETE IS NOT NULL) OR (@TherapeuticAreaINSERT IS NOT NULL AND @TherapeuticAreaDELETE IS NULL) OR @ProductTypeINSERT <> @ProductTypeDELETE OR (@ProductTypeINSERT IS NULL AND @ProductTypeDELETE IS NOT NULL) OR (@ProductTypeINSERT IS NOT NULL AND @ProductTypeDELETE IS NULL) OR @CostINSERT <> @CostDELETE OR (@CostINSERT IS NULL AND @CostDELETE IS NOT NULL) OR (@CostINSERT IS NOT NULL AND @CostDELETE IS NULL) OR @ManufacturerINSERT <> @ManufacturerDELETE OR (@ManufacturerINSERT IS NULL AND @ManufacturerDELETE IS NOT NULL) OR (@ManufacturerINSERT IS NOT NULL AND @ManufacturerDELETE IS NULL) OR @CompanyProductINSERT <> @CompanyProductDELETE OR (@CompanyProductINSERT IS NULL AND @CompanyProductDELETE IS NOT NULL) OR (@CompanyProductINSERT IS NOT NULL AND @CompanyProductDELETE IS NULL) OR @DescriptionINSERT <> @DescriptionDELETE OR (@DescriptionINSERT IS NULL AND @DescriptionDELETE IS NOT NULL) OR (@DescriptionINSERT IS NOT NULL AND @DescriptionDELETE IS NULL)
					BEGIN
						UPDATE [Product] SET EndDate = GETDATE() WHERE ProductId = @PrimaryKeyValue AND EndDate IS NULL;

						INSERT INTO [Product](CreatedDate, UpdatedDate, ExternalId1, ProductId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, Consumersitec, Productinfoc, TherapeuticClass, ParentProduct, TherapeuticArea, ProductType, RequireKeyMessage, Cost, ExternalID, Manufacturer, CompanyProduct, ControlledSubstance, Description, SampleQuantityPicklist, DisplayOrder, NoMetrics, Distributor, SampleQuantityBound, SampleUM, NoDetails, QuantityPerCase, Schedule, Restricted, PricingRuleQuantityBound, NoPromoItems, UserAligned, RestrictedStates, SortCode, NoCyclePlans, InventoryOrderUOM, InventoryQuantityPerCase, VExternalId, EndDate)
						SELECT CreatedDate, UpdatedDate, ExternalId1, ProductId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, Consumersitec, Productinfoc, TherapeuticClass, ParentProduct, TherapeuticArea, ProductType, RequireKeyMessage, Cost, ExternalID, Manufacturer, CompanyProduct, ControlledSubstance, Description, SampleQuantityPicklist, DisplayOrder, NoMetrics, Distributor, SampleQuantityBound, SampleUM, NoDetails, QuantityPerCase, Schedule, Restricted, PricingRuleQuantityBound, NoPromoItems, UserAligned, RestrictedStates, SortCode, NoCyclePlans, InventoryOrderUOM, InventoryQuantityPerCase, VExternalId, CASE WHEN IsDeleted = 'True' THEN GETDATE() END
						FROM #insertedUPDATE WHERE ProductId = @PrimaryKeyValue;
					END
				ELSE
					-- If none of the auditable fields is modified, then update the current active row with the latest values.
					UPDATE T SET T.CreatedDate = I.CreatedDate
						 , T.UpdatedDate = I.UpdatedDate
						 , T.ExternalId1 = I.ExternalId1
						 , T.OwnerId = I.OwnerId
						 , T.IsDeleted = I.IsDeleted
						 , T.VeevaCreatedDate = I.VeevaCreatedDate
						 , T.VeevaCreatedById = I.VeevaCreatedById
						 , T.LastModifiedDate = I.LastModifiedDate
						 , T.LastModifiedById = I.LastModifiedById
						 , T.SystemModstamp = I.SystemModstamp
						 , T.MayEdit = I.MayEdit
						 , T.IsLocked = I.IsLocked
						 , T.LastViewedDate = I.LastViewedDate
						 , T.LastReferencedDate = I.LastReferencedDate
						 , T.Consumersitec = I.Consumersitec
						 , T.Productinfoc = I.Productinfoc
						 , T.RequireKeyMessage = I.RequireKeyMessage
						 , T.ExternalID = I.ExternalID
						 , T.ControlledSubstance = I.ControlledSubstance
						 , T.SampleQuantityPicklist = I.SampleQuantityPicklist
						 , T.DisplayOrder = I.DisplayOrder
						 , T.NoMetrics = I.NoMetrics
						 , T.Distributor = I.Distributor
						 , T.SampleQuantityBound = I.SampleQuantityBound
						 , T.SampleUM = I.SampleUM
						 , T.NoDetails = I.NoDetails
						 , T.QuantityPerCase = I.QuantityPerCase
						 , T.Schedule = I.Schedule
						 , T.Restricted = I.Restricted
						 , T.PricingRuleQuantityBound = I.PricingRuleQuantityBound
						 , T.NoPromoItems = I.NoPromoItems
						 , T.UserAligned = I.UserAligned
						 , T.RestrictedStates = I.RestrictedStates
						 , T.SortCode = I.SortCode
						 , T.NoCyclePlans = I.NoCyclePlans
						 , T.InventoryOrderUOM = I.InventoryOrderUOM
						 , T.InventoryQuantityPerCase = I.InventoryQuantityPerCase
						 , T.VExternalId = I.VExternalId, T.EndDate = CASE WHEN I.IsDeleted = 'True' THEN GETDATE() END 
					FROM [Product] T INNER JOIN #insertedUPDATE I ON T.ProductId = I.ProductId AND I.ProductId = @PrimaryKeyValue
					WHERE T.EndDate IS NULL;

				SELECT @loopCount = @loopCount - 1;
				delete from #insertedUPDATE where ProductId = @PrimaryKeyValue;
			END -- End of While loop
		END -- End of Update block
		ELSE
		BEGIN -- Insert block
			IF NOT EXISTS (select 1 from DELETED) -- Check if an Inactive row is updated
			BEGIN
				-- To ensure that EndDate column value is always NULL on an INSERT statement.
				INSERT INTO [Product](CreatedDate, UpdatedDate, ExternalId1, ProductId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, Consumersitec, Productinfoc, TherapeuticClass, ParentProduct, TherapeuticArea, ProductType, RequireKeyMessage, Cost, ExternalID, Manufacturer, CompanyProduct, ControlledSubstance, Description, SampleQuantityPicklist, DisplayOrder, NoMetrics, Distributor, SampleQuantityBound, SampleUM, NoDetails, QuantityPerCase, Schedule, Restricted, PricingRuleQuantityBound, NoPromoItems, UserAligned, RestrictedStates, SortCode, NoCyclePlans, InventoryOrderUOM, InventoryQuantityPerCase, VExternalId, EndDate)
				SELECT CreatedDate, UpdatedDate, ExternalId1, ProductId, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, LastViewedDate, LastReferencedDate, Consumersitec, Productinfoc, TherapeuticClass, ParentProduct, TherapeuticArea, ProductType, RequireKeyMessage, Cost, ExternalID, Manufacturer, CompanyProduct, ControlledSubstance, Description, SampleQuantityPicklist, DisplayOrder, NoMetrics, Distributor, SampleQuantityBound, SampleUM, NoDetails, QuantityPerCase, Schedule, Restricted, PricingRuleQuantityBound, NoPromoItems, UserAligned, RestrictedStates, SortCode, NoCyclePlans, InventoryOrderUOM, InventoryQuantityPerCase, VExternalId, CASE WHEN IsDeleted = 'True' THEN GETDATE() END FROM INSERTED;
			END
		END -- End of Insert block
	END
	ELSE
	BEGIN -- Delete Block
		UPDATE [Product] SET EndDate = GETDATE() WHERE ProductId IN (SELECT ProductId FROM #deleted) AND EndDate IS NULL;
	END -- End of Delete block
END





CREATE   PROCEDURE [dbo].[sp_product_transform] 
AS
BEGIN

	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_product_transform', 'Started', GETUTCDATE());


	UPDATE P SET 
		P.UpdatedDate = GETDATE(),
		P.ExternalId1 = S.Id,
		P.OwnerId = S.OwnerId,
		P.IsDeleted = S.IsDeleted,
		P.Name = S.Name,
		P.VeevaCreatedDate = S.CreatedDate,
		P.VeevaCreatedById = S.CreatedById,
		P.LastModifiedDate = S.LastModifiedDate,
		P.LastModifiedById = S.LastModifiedById,
		P.SystemModstamp = S.SystemModstamp,
		P.MayEdit = S.MayEdit,
		P.IsLocked = S.IsLocked,
		P.LastViewedDate = S.LastViewedDate,
		P.LastReferencedDate = S.LastReferencedDate,
		P.Consumersitec = S.Consumer_site__c,
		P.Productinfoc = S.Product_info__c,
		P.TherapeuticClass = S.Therapeutic_Class_vod__c,
		P.ParentProduct = S.Parent_Product_vod__c,
		P.TherapeuticArea = S.Therapeutic_Area_vod__c,
		P.ProductType = S.Product_Type_vod__c,
		P.RequireKeyMessage = S.Require_Key_Message_vod__c,
		P.Cost = S.Cost_vod__c,
		P.ExternalID = S.External_ID_vod__c,
		P.Manufacturer = S.Manufacturer_vod__c,
		P.CompanyProduct = S.Company_Product_vod__c,
		P.ControlledSubstance = S.Controlled_Substance_vod__c,
		P.Description = S.Description_vod__c,
		P.SampleQuantityPicklist = S.Sample_Quantity_Picklist_vod__c,
		P.DisplayOrder = S.Display_Order_vod__c,
		P.NoMetrics = S.No_Metrics_vod__c,
		P.Distributor = S.Distributor_vod__c,
		P.SampleQuantityBound = S.Sample_Quantity_Bound_vod__c,
		P.SampleUM = S.Sample_U_M_vod__c,
		P.NoDetails = S.No_Details_vod__c,
		P.QuantityPerCase = S.Quantity_Per_Case_vod__c,
		P.Schedule = S.Schedule_vod__c,
		P.Restricted = S.Restricted_vod__c,
		P.PricingRuleQuantityBound = S.Pricing_Rule_Quantity_Bound_vod__c,
		P.NoPromoItems = S.No_Promo_Items_vod__c,
		P.UserAligned = S.User_Aligned_vod__c,
		P.RestrictedStates = S.Restricted_States_vod__c,
		P.SortCode = S.Sort_Code_vod__c,
		P.NoCyclePlans = S.No_Cycle_Plans_vod__c,
		P.InventoryOrderUOM = S.Inventory_Order_UOM_vod__c,
		P.InventoryQuantityPerCase = S.Inventory_Quantity_Per_Case_vod__c,
		P.VExternalId = S.VExternal_Id_vod__c
	FROM [dbo].[Product] P
	INNER JOIN [dbo].[Staging_Product] S ON S.[Id] = P.[ExternalId1] 
		AND S.SystemModstamp <> P.SystemModstamp AND P.EndDate IS NULL;
		
		

	INSERT INTO [dbo].[Product]
		([ProductId], CreatedDate, 
		ExternalId1, OwnerId, IsDeleted, Name, VeevaCreatedDate, VeevaCreatedById, 
		LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, 
		LastViewedDate, LastReferencedDate, Consumersitec, Productinfoc, 
		TherapeuticClass, ParentProduct, TherapeuticArea, ProductType, 
		RequireKeyMessage, Cost, ExternalID, Manufacturer, CompanyProduct, 
		ControlledSubstance, Description, SampleQuantityPicklist, DisplayOrder, 
		NoMetrics, Distributor, SampleQuantityBound, SampleUM, NoDetails, 
		QuantityPerCase, Schedule, Restricted, PricingRuleQuantityBound, 
		NoPromoItems, UserAligned, RestrictedStates, SortCode, NoCyclePlans, 
		InventoryOrderUOM, InventoryQuantityPerCase, VExternalId)
	SELECT
		NEWID() AS [ProductId], GETDATE(),
		Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, 
		LastModifiedDate, LastModifiedById, SystemModstamp, MayEdit, IsLocked, 
		LastViewedDate, LastReferencedDate, Consumer_site__c, Product_info__c, 
		Therapeutic_Class_vod__c, Parent_Product_vod__c, Therapeutic_Area_vod__c, Product_Type_vod__c, 
		Require_Key_Message_vod__c, Cost_vod__c, External_ID_vod__c, Manufacturer_vod__c, Company_Product_vod__c, 
		Controlled_Substance_vod__c, Description_vod__c, Sample_Quantity_Picklist_vod__c, Display_Order_vod__c, 
		No_Metrics_vod__c, Distributor_vod__c, Sample_Quantity_Bound_vod__c, Sample_U_M_vod__c, No_Details_vod__c, 
		Quantity_Per_Case_vod__c, Schedule_vod__c, Restricted_vod__c, Pricing_Rule_Quantity_Bound_vod__c, 
		No_Promo_Items_vod__c, User_Aligned_vod__c, Restricted_States_vod__c, Sort_Code_vod__c, No_Cycle_Plans_vod__c, 
		Inventory_Order_UOM_vod__c, Inventory_Quantity_Per_Case_vod__c, VExternal_Id_vod__c
	FROM [Staging_Product] AS S
	WHERE NOT EXISTS (SELECT 1 FROM [Product] P WHERE P.[ExternalId1] = S.[Id] AND P.EndDate IS NULL);


	INSERT INTO LogMessage(ProcedureName, Comments, LogUTCDate) VALUES('sp_product_transform', 'Completed', GETUTCDATE());

END


create proc [web].SOps_PopulateSOpsAccountReviewForLiveCallPlan
(
	@sOpsCallPlanId int
)
as
begin

	insert into [web].SOpsAccountReview	(SOpsCallPlanId,SOpsTerritoryId,SOpsAccountId,AccountName,AddressLine1,City,State,Specialty,CurrentTierValue,RecommendedTierValue,ExternalId1,ExternalId2,ExternalId3,ExternalId4,ExternalId5,ExternalId6,ExternalId7,ExternalId8)
		select @sOpsCallPlanId as 'SOpsCallPlanId', SACT.SOpsTerritoryId, SACT.SOpsAccountId
			, SACC.Name as 'AccountName',SADD.AddressLine1,	SADD.City, SADD.State,	SPEC.SpecialtyType,	SATC.Value as 'CurrentTierValue',	SATR.Value as 'RecommendedTierValue',SACC.ExternalId1,SACC.ExternalId2,SACC.ExternalId3,SACC.ExternalId4,SACC.ExternalId5,SACC.ExternalId6,SACC.ExternalId7,SACC.ExternalId8
			from [web].sopsaccountTerritory SACT
			inner join [web].SOpsAccount SACC on SACT.SOpsAccountId=SACC.SOpsAccountId
			left join [web].SOpsAddress SADD on SACT.SopsAddressId=SADD.SOpsAddressId
			left join [web].SOpsSpecialty SPEC on SACC.SopsSpecialtyId=SPEC.SOpsSpecialtyId
			left join [web].SOpsAccountTier SATR on SACC.RecommendedTierId=SATR.SOpsAccountTierId
			left join [web].SOpsAccountTier SATC on SACT.CurrentTierId=SATC.SOpsAccountTierId

end
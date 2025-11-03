
create proc SOps_PopulateSOpsAccountReviewForLiveCallPlan
(
	@sOpsCallPlanId int
)
as
begin

	insert into SOpsAccountReview	(SOpsCallPlanId,SOpsTerritoryId,SOpsAccountId,AccountName,AddressLine1,City,State,Specialty,CurrentTierValue,RecommendedTierValue,ExternalId1,ExternalId2,ExternalId3,ExternalId4,ExternalId5,ExternalId6,ExternalId7,ExternalId8)
		select @sOpsCallPlanId as 'SOpsCallPlanId', SACT.SOpsTerritoryId, SACT.SOpsAccountId
			, SACC.Name as 'AccountName',SADD.AddressLine1,	SADD.City, SADD.State,	SPEC.SpecialtyType,	SATC.Value as 'CurrentTierValue',	SATR.Value as 'RecommendedTierValue',SACC.ExternalId1,SACC.ExternalId2,SACC.ExternalId3,SACC.ExternalId4,SACC.ExternalId5,SACC.ExternalId6,SACC.ExternalId7,SACC.ExternalId8
			from sopsaccountTerritory SACT
			inner join SOpsAccount SACC on SACT.SOpsAccountId=SACC.SOpsAccountId
			left join SOpsAddress SADD on SACT.SopsAddressId=SADD.SOpsAddressId
			left join SOpsSpecialty SPEC on SACC.SopsSpecialtyId=SPEC.SOpsSpecialtyId
			left join SOpsAccountTier SATR on SACC.RecommendedTierId=SATR.SOpsAccountTierId
			left join SOpsAccountTier SATC on SACT.CurrentTierId=SATC.SOpsAccountTierId

end
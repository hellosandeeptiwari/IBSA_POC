 create proc SOps_UpdateSOpsAccountTerritoryFutureTier(
	@callPlanPeriodId int
)
as
begin
	declare @callPlanLevelOfApproval nvarchar(4)
	select @callPlanLevelOfApproval=LevelOfApproval from SOpsCallPlan where SOpsCallPlanId=
		(select SOpsCallPlanId from SOpsCallPlanPeriod where SOpsCallPlanPeriodId= @callPlanPeriodId)

	begin transaction
	if(@callPlanLevelOfApproval='ALL')
	begin
		update SOpsAccountTerritory set SOpsAccountTerritory.FutureTierId=SOpsCallPlanAccountTier.SOpsAccountTierId from SOpsCallPlanAccountTier where SOpsCallPlanAccountTier.SOpsCallPlanPeriodId=@callPlanPeriodId and SOpsAccountTerritory.SOpsAccountId=SOpsCallPlanAccountTier.SOpsAccountId
	end
	else if(@callPlanLevelOfApproval='ONE')
	begin
		update SOpsAccountTerritory set SOpsAccountTerritory.FutureTierId=SOpsCallPlanOneLevelAccountTier.LevelThreeTierId
			from SOpsCallPlanOneLevelAccountTier where SOpsCallPlanOneLevelAccountTier.LevelThreeSOpsCallPlanPeriodId=@callPlanPeriodId 
				and SOpsAccountTerritory.SOpsAccountId=SOpsCallPlanOneLevelAccountTier.SOpsAccountId

	end
	if(@@ERROR=0)
	begin
		commit transaction
	end
	else
	begin
		rollback transaction
	end
end
 create proc [web].SOps_UpdateSOpsAccountTerritoryFutureTier(
	@callPlanPeriodId int
)
as
begin
	begin transaction
		update [web].SOpsAccountTerritory set SOpsAccountTerritory.FutureTierId=SOpsCallPlanOneLevelAccountTier.LevelThreeTierId
			from [web].SOpsCallPlanOneLevelAccountTier where SOpsCallPlanOneLevelAccountTier.LevelThreeSOpsCallPlanPeriodId=@callPlanPeriodId 
				and SOpsAccountTerritory.SOpsAccountId=SOpsCallPlanOneLevelAccountTier.SOpsAccountId
	if(@@ERROR=0)
	begin
		commit transaction
	end
	else
	begin
		rollback transaction
	end
end
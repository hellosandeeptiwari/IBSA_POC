create proc [web].SOps_UpdateCallPlanAccountTierForNewCallPlanPeriod(
	@previousCallPeriodPlanId int
)
as
begin
	declare @callPlanId int
	select @callPlanId=SOpsCallPlanId from [web].SOpsCallPlanPeriod where SOpsCallPlanPeriodId=@previousCallPeriodPlanId
	begin transaction
		if((select count(SOpsCallPlanOneLevelAccountTierId) from [web].SOpsCallPlanOneLevelAccountTier where LevelOneSOpsCallPlanPeriodId=@previousCallPeriodPlanId)>0)
		begin
			update  o set o.LevelTwoTierId=o.LevelOneTierId,o.LevelTwoUpdateDate=GETUTCDATE() from [web].SOpsCallPlanOneLevelAccountTier o where o.LevelOneSOpsCallPlanPeriodId=@previousCallPeriodPlanId
			
			insert into  [web].[SOpsAccountTierAudit] ([SOpsCallPlanId],[SOpsCallPlanPeriodId],[SOpsTerritoryId],[SOpsAccountId],[OldTier],[NewTier],[CreatorType],[CreatedDate])
			select @callPlanId,@previousCallPeriodPlanId+1,o.FieldTerritoryId,o.SOpsAccountId,AT1.Value,AT2.Value,'SYS',GETUTCDATE() 
				from [web].SOpsCallPlanOneLevelAccountTier o 
				inner join [web].SOpsAccountTier AT1 on o.LevelOneTierId=AT1.SOpsAccountTierId
				inner join [web].SOpsAccountTier AT2 on o.LevelTwoTierId=AT2.SOpsAccountTierId
				where o.LevelOneSOpsCallPlanPeriodId=@previousCallPeriodPlanId

		end
		else if((select count(SOpsCallPlanOneLevelAccountTierId) from [web].SOpsCallPlanOneLevelAccountTier where LevelTwoSOpsCallPlanPeriodId=@previousCallPeriodPlanId)>0)
		begin
			if((select count(SOpsCallPlanOneLevelAccountTierId) from [web].SOpsCallPlanOneLevelAccountTier where LevelTwoSOpsCallPlanPeriodId=2 and LevelTwoTierId is not null)>0)
			begin
				update  o set o.LevelTwoTierId=o.LevelOneTierId,o.LevelTwoUpdateDate=GETUTCDATE() from [web].SOpsCallPlanOneLevelAccountTier o where o.LevelOneSOpsCallPlanPeriodId=@previousCallPeriodPlanId-1

				insert into  [web].[SOpsAccountTierAudit] ([SOpsCallPlanId],[SOpsCallPlanPeriodId],[SOpsTerritoryId],[SOpsAccountId],[OldTier],[NewTier],[CreatorType],[CreatedDate])
				select @callPlanId,@previousCallPeriodPlanId,FieldTerritoryId,SOpsAccountId,AT1.Value,AT2.Value,'SYS',GETUTCDATE() 
					from [web].SOpsCallPlanOneLevelAccountTier o 
					inner join [web].SOpsAccountTier AT1 on o.LevelOneTierId=AT1.SOpsAccountTierId
					inner join [web].SOpsAccountTier AT2 on o.LevelTwoTierId=AT2.SOpsAccountTierId
					where o.LevelOneSOpsCallPlanPeriodId=@previousCallPeriodPlanId
			end
			update  o set o.LevelThreeTierId=o.LevelTwoTierId,o.LevelThreeUpdateDate=GETUTCDATE() from [web].SOpsCallPlanOneLevelAccountTier o where o.LevelTwoSOpsCallPlanPeriodId=@previousCallPeriodPlanId
			
			insert into  [web].[SOpsAccountTierAudit] ([SOpsCallPlanId],[SOpsCallPlanPeriodId],[SOpsTerritoryId],[SOpsAccountId],[OldTier],[NewTier],[CreatorType],[CreatedDate])
				select @callPlanId,@previousCallPeriodPlanId+1,FieldTerritoryId,SOpsAccountId,AT2.Value,AT3.Value,'SYS',GETUTCDATE() 
					from [web].SOpsCallPlanOneLevelAccountTier o 
					inner join [web].SOpsAccountTier AT2 on o.LevelTwoTierId=AT2.SOpsAccountTierId
					inner join [web].SOpsAccountTier AT3 on o.LevelThreeTierId=AT3.SOpsAccountTierId
					where o.LevelTwoSOpsCallPlanPeriodId=@previousCallPeriodPlanId
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
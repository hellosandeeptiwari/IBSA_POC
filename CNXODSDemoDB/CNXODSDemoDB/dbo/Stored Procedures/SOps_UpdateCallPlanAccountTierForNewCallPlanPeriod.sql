create proc SOps_UpdateCallPlanAccountTierForNewCallPlanPeriod(
	@previousCallPeriodPlanId int
)
as
begin
	declare @callPlanLevelOfApproval nvarchar(4)
	select @callPlanLevelOfApproval=LevelOfApproval from SOpsCallPlan where SOpsCallPlanId=
		(select SOpsCallPlanId from SOpsCallPlanPeriod where SOpsCallPlanPeriodId= @previousCallPeriodPlanId)
	
	begin transaction
	if(@callPlanLevelOfApproval='ALL')
	begin
		declare  @accountTier table
		(
			[Id] [int] IDENTITY(1,1) NOT NULL,
			[ParentSOpsCallPlanAccountTierId] [int] NOT NULL,
			[SOpsAccountTierId] [int]  null,
			primary key (Id)
		)

		insert into @accountTier select SOpsCallPlanAccountTierId,SOpsAccountTierId from SOpsCallPlanAccountTier where  SOpsCallPlanPeriodId=@previousCallPeriodPlanId
		declare @count int
		set @count=1
		declare @totalCount int
		select @totalCount=count(Id) from @accountTier

		while (@count<=@totalCount)
		begin
			declare @ParentSOpsCallPlanAccountTierId int 
			declare @SOpsAccountTierId int
			select @ParentSOpsCallPlanAccountTierId=ParentSOpsCallPlanAccountTierId,@SOpsAccountTierId=SOpsAccountTierId from @accountTier where id=@count
			update SOpsCallPlanAccountTier set SOpsAccountTierId=@SOpsAccountTierId where ParentSOpsCallPlanAccountTierId=@ParentSOpsCallPlanAccountTierId
			set @count=@count+1
		end
	end
	else if(@callPlanLevelOfApproval='ONE')
	begin
		if((select count(SOpsCallPlanOneLevelAccountTierId) from SOpsCallPlanOneLevelAccountTier where LevelOneSOpsCallPlanPeriodId=@previousCallPeriodPlanId)>0)
		begin
			update  o set o.LevelTwoTierId=o.LevelOneTierId from SOpsCallPlanOneLevelAccountTier o where o.LevelOneSOpsCallPlanPeriodId=@previousCallPeriodPlanId
		end
		else if((select count(SOpsCallPlanOneLevelAccountTierId) from SOpsCallPlanOneLevelAccountTier where LevelTwoSOpsCallPlanPeriodId=@previousCallPeriodPlanId)>0)
		begin
			update  o set o.LevelThreeTierId=o.LevelTwoTierId from SOpsCallPlanOneLevelAccountTier o where o.LevelTwoSOpsCallPlanPeriodId=@previousCallPeriodPlanId
		end
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
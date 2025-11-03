drop proc SOps_UpdateSOpsUserForLiveCallPlan
GO
create proc SOps_UpdateSOpsUserForLiveCallPlan(
	@sOpsUserId int,
	@callPlanId int
)
as
begin	
	--update total and average call counts in SOpsUser table
	declare @totalWorkingdays int
	select @totalWorkingdays=TotalWorkingdays from SOpsCallPlan where  SOpsCallPlanId=@callPlanId
	declare  @sOpsUsers table
	(
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[UserId] [int] NOT NULL,
		primary key (Id)
	)
	insert into @sOpsUsers (UserId) select SOpsUserId from SOpsUser where (@sOpsUserId=0 or (@sOpsUserId>0 and SOpsUserId=@sOpsUserId))
	declare @count int
	set @count=1
	begin transaction
	declare @userCount int
	select @userCount=count(Id) from @sOpsUsers
	declare @totalFutureCalls decimal(6,2)
	declare @callPlanLevelOfApproval nvarchar(4)
	select @callPlanLevelOfApproval=LevelOfApproval from SOpsCallPlan where SOpsCallPlanId=@callPlanId
	while(@count<=@userCount)
	begin
		declare @uId int
		select @uId=UserId from @sOpsUsers where Id=@count
		if(@callPlanLevelOfApproval='ALL')
		begin
			select @totalFutureCalls=sum(Tier.NumberOfCalls) from	SOpsCallPlanAccountTier ACT inner join SOpsAccountTier Tier on act.SOpsAccountTierId=Tier.SOpsAccountTierId where act.SOpsUserId=@uId
		end
		else if(@callPlanLevelOfApproval='ONE')
		begin
			select @totalFutureCalls=sum(Tier.NumberOfCalls) from	SOpsCallPlanOneLevelAccountTier ACT inner join SOpsAccountTier Tier on act.LevelOneTierId=Tier.SOpsAccountTierId where act.LevelOneUserId=@uId
		end
		update SOpsUser set NumberOfFutureTotalCalls=@totalFutureCalls,NumberOfFutureAverageCalls=cast((@totalFutureCalls/@totalWorkingdays) as decimal(6,2)) where SOpsUserId=@uId
		set @count=@count+1
	end
	update SOpsCallPlan set Status='LIVE' where SOpsCallPlanId=@callPlanId
	if(@@ERROR=0)
	begin
		commit transaction
	end
	else
	begin
		rollback transaction
	end
end
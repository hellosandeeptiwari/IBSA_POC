drop proc [web].SOps_UpdateSOpsTerritoryForLiveCallPlan
GO
create proc [web].SOps_UpdateSOpsTerritoryForLiveCallPlan(
	@sOpsTerritoryId int,
	@callPlanId int
)
as
begin	
	--update total and average call counts in SOpsUser table
	declare @totalWorkingdays int
	select @totalWorkingdays=TotalWorkingdays from [web].SOpsCallPlan where  SOpsCallPlanId=@callPlanId
	declare  @sOpsTerritories table
	(
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[SOpsTerritoryId] [int] NOT NULL,
		primary key (Id)
	)
	insert into @sOpsTerritories ([SOpsTerritoryId]) select [SOpsTerritoryId] from [web].SOpsTerritory where (@sOpsTerritoryId=0 or (@sOpsTerritoryId>0 and SOpsTerritoryId=@sOpsTerritoryId))
	declare @count int
	set @count=1
	begin transaction
	declare @territoryCount int
	declare @targetCount int
	declare @nonTargetCount int
	select @territoryCount=count(Id) from @sOpsTerritories
	declare @totalFutureCalls decimal(6,2)
	while(@count<=@territoryCount)
	begin
		declare @territoryId int
		select @territoryId=SOpsTerritoryId from @sOpsTerritories where Id=@count
		select @targetCount=count(*) from	[web].SOpsCallPlanOneLevelAccountTier ACT inner join [web].SOpsAccountTier Tier on act.LevelOneTierId=Tier.SOpsAccountTierId where act.FieldTerritoryId=@territoryId and Tier.NumberOfCalls>0
		select @nonTargetCount=count(*) from	[web].SOpsCallPlanOneLevelAccountTier ACT inner join [web].SOpsAccountTier Tier on act.LevelOneTierId=Tier.SOpsAccountTierId where act.FieldTerritoryId=@territoryId and Tier.NumberOfCalls=0
		select @totalFutureCalls=sum(Tier.NumberOfCalls) from	[web].SOpsCallPlanOneLevelAccountTier ACT inner join SOpsAccountTier Tier on act.LevelOneTierId=Tier.SOpsAccountTierId where act.FieldTerritoryId=@territoryId
		update [web].[SOpsTerritory] set CurrentTargetCount=@targetCount,CurrentNonTargetCount=@nonTargetCount,FutureTargetCount=@targetCount,FutureNonTargetCount=@nonTargetCount, NumberOfFutureTotalCalls=@totalFutureCalls,NumberOfFutureAverageCalls=cast((@totalFutureCalls/@totalWorkingdays) as decimal(6,2)) where SOpsTerritoryId=@territoryId
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
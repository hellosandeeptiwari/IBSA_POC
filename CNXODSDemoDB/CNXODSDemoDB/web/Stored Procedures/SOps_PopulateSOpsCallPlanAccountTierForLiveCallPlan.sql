create proc [web].SOps_PopulateSOpsCallPlanAccountTierForLiveCallPlan(
	@sOpsTerritoryId int,
	@callPlanId int
)
as
begin
	declare  @accountTier table
	(
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[SOpsAccountId] [int] NOT NULL,
		[FieldTerritoryId] [int] NOT NULL,
		[RecommendedTierId] [int]  null,
		[RecommendedTierValue] nvarchar(200)  null,
		[FieldUserId] [int] NOT NULL,
		primary key (Id)
	)

	--Populate account tier table variable
	insert into @accountTier
		(SOpsAccountId,FieldTerritoryId,FieldUserId,RecommendedTierId,[RecommendedTierValue])
	select SAT.SOpsAccountId, SAT.SOpsTerritoryId, FieldUT.SOpsUserId, Acc.RecommendedTierId,AT.Value
	from [web].SOpsAccountTerritory SAT
		inner join SOpsUserTerritory FieldUT on FieldUT.SOpsTerritoryId=SAT.SOpsTerritoryId
		inner join SOpsAccount Acc on SAT.SOpsAccountId=Acc.SOpsAccountId
		left join SOpsAccountTier AT on Acc.RecommendedTierId=AT.SOpsAccountTierId
	where FieldUT.IsActiveTerritory=1 and ( @sOpsTerritoryId=0 or (@sOpsTerritoryId>0 and SAT.SOpsTerritoryId=@sOpsTerritoryId))

	declare @accountTierCount int
	select @accountTierCount=count(Id)
	from @accountTier
	declare @count int
	set @count=1
	declare @fieldCallPlanPeriodId int
	select @fieldCallPlanPeriodId=SOpsCallPlanPeriodId
	from SOpsCallPlanPeriod
	where SOpsCallPlanId=@callPlanId and Sequence=1

	declare @managerCallPlanPeriodId int
	select @managerCallPlanPeriodId=SOpsCallPlanPeriodId
	from SOpsCallPlanPeriod
	where SOpsCallPlanId=@callPlanId and Sequence=2

	declare @hoCallPlanPeriodId int
	select @hoCallPlanPeriodId=SOpsCallPlanPeriodId
	from SOpsCallPlanPeriod
	where SOpsCallPlanId=@callPlanId and Sequence=3

	begin transaction
	while(@count<=@accountTierCount)
	begin
		declare @accountId int
		declare @recommendedTierId int
		declare @recommendedTierValue nvarchar(200)
		declare @fieldSOpsUserId int
		declare @fieldTerritoryId int
		declare @managerSOpsUserId int
		declare @managerTerritoryId int
		declare @hoSOpsUserId int

		declare @reviewerAccountTierId int
		declare @managerAccountTierId int

		--Get @count's record from account tier table variable
		select @accountId=SOpsAccountId, @recommendedTierId=RecommendedTierId,@recommendedTierValue=RecommendedTierValue, @fieldSOpsUserId=FieldUserId, @fieldTerritoryId=FieldTerritoryId
		from @accountTier
		where Id=@count

		--Get field territory's parent territory SOpsUserId
		select @managerSOpsUserId=SOpsUserId, @managerTerritoryId=SOpsTerritoryId
		from SOpsUserTerritory
		where IsActiveTerritory=1 and SOpsTerritoryId=(select SOpsParentTerritoryId
			from [web].SOpsTerritory
			where SOpsTerritoryId=@fieldTerritoryId)

		if(@managerSOpsUserId is null)
		begin
			select @managerSOpsUserId=SOpsUserId
			from SOpsUserTerritory
			where IsActiveTerritory=1 and SOpsTerritoryId=(select SOpsParentTerritoryId
				from [web].SOpsTerritory
				where SOpsTerritoryId=@managerTerritoryId)
		end

		--Get HO User Id
		select @hoSOpsUserId=SOpsUserId
		from SOpsUserTerritory
		where IsActiveTerritory=1 and SOpsTerritoryId=(select SOpsParentTerritoryId
			from [web].SOpsTerritory
			where SOpsTerritoryId=@managerTerritoryId)

		if(@hoSOpsUserId is null)
		begin
			set @hoSOpsUserId=@managerSOpsUserId
		end
		
		insert into [web].SOpsCallPlanOneLevelAccountTier ( SOpsCallPlanId,FieldTerritoryId,SOpsAccountId,LevelOneUserId,LevelOneSOpsCallPlanPeriodId,LevelOneTierId,LevelOneUpdateDate,LevelTwoUserId,LevelTwoSOpsCallPlanPeriodId,LevelTwoUpdateDate,LevelThreeUserId,LevelThreeSOpsCallPlanPeriodId,LevelThreeUpdateDate)
			values (@callPlanId,@fieldTerritoryId,@accountId,@fieldSOpsUserId,@fieldCallPlanPeriodId,@recommendedTierId,GETUTCDATE(),@managerSOpsUserId,@managerCallPlanPeriodId,GETUTCDATE(),@hoSOpsUserId,@hoCallPlanPeriodId,GETUTCDATE())
		insert into  [web].[SOpsAccountTierAudit] ([SOpsCallPlanId],[SOpsCallPlanPeriodId],[SOpsTerritoryId],[SOpsAccountId],[NewTier],[CreatorType],[CreatedDate])
			values (@callPlanId,@fieldCallPlanPeriodId,@fieldTerritoryId,@accountId,@recommendedTierValue,'SYS',GETUTCDATE())

		set @count=@count+1
	end
	exec [web].SOps_UpdateSOpsTerritoryForLiveCallPlan 0,@callPlanId
	if(@@ERROR=0)
	begin
		commit transaction
	end
	else
	begin
		rollback transaction
	end
end
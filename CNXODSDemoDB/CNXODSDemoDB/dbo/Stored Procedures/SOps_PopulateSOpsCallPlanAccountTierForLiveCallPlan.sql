
create proc SOps_PopulateSOpsCallPlanAccountTierForLiveCallPlan(
	@sOpsTerritoryId int,
	@callPlanId int
)
as
begin
	declare @callPlanLevelOfApproval nvarchar(4)
	select @callPlanLevelOfApproval=LevelOfApproval from SOpsCallPlan where SOpsCallPlanId=@callPlanId

	declare  @accountTier table
	(
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[SOpsAccountId] [int] NOT NULL,
		[FieldTerritoryId] [int] NOT NULL,
		[RecommendedTierId] [int]  null,
		[FieldUserId] [int] NOT NULL,
		primary key (Id)
	)

	--Populate account tier table variable
	insert into @accountTier
		(SOpsAccountId,FieldTerritoryId,FieldUserId,RecommendedTierId)
	select SAT.SOpsAccountId, SAT.SOpsTerritoryId, FieldUT.SOpsUserId, Acc.RecommendedTierId
	from SOpsAccountTerritory SAT
		inner join SOpsUserTerritory FieldUT on FieldUT.SOpsTerritoryId=SAT.SOpsTerritoryId
		inner join SOpsAccount Acc on SAT.SOpsAccountId=Acc.SOpsAccountId
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
		declare @fieldSOpsUserId int
		declare @fieldTerritoryId int
		declare @managerSOpsUserId int
		declare @managerTerritoryId int
		declare @hoSOpsUserId int

		declare @reviewerAccountTierId int
		declare @managerAccountTierId int

		--Get @count's record from account tier table variable
		select @accountId=SOpsAccountId, @recommendedTierId=RecommendedTierId, @fieldSOpsUserId=FieldUserId, @fieldTerritoryId=FieldTerritoryId
		from @accountTier
		where Id=@count

		--Get field territory's parent territory SOpsUserId
		select @managerSOpsUserId=SOpsUserId, @managerTerritoryId=SOpsTerritoryId
		from SOpsUserTerritory
		where IsActiveTerritory=1 and SOpsTerritoryId=(select SOpsParentTerritoryId
			from SOpsTerritory
			where SOpsTerritoryId=@fieldTerritoryId)

		if(@managerSOpsUserId is null)
		begin
			select @managerSOpsUserId=SOpsUserId
			from SOpsUserTerritory
			where IsActiveTerritory=1 and SOpsTerritoryId=(select SOpsParentTerritoryId
				from SOpsTerritory
				where SOpsTerritoryId=@managerTerritoryId)
		end

		--Get HO User Id
		select @hoSOpsUserId=SOpsUserId
		from SOpsUserTerritory
		where IsActiveTerritory=1 and SOpsTerritoryId=(select SOpsParentTerritoryId
			from SOpsTerritory
			where SOpsTerritoryId=@managerTerritoryId)

		if(@hoSOpsUserId is null)
		begin
			set @hoSOpsUserId=@managerSOpsUserId
		end
		--Populate SOpsCallPlanAccountTier because call plan is all level approval type
		if(@callPlanLevelOfApproval='ALL')
		begin
			--Populate account tier record for field user
			insert into SOpsCallPlanAccountTier
				(SOpsUserId,FieldUserId,FieldTerritoryId,SOpsAccountId,SOpsAccountTierId,CreatedDate,SOpsCallPlanPeriodId)
			select @fieldSOpsUserId, @fieldSOpsUserId, @fieldTerritoryId, @accountId, @recommendedTierId, GETDATE(), @fieldCallPlanPeriodId
			from SOpsUser
			where SOpsUserId=@fieldSOpsUserId

			--Get field user account tier record's id
			set @reviewerAccountTierId=@@IDENTITY
			--Populate account tier record for field user's manager
			insert into SOpsCallPlanAccountTier
				(ParentSOpsCallPlanAccountTierId,SOpsUserId,FieldUserId,FieldTerritoryId,SOpsAccountId,CreatedDate,SOpsCallPlanPeriodId)
			select @reviewerAccountTierId, @managerSOpsUserId, @fieldSOpsUserId, @fieldTerritoryId, @accountId, GETDATE(), @managerCallPlanPeriodId
			from SOpsUser
			where SOpsUserId=@managerSOpsUserId

			--Get field user's manager's account tier record's id
			set @managerAccountTierId=@@IDENTITY
			--Populate account tier record for HO user
			insert into SOpsCallPlanAccountTier
				(ParentSOpsCallPlanAccountTierId,SOpsUserId,FieldUserId,FieldTerritoryId,SOpsAccountId,CreatedDate,SOpsCallPlanPeriodId)
			values
				(@managerAccountTierId, @hoSOpsUserId, @fieldSOpsUserId, @fieldTerritoryId, @accountId, GETDATE(), @hoCallPlanPeriodId)
		end
		--Populate SOpsCallPlanOneLevelAccountTier because call plan is one level approval type
		else if(@callPlanLevelOfApproval='ONE')
		begin
			insert into SOpsCallPlanOneLevelAccountTier ( SOpsCallPlanId,FieldTerritoryId,SOpsAccountId,LevelOneUserId,LevelOneSOpsCallPlanPeriodId,LevelOneTierId,LevelOneUpdateDate,LevelTwoUserId,LevelTwoSOpsCallPlanPeriodId,LevelTwoUpdateDate,LevelThreeUserId,LevelThreeSOpsCallPlanPeriodId,LevelThreeUpdateDate)
				values (@callPlanId,@fieldTerritoryId,@accountId,@fieldSOpsUserId,@fieldCallPlanPeriodId,@recommendedTierId,GETUTCDATE(),@managerSOpsUserId,@managerCallPlanPeriodId,GETUTCDATE(),@hoSOpsUserId,@hoCallPlanPeriodId,GETUTCDATE())
		end
		set @count=@count+1
	end
	exec SOps_UpdateSOpsUserForLiveCallPlan 0,@callPlanId
	if(@@ERROR=0)
	begin
		commit transaction
	end
	else
	begin
		rollback transaction
	end
end
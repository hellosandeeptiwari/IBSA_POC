create proc SOps_PopulateCallPlanPeriodUserSubmission(
	@previousCallPlanPeriodId int
)
as
begin
	declare  @userIds table
	(
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[SOpsUserId] [int] NOT NULL,
		[SOpsTerritoryId] [int] NOT NULL,
		primary key (Id)
	)

	--get non-submitted user ids for previous callPlan period
	declare @callPlanLevelOfApproval nvarchar(4)
	select @callPlanLevelOfApproval=LevelOfApproval from SOpsCallPlan where SOpsCallPlanId=
		(select SOpsCallPlanId from SOpsCallPlanPeriod where SOpsCallPlanPeriodId= @previousCallPlanPeriodId)
	
	if(@callPlanLevelOfApproval='ALL')
	begin
		insert into @userIds (SOpsUserId,SOpsTerritoryId) 
		select distinct SOpsUserId,FieldTerritoryId from SOpsCallPlanAccountTier  ACT
		where ACT.SOpsCallPlanPeriodId=@previousCallPlanPeriodId and
			0=(select COUNT(*) from SOpsCallPlanPeriodUserSubmission subm where 
				subm.SOpsCallPlanPeriodId=@previousCallPlanPeriodId and subm.SOpsUserId=act.SOpsUserId and subm.SOpsTerritoryId=act.FieldTerritoryId)
	end
	else if(@callPlanLevelOfApproval='ONE')
	begin
		declare @sequence int
		select @sequence=Sequence from SOpsCallPlanPeriod where SOpsCallPlanPeriodId=@previousCallPlanPeriodId
		if(@sequence=1)
		begin
			insert into @userIds (SOpsUserId,SOpsTerritoryId) 
			select distinct LevelOneUserId as 'SOpsUserId',FieldTerritoryId from SOpsCallPlanOneLevelAccountTier  ACT
				where ACT.LevelOneSOpsCallPlanPeriodId=@previousCallPlanPeriodId and
					0=(select COUNT(*) from SOpsCallPlanPeriodUserSubmission subm where 
						subm.SOpsCallPlanPeriodId=@previousCallPlanPeriodId and subm.SOpsUserId=act.LevelOneUserId and subm.SOpsTerritoryId=act.FieldTerritoryId)
		end
		else if(@sequence=2)
		begin
			insert into @userIds (SOpsUserId,SOpsTerritoryId) 
			select distinct LevelTwoUserId as 'SOpsUserId',FieldTerritoryId from SOpsCallPlanOneLevelAccountTier  ACT
			where ACT.LevelTwoSOpsCallPlanPeriodId=@previousCallPlanPeriodId and
				0=(select COUNT(*) from SOpsCallPlanPeriodUserSubmission subm where 
					subm.SOpsCallPlanPeriodId=@previousCallPlanPeriodId and subm.SOpsUserId=act.LevelTwoUserId and subm.SOpsTerritoryId=act.FieldTerritoryId)
		end
		else if(@sequence=3)
		begin
			insert into @userIds (SOpsUserId,SOpsTerritoryId) 
			select distinct LevelThreeUserId as 'SOpsUserId',FieldTerritoryId from SOpsCallPlanOneLevelAccountTier  ACT
			where ACT.LevelThreeSOpsCallPlanPeriodId=@previousCallPlanPeriodId and
				0=(select COUNT(*) from SOpsCallPlanPeriodUserSubmission subm where 
					subm.SOpsCallPlanPeriodId=@previousCallPlanPeriodId and subm.SOpsUserId=act.LevelThreeUserId and subm.SOpsTerritoryId=act.FieldTerritoryId)
		end
	end
	begin transaction
	insert into SOpsCallPlanPeriodUserSubmission (SOpsCallPlanPeriodId,Status,SOpsUserId,SOpsTerritoryId,SubmissionDate)
		select @previousCallPlanPeriodId,'SSUB',SOpsUserId,SOpsTerritoryId,GETDATE() from @userIds
	
	if(@@ERROR=0)
	begin
		commit transaction
	end
	else
	begin
		rollback transaction
	end
end
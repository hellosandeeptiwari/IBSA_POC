create proc [web].SOps_ProcessCallPlanData
(
	@callPlanId int,
	@repPeriodActualStartDate date
)
as
begin
	begin transaction
		truncate table [web].SOpsAccountTierAudit
		truncate table [web].SOpsCallPlanOneLevelAccountTier
		truncate table [web].SOpsAccountReview
		truncate table [web].SOpsCallPlanPeriodUserSubmission
		exec [web].SOps_PopulateSOpsAccountReviewForLiveCallPlan @callPlanId
		exec [web].SOps_PopulateSOpsCallPlanAccountTierForLiveCallPlan 0,@callPlanId
		update CP
			set CP.CurrentCallPlanPeriodId= CPP.SOpsCallPlanPeriodId
			from [web].SOpsCallPlan CP
			inner join [web].SOpsCallPlanPeriod CPP on CP.SOpsCallPlanId=CPP.SOpsCallPlanId
			where CP.SOpsCallPlanId=@callPlanId and CPP.Sequence=1

		update [web].SOpsCallPlanPeriod set ActualStartDate=@repPeriodActualStartDate where SOpsCallPlanId=@callPlanId and Sequence=1
		if(@@ERROR=0)
		begin
			commit transaction
		end
		else
		begin
			rollback transaction
			update [web].SOpsCallPlan set Status='EROR' where SOpsCallPlanId=@callPlanId
		end
end

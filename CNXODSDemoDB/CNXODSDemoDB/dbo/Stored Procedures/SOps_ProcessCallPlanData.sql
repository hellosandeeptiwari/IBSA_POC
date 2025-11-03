
create proc [dbo].[SOps_ProcessCallPlanData]
(
	@callPlanId int
)
as
begin
	begin transaction
		truncate table SOpsCallPlanAccountTier
		truncate table SOpsCallPlanOneLevelAccountTier
		truncate table SOpsAccountReview
		truncate table SOpsCallPlanPeriodUserSubmission
		exec SOps_PopulateSOpsAccountReviewForLiveCallPlan @callPlanId
		exec SOps_PopulateSOpsCallPlanAccountTierForLiveCallPlan 0,@callPlanId
		if(@@ERROR=0)
		begin
			commit transaction
		end
		else
		begin
			rollback transaction
			update SOpsCallPlan set Status='EROR' where SOpsCallPlanId=@callPlanId
		end
end

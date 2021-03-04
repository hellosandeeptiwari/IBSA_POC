drop proc [web].SOps_ProcessCallPlanHistoryData
GO
create proc [web].SOps_ProcessCallPlanHistoryData
(
	@callPlanId int
)
as
begin
	begin transaction

		--declare @callPlanId int
		--set @callPlanId=9

		--SOpsCallPlan
		insert into web.SOpsCallPlanHistory  
			( Name,StartDate,EndDate,PeriodStartDate,PeriodEndDate,TotalWorkingdays,TotalHolidays,TotalWeekends, TimeZone,Description,CreatedBy,CreatedDate,SourceId)
		select Name,StartDate,EndDate,PeriodStartDate,PeriodEndDate,TotalWorkingdays,TotalHolidays,TotalWeekends, TimeZone,Description,CreatedBy,CreatedDate,SOpsCallPlanId
			 from web.SOpsCallPlan where SOpsCallPlanId=@callPlanId

		declare @historyCallPlanId int 
		set @historyCallPlanId= @@Identity
		--SOpsUser
		insert into web.SOpsUserHistory  (SOpsCallPlanId, Email,OdsUserId,DisplayName,OdsManagerUserId,ExternalId1,ExternalId2,SourceId)
		select @historyCallPlanId,Email,OdsUserId,DisplayName,OdsManagerUserId,ExternalId1,ExternalId2,SOpsUserId  from web.SOpsUser 

		--SOpsTerritory
		insert into web.[SOpsTerritoryHistory]  (SOpsCallPlanId,Name,Description,SOpsParentTerritoryId,OdsTerritoryId,OdsParentTerritoryId,CurrentTargetCount,CurrentNonTargetCount,FutureTargetCount,FutureNonTargetCount,NumberOfCurrentTotalCalls,NumberOfCurrentAverageCalls,NumberOfFutureTotalCalls,NumberOfFutureAverageCalls,Status,SourceId)
		select @historyCallPlanId,Name,Description,SOpsParentTerritoryId,OdsTerritoryId,OdsParentTerritoryId,CurrentTargetCount,CurrentNonTargetCount,FutureTargetCount,FutureNonTargetCount,NumberOfCurrentTotalCalls,NumberOfCurrentAverageCalls,NumberOfFutureTotalCalls,NumberOfFutureAverageCalls,Status,SOpsTerritoryId from web.[SOpsTerritory] 

		--Updating SOpsParentTerritoryId to new [SOpsTerritoryHistory]'s record Id
		 UPDATE t 
			SET t.SOpsParentTerritoryId = t2.SOpsTerritoryId 
			FROM web.[SOpsTerritoryHistory] t 
			INNER JOIN web.[SOpsTerritoryHistory] t2 ON t.SOpsParentTerritoryId = t2.SourceId 
			WHERE t.SOpsParentTerritoryId is not null AND 
					t.SOpsCallPlanId = @historyCallPlanId and
					t2.SOpsCallPlanId = @historyCallPlanId 

		--SOpsUserTerritory
		insert into web.[SOpsUserTerritoryHistory]  (SOpsCallPlanId,SOpsUserId,SOpsTerritoryId,IsActiveTerritory,SourceId)
		select @historyCallPlanId,U.SOpsUserId,T.SOpsTerritoryId,UT.IsActiveTerritory,SOpsUserTerritoryId from web.[SOpsUserTerritory] UT
			inner join web.[SOpsUserHistory] U on UT.SOpsUserId=U.SourceId
			inner join  web.[SOpsTerritoryHistory] T on UT.SOpsTerritoryId=T.SourceId
			where U.SOpsCallPlanId=@historyCallPlanId and 
					T.SOpsCallPlanId=@historyCallPlanId

		--SOpsCallPlanPeriodHistory
		insert into web.[SOpsCallPlanPeriodHistory]  (SOpsCallPlanId,LevelCode,Description,PlannedStartDate,PlannedEndDate,ActualStartDate,ActualEndDate,Sequence,UILabel,SourceId)
		select @historyCallPlanId,LevelCode,Description,PlannedStartDate,PlannedEndDate,ActualStartDate,ActualEndDate,Sequence,UILabel,SOpsCallPlanPeriodId
			from web.[SOpsCallPlanPeriod] where SOpsCallPlanId=@callPlanId

		--SOpsCallPlanPeriodUserSubmissionHistory
		insert into web.[SOpsCallPlanPeriodUserSubmissionHistory] (SOpsCallPlanId,SOpsCallPlanPeriodId,Status,SOpsUserId,SOpsTerritoryId,SubmissionDate,SourceId)
		select @historyCallPlanId,P.SOpsCallPlanPeriodId,US.Status,U.SOpsUserId,T.SOpsTerritoryId,US.SubmissionDate,US.SOpsCallPlanPeriodUserSubmissionId
			from web.[SOpsCallPlanPeriodUserSubmission] US
			inner join web.[SOpsCallPlanPeriodHistory] P on US.SOpsCallPlanPeriodId=P.SourceId
			inner join web.[SOpsUserHistory] U on US.SOpsUserId=U.SourceId
			inner join  web.[SOpsTerritoryHistory] T on US.SOpsTerritoryId=T.SourceId
			where P.SOpsCallPlanId=@historyCallPlanId and 
					U.SOpsCallPlanId=@historyCallPlanId and 
					T.SOpsCallPlanId=@historyCallPlanId

		--SopsSpecialtyHistory
		insert into web.[SopsSpecialtyHistory] (SOpsCallPlanId,SpecialtyType,SourceId)
		select @historyCallPlanId,SpecialtyType,SopsSpecialtyId from web.[SopsSpecialty]

		--SOpsAccountTierHistory
		insert into web.[SOpsAccountTierHistory] (SOpsCallPlanId,FutureCallPlanTier,Value,NumberOfCalls,Sequence,IsChangeCommentRequired,SourceId)
		select @historyCallPlanId,FutureCallPlanTier,Value,NumberOfCalls,Sequence,IsChangeCommentRequired,SOpsAccountTierId from web.[SOpsAccountTier]

		--SOpsAccountHistory
		insert into web.[SOpsAccountHistory]  
			(SOpsCallPlanId,OdsAccountId,Name,S.SopsSpecialtyId,RecommendedTierId,AccountType,
			ExternalId1,ExternalId2,ExternalId3,ExternalId4,ExternalId5,ExternalId6,ExternalId7,ExternalId8,SourceId)
		select @historyCallPlanId,OdsAccountId,Name,S.SopsSpecialtyId,RT.SOpsAccountTierId,AccountType,
			ExternalId1,ExternalId2,ExternalId3,ExternalId4,ExternalId5,ExternalId6,ExternalId7,ExternalId8,SOpsAccountId
			from web.[SOpsAccount] A
			inner join web.[SopsSpecialtyHistory] S on A.SopsSpecialtyId=S.SourceId
			inner join web.[SOpsAccountTierHistory] RT on A.RecommendedTierId=RT.SourceId
			where S.SOpsCallPlanId=@historyCallPlanId and 
					RT.SOpsCallPlanId=@historyCallPlanId

		--SOpsAddressHistory
		insert into web.[SOpsAddressHistory] (SOpsCallPlanId,OdsAddressId,AddressLine1,AddressLine2,City,State,Country,ZipCode,SourceId)
		select @historyCallPlanId,OdsAddressId,AddressLine1,AddressLine2,City,State,Country,ZipCode,SOpsAddressId
			from web.[SOpsAddress]

		--SOpsAccountAddressHistory
		insert into web.[SOpsAccountAddressHistory]  
			(SOpsCallPlanId,SOpsAccountId,SOpsAddressId,Status,SourceId)
		select @historyCallPlanId,Acc.SOpsAccountId,Ad.SOpsAddressId,AA.Status,AA.SOpsAccountAddressId
			from web.[SOpsAccountAddress] AA
			inner join web.[SOpsAccountHistory] Acc on AA.SOpsAccountId=Acc.SourceId
			inner join web.[SOpsAddressHistory] Ad on AA.SOpsAddressId=Ad.SourceId
			where Acc.SOpsCallPlanId=@historyCallPlanId and
					Ad.SOpsCallPlanId=@historyCallPlanId

		--SOpsAccountTerritoryHistory
		insert into web.[SOpsAccountTerritoryHistory]  
			(SOpsCallPlanId,SOpsAccountId,SOpsTerritoryId,SopsAddressId,CurrentTierId,FutureTierId,SourceId)
		select @historyCallPlanId,Acc.SOpsAccountId,T.SOpsTerritoryId,Ad.SOpsAddressId,CT.SOpsAccountTierId,FT.SOpsAccountTierId,AT.SOpsAccountTerritoryId
			from web.[SOpsAccountTerritory] AT
			inner join web.[SOpsAccountHistory] Acc on AT.SOpsAccountId=Acc.SourceId
			inner join web.[SOpsAddressHistory] Ad on AT.SOpsAddressId=Ad.SourceId
			inner join web.[SOpsTerritoryHistory] T on AT.SOpsTerritoryId=T.SourceId
			inner join web.[SOpsAccountTierHistory] CT on AT.CurrentTierId=CT.SourceId
			inner join web.[SOpsAccountTierHistory] FT on AT.FutureTierId=FT.SourceId
			where Acc.SOpsCallPlanId=@historyCallPlanId and 
					Ad.SOpsCallPlanId=@historyCallPlanId and 
					T.SOpsCallPlanId=@historyCallPlanId and 
					CT.SOpsCallPlanId=@historyCallPlanId and 
					FT.SOpsCallPlanId=@historyCallPlanId

		--SOpsAccountReviewHistory
		insert into web.[SOpsAccountReviewHistory]  
			(SOpsCallPlanId,SOpsTerritoryId,SOpsAccountId,AccountName,CRMId,AddressLine1,City,State,Specialty,CurrentTierValue,RecommendedTierValue,ExternalId1,ExternalId2,ExternalId3,ExternalId4,ExternalId5,ExternalId6,ExternalId7,ExternalId8,SourceId)
		select @historyCallPlanId,T.SOpsTerritoryId,Acc.SOpsAccountId,AR.AccountName,AR.CRMId,AR.AddressLine1,AR.City,AR.State,AR.Specialty,AR.CurrentTierValue,AR.RecommendedTierValue,AR.ExternalId1,AR.ExternalId2,AR.ExternalId3,AR.ExternalId4,AR.ExternalId5,AR.ExternalId6,AR.ExternalId7,AR.ExternalId8,AR.SOpsReviewSupportId
			from web.[SOpsAccountReview] AR
			inner join web.[SOpsAccountHistory] Acc on AR.SOpsAccountId=Acc.SourceId
			inner join web.[SOpsTerritoryHistory] T on AR.SOpsTerritoryId=T.SourceId
			where Acc.SOpsCallPlanId=@historyCallPlanId and T.SOpsCallPlanId=@historyCallPlanId

		--SOpsCallPlanOneLevelAccountTierHistory
		insert into web.[SOpsCallPlanOneLevelAccountTierHistory]  
			(SOpsCallPlanId,FieldTerritoryId,SOpsAccountId,
			LevelOneUserId,LevelOneSOpsCallPlanPeriodId,LevelOneTierId,LevelOneComment,LevelOneComment2,LevelOneComment3,LevelOneCommentCode,LevelOneCommentCode3,LevelOneUpdateDate,
			LevelTwoUserId,LevelTwoSOpsCallPlanPeriodId,LevelTwoTierId,LevelTwoComment,LevelTwoComment2,LevelTwoComment3,LevelTwoCommentCode,LevelTwoCommentCode3,LevelTwoUpdateDate,
			LevelThreeUserId,LevelThreeSOpsCallPlanPeriodId,LevelThreeTierId,LevelThreeComment,LevelThreeComment2,LevelThreeComment3,LevelThreeCommentCode,LevelThreeCommentCode3,LevelThreeUpdateDate,
			SourceId)
		select @historyCallPlanId,T.SOpsTerritoryId,Acc.SOpsAccountId,
			U1.SOpsUserId,P1.SOpsCallPlanPeriodId,T1.SOpsAccountTierId,LevelOneComment,LevelOneComment2,LevelOneComment3,LevelOneCommentCode,LevelOneCommentCode3,LevelOneUpdateDate,
			U2.SOpsUserId,P2.SOpsCallPlanPeriodId,T2.SOpsAccountTierId,LevelTwoComment,LevelTwoComment2,LevelTwoComment3,LevelTwoCommentCode,LevelTwoCommentCode3,LevelTwoUpdateDate,
			U3.SOpsUserId,P3.SOpsCallPlanPeriodId,T3.SOpsAccountTierId,LevelThreeComment,LevelThreeComment2,LevelThreeComment3,LevelThreeCommentCode,LevelThreeCommentCode3,LevelThreeUpdateDate,
			AO.SOpsCallPlanOneLevelAccountTierId
			from web.[SOpsCallPlanOneLevelAccountTier] AO
			inner join web.[SOpsAccountHistory] Acc on AO.SOpsAccountId=Acc.SourceId
			inner join web.[SOpsTerritoryHistory] T on AO.FieldTerritoryId=T.SourceId
			inner join web.[SOpsUserHistory] U1 on AO.LevelOneUserId=U1.SourceId
			inner join web.[SOpsUserHistory] U2 on AO.LevelTwoUserId=U2.SourceId
			inner join web.[SOpsUserHistory] U3 on AO.LevelThreeUserId=U3.SourceId
			inner join web.[SOpsAccountTierHistory] T1 on AO.LevelOneTierId=T1.SourceId
			inner join web.[SOpsAccountTierHistory] T2 on AO.LevelTwoTierId=T2.SourceId
			inner join web.[SOpsAccountTierHistory] T3 on AO.LevelThreeTierId=T3.SourceId
			inner join web.[SOpsCallPlanPeriodHistory] P1 on AO.LevelOneSOpsCallPlanPeriodId=P1.SourceId
			inner join web.[SOpsCallPlanPeriodHistory] P2 on AO.LevelTwoSOpsCallPlanPeriodId=P2.SourceId
			inner join web.[SOpsCallPlanPeriodHistory] P3 on AO.LevelThreeSOpsCallPlanPeriodId=P3.SourceId
			where Acc.SOpsCallPlanId=@historyCallPlanId and 
			T.SOpsCallPlanId=@historyCallPlanId and 
			U1.SOpsCallPlanId=@historyCallPlanId and 
			U2.SOpsCallPlanId=@historyCallPlanId and 
			U3.SOpsCallPlanId=@historyCallPlanId and 
			T1.SOpsCallPlanId=@historyCallPlanId and 
			T2.SOpsCallPlanId=@historyCallPlanId and 
			T3.SOpsCallPlanId=@historyCallPlanId and 
			P1.SOpsCallPlanId=@historyCallPlanId and 
			P2.SOpsCallPlanId=@historyCallPlanId and 
			P3.SOpsCallPlanId=@historyCallPlanId


		--SOpsAccountTierAuditHistory
		insert into web.[SOpsAccountTierAuditHistory]  
			(SOpsCallPlanId,SOpsCallPlanPeriodId,SOpsTerritoryId,SOpsAccountId,SOpsUserId,PlatformUserId,PlatformEmail,OldTier,NewTier,Comment,Comment2,CreatorType,CreatedDate,SourceId)
		select @historyCallPlanId,P.SOpsCallPlanPeriodId,T.SOpsTerritoryId,Acc.SOpsAccountId,U.SOpsUserId,A.PlatformUserId,A.PlatformEmail,A.OldTier,A.NewTier,A.Comment,A.Comment2,A.CreatorType,A.CreatedDate,A.SOpsAccountTierAuditId
			from web.[SOpsAccountTierAudit] A
			inner join web.[SOpsCallPlanPeriodHistory] P on A.SOpsCallPlanPeriodId=P.SourceId
			inner join web.[SOpsTerritoryHistory] T on A.SOpsTerritoryId=T.SourceId
			inner join web.[SOpsAccountHistory] Acc on A.SOpsAccountId=Acc.SourceId
			inner join web.[SOpsUserHistory] U on A.SOpsUserId=U.SourceId
			where P.SOpsCallPlanId=@historyCallPlanId and 
					T.SOpsCallPlanId=@historyCallPlanId and
					Acc.SOpsCallPlanId=@historyCallPlanId and
					U.SOpsCallPlanId=@historyCallPlanId 

		--SOpsCallPlanOneLevelAccountTierDynamicHistory
		insert into web.[SOpsCallPlanOneLevelAccountTierDynamicHistory]  
			(SOpsCallPlanId,SOpsCallPlanOneLevelAccountTierId,SOpsCallPlanPeriodId,FieldTerritoryId,SOpsAccountId,SOpsUserId,TextField1,TextField2,TextField3,TextField4,TextField5,TextField6,TextField7,TextField8,TextField9,TextField10,TextField11,TextField12,TextField13,TextField14,TextField15,TextField16,TextField17,TextField18,TextField19,TextField20,CodeField1,CodeField2,CodeField3,CodeField4,CodeField5,SourceId)
		select @historyCallPlanId,ACT.SOpsCallPlanOneLevelAccountTierId,P.SOpsCallPlanPeriodId,T.SOpsTerritoryId,Acc.SOpsAccountId,U.SOpsUserId,A.TextField1,A.TextField2,A.TextField3,A.TextField4,A.TextField5,A.TextField6,A.TextField7,A.TextField8,A.TextField9,A.TextField10,A.TextField11,A.TextField12,A.TextField13,A.TextField14,A.TextField15,A.TextField16,A.TextField17,A.TextField18,A.TextField19,A.TextField20,A.CodeField1,A.CodeField2,A.CodeField3,A.CodeField4,A.CodeField5,A.SOpsCallPlanOneLevelAccountTierDynamicId
			from web.[SOpsCallPlanOneLevelAccountTierDynamic] A
			inner join web.[SOpsCallPlanOneLevelAccountTierHistory] ACT on A.SOpsCallPlanOneLevelAccountTierId=ACT.SourceId
			inner join web.[SOpsCallPlanPeriodHistory] P on A.SOpsCallPlanPeriodId=P.SourceId
			inner join web.[SOpsTerritoryHistory] T on A.FieldTerritoryId=T.SourceId
			inner join web.[SOpsAccountHistory] Acc on A.SOpsAccountId=Acc.SourceId
			inner join web.[SOpsUserHistory] U on A.SOpsUserId=U.SourceId
			where ACT.SOpsCallPlanId=@historyCallPlanId and 
					P.SOpsCallPlanId=@historyCallPlanId and
					T.SOpsCallPlanId=@historyCallPlanId and
					Acc.SOpsCallPlanId=@historyCallPlanId and
					U.SOpsCallPlanId=@historyCallPlanId 

		if(@@ERROR=0)
		begin
			commit transaction
		end
		else
		begin
			rollback transaction
		end
end
GO
--SSUB- System submitted
--USUB – User Submitted

create proc  [web].[uspTargetSettingReportList]
as
begin	

	select RT.Name as 'RepTerritory', Rep.DisplayName as 'RepName', SACT1.AccountCount as 'AccountCount',
	   case when  SACT2.UpdatedCount is not null THEN SACT2.UpdatedCount else	0 end as 'RepUpdatedCount',
	   case when RST.Status is not null then RST.Status else 'PEND' end as 'RepStatus',
	   MT.Name as 'ManagerTerritory', MGR.DisplayName as 'ManagerName', MGR.Email as 'ManagerEmail',
	   case when  SACT3.UpdatedCount is not null THEN SACT3.UpdatedCount else	0 end as 'ManagerUpdatedCount',
	   case when MST.Status is not null then MST.Status else 'REVI' end as 'ManagerStatus',
	   HT.Name as 'HOTerritory', HO.DisplayName as 'HOName', HO.email as 'HOEmail',
	   case when  SACT4.UpdatedCount is not null THEN SACT4.UpdatedCount else	0 end as 'HOUpdatedCount',
	   case when HST.Status is not null then HST.Status else 'REVI' end as 'HOStatus'
	from
	   (select FieldTerritoryId, LevelOneUserId as 'SOpsUserId', count(*) as AccountCount
	   from web.SOpsCallPlanOneLevelAccountTier
	   group by FieldTerritoryId,LevelOneUserId) SACT1
	   left join
	   (select FieldTerritoryId, LevelOneUserId as 'SOpsUserId', count(*) as UpdatedCount
	   from web.SOpsCallPlanOneLevelAccountTier A1
	   inner join web.SOpsAccount A2 on A1.SOpsAccountId=A2.SOpsAccountId
	   where A2.RecommendedTierId!=A1.LevelOneTierId and LevelOneComment is not null
	   group by FieldTerritoryId,LevelOneUserId) SACT2
	   on SACT1.FieldTerritoryId=SACT2.FieldTerritoryId
	   left join
	   (select FieldTerritoryId, LevelOneUserId as 'SOpsUserId', count(*) as UpdatedCount
	   from web.SOpsCallPlanOneLevelAccountTier
	   where LevelTwoComment is not null
	   group by FieldTerritoryId,LevelOneUserId) SACT3
	   on SACT1.FieldTerritoryId=SACT3.FieldTerritoryId
	   left join
	   (select FieldTerritoryId, LevelOneUserId as 'SOpsUserId', count(*) as UpdatedCount
	   from web.SOpsCallPlanOneLevelAccountTier
	   where LevelThreeComment is not null
	   group by FieldTerritoryId,LevelOneUserId) SACT4
	   on SACT1.FieldTerritoryId=SACT4.FieldTerritoryId
	   inner join web.SOpsTerritory RT on SACT1.FieldTerritoryId=RT.SOpsTerritoryId
	   inner join web.SOpsTerritory MT on MT.SOpsTerritoryId=RT.SOpsParentTerritoryId
	   inner join web.SOpsTerritory HT on HT.SOpsTerritoryId=MT.SOpsParentTerritoryId
	   inner join web.SOpsUser Rep on SACT1.SOpsUserId=Rep.SOpsUserId
	   inner join web.SOpsUser MGR on MGR.SOpsUserId in (select SOpsUserId
	   from web.SOpsUserTerritory
	   where SOpsTerritoryId=MT.SOpsTerritoryId)
	   inner join web.SOpsUser HO on HO.SOpsUserId in (select SOpsUserId
	   from web.SOpsUserTerritory
	   where SOpsTerritoryId=HT.SOpsTerritoryId)
	   left join web.SOpsCallPlanPeriodUserSubmission RST on RST.SOpsUserId=Rep.SOpsUserId and RST.SOpsTerritoryId=RT.SOpsTerritoryId
	   left join web.SOpsCallPlanPeriodUserSubmission MST on MST.SOpsUserId=MGR.SOpsUserId and MST.SOpsTerritoryId=RT.SOpsTerritoryId
	   left join web.SOpsCallPlanPeriodUserSubmission HST on HST.SOpsUserId=HO.SOpsUserId and HST.SOpsTerritoryId=RT.SOpsTerritoryId
	order by RT.Name
end
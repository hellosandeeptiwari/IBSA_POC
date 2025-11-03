CREATE OR ALTER PROC [dbo].[sp_veev_asyncapexjob_transfrom]
AS
BEGIN

	UPDATE AJ
	SET AJ.[ApexClassId] = AA.[ApexClassId],
		AJ.[CompletedDate] = AA.[CompletedDate],
		AJ.[CreatedById] = AA.[CreatedById],
		AJ.[CreatedDate] = AA.[CreatedDate],
		AJ.[ExtendedStatus] = AA.[ExtendedStatus],
		AJ.[JobItemsProcessed] = AA.[JobItemsProcessed],
		AJ.[JobType] = AA.[JobType],
		AJ.[LastProcessed] = AA.[LastProcessed],
		AJ.[LastProcessedOffset] = AA.[LastProcessedOffset],
		AJ.[MethodName] = AA.[MethodName],
		AJ.[NumberOfErrors] = AA.[NumberOfErrors],
		AJ.[ParentJobId] = AA.[ParentJobId],
		AJ.[Status] = AA.[Status],
		AJ.[TotalJobItems] = AA.[TotalJobItems]
		FROM VEEV_AsyncApexJob AJ
		INNER JOIN Staging_VEEV_AsyncApexJob AA ON AJ.ExternalId1 = AA.Id AND AJ.EndDate IS NULL
		INNER JOIN ConexusCustomer CC ON CC.CustomerId = AJ.CustomerId ;

INSERT INTO [dbo].[VEEV_AsyncApexJob]
           ([AsyncApexJobId]
           ,[ApexClassId]
           ,[CompletedDate]
           ,[CreatedById]
           ,[CreatedDate]
           ,[ExtendedStatus]
           ,[ExternalId1]
           ,[JobItemsProcessed]
           ,[JobType]
           ,[LastProcessed]
           ,[LastProcessedOffset]
           ,[MethodName]
           ,[NumberOfErrors]
           ,[ParentJobId]
           ,[Status]
           ,[TotalJobItems]
           ,[CustomerId])

SELECT NEWID() AS [AsyncApexJobId]
		  ,SVAS.[ApexClassId]
		  ,SVAS.[CompletedDate]
		  ,SVAS.[CreatedById]
		  ,SVAS.[CreatedDate]
		  ,SVAS.[ExtendedStatus]
		  ,SVAS.[Id]
		  ,SVAS.[JobItemsProcessed]
		  ,SVAS.[JobType]
		  ,SVAS.[LastProcessed]
		  ,SVAS.[LastProcessedOffset]
		  ,SVAS.[MethodName]
		  ,SVAS.[NumberOfErrors]
		  ,SVAS.[ParentJobId]
		  ,SVAS.[Status]
		  ,SVAS.[TotalJobItems]
		  ,CC.[CustomerId]
	  FROM [dbo].[Staging_VEEV_AsyncApexJob] SVAS
	  INNER JOIN ConexusCustomer CC ON SVAS.CustomerId = CC.CustomerId
	  WHERE NOT EXISTS(SELECT 1 FROM [VEEV_AsyncApexJob] VAS WHERE VAS.[ExternalId1] = SVAS.Id AND SVAS.[CustomerId]= VAS.[CustomerId] AND VAS.EndDate IS NULL)

END
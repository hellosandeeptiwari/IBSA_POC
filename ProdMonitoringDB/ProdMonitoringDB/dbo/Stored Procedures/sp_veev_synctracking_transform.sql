CREATE OR ALTER PROCEDURE [dbo].[sp_veev_synctracking_transform]
AS
BEGIN
	
	UPDATE ST
	SET ST.[SyncTrackingName] = SST.[Name],
		ST.[CreatedById] = SST.[CreatedById],
		ST.[CreatedDate] = SST.[CreatedDate],
		ST.[IsDeleted] = SST.[IsDeleted],
		ST.[LastModifiedById] = SST.[LastModifiedById],
		ST.[LastModifiedDate] = SST.[LastModifiedDate],
		ST.[MobileId] = SST.[MobileId],
		ST.[Ownerid] = SST.[Ownerid],
		ST.[NumberofRetries] = SST.[NumberofRetries],
		ST.[NumberofUploadErrors] = SST.[NumberofUploadErrors],
		ST.[NumberOfUploads] = SST.[NumberOfUploads],
		ST.[NumberOfVTrans] = SST.[NumberOfVTrans],
		ST.[MediaProcessed] = SST.[MediaProcessed],
		ST.[Cancelled] = SST.[Cancelled],
		ST.[SuccessfulSync] = SST.[SuccessfulSync],
		ST.[SyncDuration] = SST.[SyncDuration],
		ST.[SyncType] = SST.[SyncType],
		ST.[SyncStartDatetime] = SST.[SyncStartDatetime],
		ST.[SyncCompletedDatetime] = SST.[SyncCompletedDatetime],
		ST.[UploadProcessed] = SST.[UploadProcessed],
		ST.[DownloadProcessed] = SST.[DownloadProcessed],
		ST.[Version] = SST.[Version],
		ST.[VInsightsProcessed] = SST.[VInsightsProcessed],
		ST.[SystemModstamp]  = SST.[SystemModstamp]
		FROM VEEV_SyncTracking ST
		INNER JOIN Staging_VEEV_SyncTracking SST ON ST.ExternalId1 = SST.Id AND ST.EndDate IS NULL
		INNER JOIN ConexusCustomer CC ON ST.CustomerId = CC.CustomerId

INSERT INTO [dbo].[VEEV_SyncTracking]
           ([SyncTrackingId]
           ,[ExternalId1]
           ,[SyncTrackingName]
           ,[CreatedById]
           ,[CreatedDate]
           ,[IsDeleted]
           ,[LastModifiedById]
           ,[LastModifiedDate]
           ,[MobileId]
           ,[Ownerid]
           ,[NumberofRetries]
           ,[NumberofUploadErrors]
           ,[NumberOfUploads]
           ,[NumberOfVTrans]
           ,[MediaProcessed]
           ,[Cancelled]
           ,[SuccessfulSync]
           ,[SyncDuration]
           ,[SyncType]
           ,[SyncStartDatetime]
           ,[SyncCompletedDatetime]
           ,[UploadProcessed]
           ,[DownloadProcessed]
           ,[Version]
           ,[VInsightsProcessed]
           ,[SystemModstamp]
           ,[CustomerId])

SELECT NEWID() AS [SyncTrackingId]
		  ,SVS.[Id]
		  ,SVS.[Name]
		  ,SVS.[CreatedById]
		  ,SVS.[CreatedDate]
		  ,SVS.[IsDeleted]
		  ,SVS.[LastModifiedById]
		  ,SVS.[LastModifiedDate]
		  ,SVS.[MayEdit]
		  ,VU.[ExternalId1]
		  ,SVS.[NumberofRetries]
		  ,SVS.[NumberofUploadErrors]
		  ,SVS.[NumberOfUploads]
		  ,SVS.[NumberOfVTrans]
		  ,SVS.[MediaProcessed]
		  ,SVS.[Cancelled]
		  ,SVS.[SuccessfulSync]
		  ,SVS.[SyncDuration]
		  ,SVS.[SyncType]
		  ,SVS.[SyncStartDatetime]
		  ,SVS.[SyncCompletedDatetime]
		  ,SVS.[UploadProcessed]
		  ,SVS.[DownloadProcessed]
		  ,SVS.[Version]
		  ,SVS.[VInsightsProcessed]
		  ,SVS.[SystemModstamp]
		  ,CC.[CustomerId]
	  FROM [dbo].[Staging_VEEV_SyncTracking] SVS
	  INNER JOIN ConexusCustomer CC ON SVS.CustomerId = CC.CustomerId
	  INNER JOIN VEEV_User VU ON SVS.Ownerid = VU.ExternalId1 AND VU.EndDate IS NULL
	  WHERE NOT EXISTS(SELECT 1 FROM VEEV_SyncTracking VS WHERE SVS.Id = VS.[ExternalId1] AND SVS.CustomerId = VS.CustomerId AND VS.EndDate IS NULL  )

END



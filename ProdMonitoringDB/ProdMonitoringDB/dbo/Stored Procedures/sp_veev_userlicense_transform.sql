CREATE PROC [dbo].[sp_veev_userlicense_transform]
as
begin

	UPDATE UL
	SET UL.[LastModifiedDate] = SUL.[LastModifiedDate],
		UL.[LicenseDefinitionKey] = SUL.[LicenseDefinitionKey],
		UL.[MasterLabel] = SUL.[MasterLabel],
		UL.[UserLicenseName] = SUL.[Name],
		UL.[Status] = SUL.[Status],
		UL.[SystemModstamp] = SUL.[SystemModstamp],
		UL.[TotalLicenses] = SUL.[TotalLicenses],
		UL.[UsedLicenses] = SUL.[UsedLicenses],
		UL.[UsedLicensesLastUpdated] = SUL.[UsedLicensesLastUpdated]
		FROM VEEV_UserLicense UL
		INNER JOIN Staging_VEEV_UserLicense SUL ON UL.ExternalId1 = SUL.Id AND UL.EndDate IS NULL
		INNER JOIN ConexusCustomer CC ON CC.CustomerId = UL.CustomerId

INSERT INTO [dbo].[VEEV_UserLicense]
           ([UserLicenseId]
           ,[CreatedDate]
           ,[ExternalId1]
           ,[LastModifiedDate]
           ,[LicenseDefinitionKey]
           ,[MasterLabel]
           ,[UserLicenseName]
           ,[Status]
           ,[SystemModstamp]
           ,[TotalLicenses]
           ,[UsedLicenses]
           ,[UsedLicensesLastUpdated]
           ,[CustomerId])


SELECT NEWID() AS [UserLicenseId]
	  ,SVU.[CreatedDate]
      ,SVU.[Id]
      ,SVU.[LastModifiedDate]
      ,SVU.[LicenseDefinitionKey]
      ,SVU.[MasterLabel]
      ,SVU.[Name]
      ,SVU.[Status]
      ,SVU.[SystemModstamp]
      ,SVU.[TotalLicenses]
      ,SVU.[UsedLicenses]
      ,SVU.[UsedLicensesLastUpdated]
      ,CC.[CustomerId]
  FROM [dbo].[Staging_VEEV_UserLicense] SVU
  INNER JOIN ConexusCustomer CC ON SVU.CustomerId = CC.CustomerId
  WHERE NOT EXISTS(SELECT 1 FROM VEEV_UserLicense VU WHERE SVU.Id = VU.ExternalId1 AND SVU.CustomerId = VU.CustomerId AND VU.EndDate IS NULL)
end
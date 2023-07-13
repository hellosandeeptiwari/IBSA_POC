using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using ODSDataConnector.Core.Models;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using static System.Net.WebRequestMethods;
using System.IO;
using System.Reflection.Metadata;
using Microsoft.Data.SqlClient;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.Azure.Management.ResourceManager;
using Microsoft.Rest;
using Microsoft.Rest.Azure.Authentication;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System.Security.Cryptography;

namespace ODSDataConnector.Core.Services
{
    public class StorageService : IStorageService
    {
        private readonly AppDBContext context;

        private readonly string subscriptionId = "3bf6616d-4f38-4fd4-82ab-51e652c757a9";
        private readonly string clientId = "8349448f-2016-4cf0-b7c7-27c62e9be090";
        private readonly string clientSecret = "x.L8Q~bdcKxbmDsNG.TZYF0MmLUqRnDymCD3haiV";
        private readonly string tenantId = "907cef94-e870-49f6-b843-09417459b152";
        private readonly string strAzureAuthenticationKey = "pjI7Q~EEIGfNY8TLOwRTDjUwaGY65Xi--vCJT";

        public StorageService(AppDBContext appDbContext)
        {
            this.context = appDbContext;
        }

        public async Task<bool> ExcecuteSQLScripts(DataRequest request)
        {
            try
            {

                var cus = this.context.Customers.Where(x => x.Id == request.customerId).FirstOrDefault();
                var dataSource = this.context.DataSources.Where(x => x.Name == request.dataSource && x.Module == request.module && x.Entity == request.entity && x.Version == request.version).FirstOrDefault();

                string connectionString = "DefaultEndpointsProtocol=https;AccountName=odsblobcontainer;AccountKey=EJSJZS/kQFUamEp0w70nJ6yP4CQOwiLjC8abIUtRwdD/EBsxeM3u3nmdTgqA6xrelOX1JLh3Q71WUN7wifzfYA==;EndpointSuffix=core.windows.net";
                BlobServiceClient blobServiceClient = new BlobServiceClient(connectionString);

                string containerName = "odsdataconnector";
                BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient(containerName);

                List<string> tables = containerClient.GetBlobs(prefix: dataSource.StoragePath + "/Tables").Select(b => b.Name).ToList();
                List<string> storeprocedures = containerClient.GetBlobs(prefix: dataSource.StoragePath + "/Storedprocedures").Select(b => b.Name).ToList();

                List<string> scripts = new List<string>();

                foreach (var blob in tables)
                {
                    scripts.Add(await GetBlobContent(blob, containerClient));
                }

                foreach (var blob in storeprocedures)
                {
                    scripts.Add(await GetBlobContent(blob, containerClient));
                }

                var destSQLConnectionString = "Data Source=" + cus.Dbserver + ";Initial Catalog=" + cus.Dbname + ";User Id=" + cus.Username + ";Password=" + cus.Password;
                using (SqlConnection connection = new SqlConnection(destSQLConnectionString))
                {
                    connection.Open();

                    foreach (var script in scripts)
                    {
                        using (SqlCommand command = new SqlCommand(script, connection))
                        {
                            //command.ExecuteNonQuery();
                        }
                    }

                }


                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                #region Linked Servcie Creation Section
                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";


                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sqlLinkedService = new LinkedServiceResource(
                     new AzureSqlDatabaseLinkedService
                     {
                         ConnectionString = "Data Source=" + cus.Dbserver + ";Initial Catalog=" + cus.Dbname + ";User Id=" + cus.Username + ";Password=" + cus.Password
                     }
                );

                // Create or update the SQL Linked Service
                dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                string FSlinkedServiceName = "CNXFTPLinkedService";
                var fileSystemLinkedService = new LinkedServiceResource(
                        new FileServerLinkedService
                        {
                            ConnectVia = new IntegrationRuntimeReference("CNXIntegrationRuntime"),
                            Host = "E:\\",
                            UserId = ".\\CP01VMEUS05adm",
                            Password = new SecureString("yvd6$20JD")
                        }
                    );

                // Create or update the File system Linked Service
                dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, FSlinkedServiceName, fileSystemLinkedService);
                Console.WriteLine("FTP Linked Service created successfully.");
                #endregion


                #region Dataset

                // Define the File System dataset name and its properties
                string datasetName = "DDDDemographicFileDataset";
                var fileSystemDataset = new DatasetResource
                (
                    new DelimitedTextDataset
                    {

                        LinkedServiceName = new LinkedServiceReference
                        {
                            ReferenceName = "CNXFTPLinkedService"
                        },
                        Location = new FtpServerLocation
                        {
                            FolderPath = "sFTP_Accounts/Fidia/DDD/Inbound",
                            FileName = "@concat('ZRXWR02_FIDIA_DMD_Demographic_File_C510R01_',activity('GetMonthandYearLookupActivity').output.firstRow.MonthYear,'.ZIP')"
                        },
                        //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                        CompressionCodec = "ZipDeflate (.zip)",
                        CompressionLevel = "Fastest",
                        ColumnDelimiter = "Pipe(|)",
                        RowDelimiter = "Default (\r,\n, or \r\n)",
                        EncodingName = "Default(UTF-8)",
                        QuoteChar = '"',
                        EscapeChar = "Backslash(\\)"
                    }
                );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, fileSystemDataset);

                string datasetName1 = "StagingDDDDemographicDataset";
                var StagingDDDDemographicDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_DDD_OutletRawData"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingDDDDemographicDataset);

                string datasetName2 = "DDDDataFileDataset";
                var DDDDataFileDataset = new DatasetResource
                (
                    new DelimitedTextDataset
                    {

                        LinkedServiceName = new LinkedServiceReference
                        {
                            ReferenceName = "CNXFTPLinkedService"
                        },
                        Location = new FtpServerLocation
                        {
                            FolderPath = "sFTP_Accounts/Fidia/DDD/Inbound",
                            FileName = "@concat('ZRXWR01_FIDIA_DMD_Data_File_C510R01_',activity('GetMonthandYearLookupActivity').output.firstRow.MonthYear,'.ZIP')"
                        },

                        CompressionCodec = "ZipDeflate (.zip)",
                        CompressionLevel = "Fastest",
                        ColumnDelimiter = "Comma (,)",
                        RowDelimiter = "Default (\r,\n, or \r\n)",
                        EncodingName = "Default(UTF-8)",
                        QuoteChar = '"',
                        EscapeChar = "Backslash(\\)"
                    }
                );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName2, DDDDataFileDataset);

                string datasetName3 = "StagingDDDDataDataset";
                var StagingDDDDataDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_DDD_FullData"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName3, StagingDDDDataDataset);
                #endregion


                // Define the pipeline name and its properties
                string pipelineName = "DDDDemographicPipeline";

                TabularTranslator tabularTranslator = new TabularTranslator
                {
                    ColumnMappings = new List<TabularColumnMapping>
                    {
                        new TabularColumnMapping
                        {
                            SourceColumnName = "1",
                            SinkColumnName = "OutletRawData"
                        }
                    }
                };

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                        {
                            // Add activities to the pipeline
                            new CopyActivity
                            {
                                Name = "CopyOutletRawDataActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "DDDDemographicFileDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingDDDDemographicDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_DDD_OutletRawData"}
                                //Translator = tabularTranslator
                                
                            },

                            new SqlServerStoredProcedureActivity
                            {
                                Name = "TransformOutletDataActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_ddd_staging_outlet_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyOutletRawDataActivity",new List<string> { "Succeeded" })}
                            },

                            new SqlServerStoredProcedureActivity
                            {
                                Name = "TransformDDDFullDataTotalsActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_ddd_fulldata_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("TransformOutletDataActivity", new List<string> { "Succeeded" }),
                                                                           new ActivityDependency("CopyDDDFuldataActivity",new List<string> { "Succeeded" }) }
                            },

                             new CopyActivity
                            {
                                Name = "CopyDDDFuldataActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "DDDDataFileDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingDDDDataDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_DDD_FullData"}
                            },
                        }
                };

                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);


                Console.WriteLine("Pipeline created successfully.");


                //CreateRunResponse runResponse = await dataFactoryManagementClient.Pipelines.CreateRunWithHttpMessagesAsync(
                //    resourceGroupName,
                //    dataFactoryName,
                //    pipelineName,
                //    parameters: null
                //);

                //string runId = runResponse.Body.RunId;

            }
            catch (Exception ex)
            {

            }

            return true;
        }

        private async Task<string> GetBlobContent(string blobName, BlobContainerClient containerClient)
        {
            string content = string.Empty;
            BlobClient blobClient = containerClient.GetBlobClient(blobName);
            BlobDownloadInfo download = await blobClient.DownloadAsync();
            using (var streamReader = new StreamReader(download.Content))
            {
                content = await streamReader.ReadToEndAsync();
            }

            return content;
        }
    }
}

using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.Rest;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ODSDataConnector.Core.Models;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Newtonsoft.Json.Linq;

namespace ODSDataConnector.Core.Services
{
    public class PlantrakAdfService : IPlantrakAdfService
    {
        private readonly ICustomerRepository customerRepository;

        private readonly string subscriptionId = "3bf6616d-4f38-4fd4-82ab-51e652c757a9";
        private readonly string clientId = "8349448f-2016-4cf0-b7c7-27c62e9be090";
        private readonly string clientSecret = "x.L8Q~bdcKxbmDsNG.TZYF0MmLUqRnDymCD3haiV";
        private readonly string tenantId = "907cef94-e870-49f6-b843-09417459b152";
        private readonly string strAzureAuthenticationKey = "pjI7Q~EEIGfNY8TLOwRTDjUwaGY65Xi--vCJT";

        public PlantrakAdfService(ICustomerRepository customerRepository)
        {
            this.customerRepository = customerRepository;
        }

        public async Task<bool> CreatePrescriberSalesPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);

                #region Linked Servcie Creation Section
                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";


                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                string FSlinkedServiceName = "CNXFTPLinkedService";

                var fsLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, FSlinkedServiceName);

                if (fsLS == null)
                {
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
                }
                #endregion


                #region Dataset
                string datasetName = "PTFullDataFileDataSet";
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
                               FolderPath = "sFTP_Accounts/IBSA_IQVIA/Inbound/PlanTrak",
                               FileName = "@concat('NEW_GW5620H_C144R01_W',activity('GetWeekNumberAndYearLookupActivity').output.firstRow.WeeknumberAndYear,'_D3.001.GZ')"
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


                string datasetName1 = "StagingPTFullDataset";
                var StagingDDDDemographicDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_PT_FullData"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingDDDDemographicDataset);
                #endregion


                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlantrakPrescriberSalesPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyFullDataActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PTFullDataFileDataSet",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingPTFullDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_PT_FullData"}
                                //Translator = tabularTranslator
                                
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "CreateColumnStoreIndexTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_create_columnstore_index_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyFullDataActivity", new List<string> { "Succeeded" })}
                            },

                           new SqlServerStoredProcedureActivity
                            {
                                Name = "PtPrescriberTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_prescriber_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CreateColumnStoreIndexTransformActivity", new List<string> { "Succeeded" })}
                            },

                            new SqlServerStoredProcedureActivity
                            {
                                Name = "PtSalesTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_sales_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("PtPrescriberTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);

                Console.WriteLine("Pipeline created successfully.");

                #endregion

                return true;
            }
            catch { }
            {
                return false;
            }
        }

        public async Task<bool> CreateControlDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);


                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";


                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                string FSlinkedServiceName = "CNXFTPLinkedService";

                var fsLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, FSlinkedServiceName);

                if (fsLS == null)
                {
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
                }
                #endregion

                #region Dataset

                string datasetName = "PTControlBinaryFileDataset";
                var fileSystemDataset = new DatasetResource
                   (
                       new BinaryDataset
                       {

                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = "CNXFTPLinkedService"
                           },
                           Location = new FtpServerLocation
                           {
                               FolderPath = "sFTP_Accounts/IBSA_IQVIA/Inbound/PlanTrak",
                               FileName = "@concat('NEW_PROD_GW561652_CLI144U_WK',activity('GetWeekNumberLookupActivity').output.firstRow.Weeknumber,'.001.GZ')"
                           }
                       }
                   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, fileSystemDataset);


                string datasetName1 = "PTStagingControlDataset";
                var StagingDDDDemographicDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_PT_ControlData"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingDDDDemographicDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlantrakControlDataPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyControlDataActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PTControlBinaryFileDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PTStagingControlDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_PT_ControlData"}
                                //Translator = tabularTranslator
                                
                            }
                    }
                };

                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);

                Console.WriteLine("Pipeline created successfully.");

                #endregion


                return true;
            }
            catch (Exception ex)
            {

                return false;
            }
        }

        public async Task<bool> CreatePBMPlansDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);


                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                string ODSBloblinkedServiceName = "CNXStorageBlobLinkedService";

                var bolbLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, ODSBloblinkedServiceName);

                if (bolbLS == null)
                {
                    var azureBlobStorageLinkedService = new LinkedServiceResource(
                        new AzureBlobStorageLinkedService
                        {
                            ConnectionString = new SecureString("DefaultEndpointsProtocol=https;AccountName=odsblobcontainer;AccountKey=EJSJZS/kQFUamEp0w70nJ6yP4CQOwiLjC8abIUtRwdD/EBsxeM3u3nmdTgqA6xrelOX1JLh3Q71WUN7wifzfYA==;EndpointSuffix=core.windows.net")
                        }
                    );

                    // Create or update the File system Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, ODSBloblinkedServiceName, azureBlobStorageLinkedService);
                    Console.WriteLine("FTP Linked Service created successfully.");
                }
                #endregion


                #region Dataset
                string datasetName = "PTPBMPlandBlobDataset";
                var blobDataset = new DatasetResource
                   (
                       new AzureBlobDataset
                       {

                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = "CNXStorageBlobLinkedService"
                           },
                           FolderPath = "ibsa/IQVIA/PlanTrack/",
                           FileName = "FEB_22_Workbook.xls",
                           //AdditionalProperties = new ExcelDataset { SheetName = "", FirstRowAsHeader = "Yes" },

                           Structure = new ExcelDataset
                           {
                               SheetName = "PBM Plans", // Specify the sheet name
                               FirstRowAsHeader = true // Number of rows to skip (optional)
                           }
                       }
                   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, blobDataset);


                string datasetName1 = "PTStagingPBMPlansDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_PT_PBMPlans"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlantrakPBMPlansPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyPBMPlansActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PTPBMPlandBlobDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PTStagingPBMPlansDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_PT_PBMPlans"}
                                //Translator = tabularTranslator
                                
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "PbmPlansTransformActivty",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_pbmplans_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPBMPlansActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public async Task<bool> CreatePayerPlansDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);


                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                // Define the File System Linked Service name and its properties
                string FSlinkedServiceName = "CNXFTPLinkedService";

                var fsLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, FSlinkedServiceName);

                if (fsLS == null)
                {
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
                }
                #endregion


                #region Dataset
                string datasetName = "PlanTrakPayerPlanFileDataset";
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
                               FolderPath = "sFTP_Accounts/IBSA_IQVIA/Inbound/MCWB",
                               FileName = "@concat('MCWB_NEWVIEW_M',startOfMonth(addToTime(utcnow(), -1, 'Month'), 'MM'),'.001')"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash(\\)",
                           FirstRowAsHeader = true
                       }
                   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, fileSystemDataset);


                string datasetName1 = "StagingPTPayerPlanDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_PT_PayerPlan"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlanTrakPayerPlanPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyPayerPlanActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PlanTrakPayerPlanFileDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingPTPayerPlanDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_PT_PayerPlan"}
                                //Translator = tabularTranslator
                                
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "PayerPlanTransformActivty",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_payerplan_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPayerPlanActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public async Task<bool> CreateModelDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);


                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                string ODSBloblinkedServiceName = "CNXStorageBlobLinkedService";

                var bolbLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, ODSBloblinkedServiceName);

                if (bolbLS == null)
                {
                    var azureBlobStorageLinkedService = new LinkedServiceResource(
                        new AzureBlobStorageLinkedService
                        {
                            ConnectionString = new SecureString("DefaultEndpointsProtocol=https;AccountName=odsblobcontainer;AccountKey=EJSJZS/kQFUamEp0w70nJ6yP4CQOwiLjC8abIUtRwdD/EBsxeM3u3nmdTgqA6xrelOX1JLh3Q71WUN7wifzfYA==;EndpointSuffix=core.windows.net")
                        }
                    );

                    // Create or update the File system Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, ODSBloblinkedServiceName, azureBlobStorageLinkedService);
                    Console.WriteLine("FTP Linked Service created successfully.");
                }
                #endregion


                #region Dataset
                string datasetName = "PlanModelDataset";
                var blobDataset = new DatasetResource
                   (
                       new AzureBlobDataset
                       {

                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = "CNXStorageBlobLinkedService"
                           },
                           FolderPath = "ibsa/IQVIA/PlanTrack/",
                           FileName = "Plan Model Type Listing_Final - FROM PAUL.xlsx",
                           //AdditionalProperties = new ExcelDataset { SheetName = "", FirstRowAsHeader = "Yes" },

                           Structure = new ExcelDataset
                           {
                               SheetName = "Table 1", // Specify the sheet name
                               FirstRowAsHeader = true // Number of rows to skip (optional)
                           }
                       }
                   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, blobDataset);


                string datasetName1 = "StagingPlanModelDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_PT_PlanModel"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlanTrakModelPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyPlanModelActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PlanModelDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingPlanModelDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_PT_PlanModel"}
                                //Translator = tabularTranslator
                                
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "PlanModelTransformActivty",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_planmodel_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPlanModelActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public async Task<bool> CreateMarketDefinitionDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);


                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                string FSlinkedServiceName = "CNXFTPLinkedService";

                var fsLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, FSlinkedServiceName);

                if (fsLS == null)
                {
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
                }
                #endregion


                #region Dataset
                string datasetName = "IqviaMarketDeifnitionFileDataset";
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
                               FolderPath = "sFTP_Accounts/IBSA_IQVIA/Inbound/Market_Definition",
                               FileName = "@concat('NRX_NRXMM45A_CSVFILE_CLI144_M',startOfMonth(addToTime(utcnow(), 0, 'Month'), 'MM'),'.001')"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash(\\)"
                       }
                   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, fileSystemDataset);


                string datasetName1 = "StagingIqviaProductDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_IQVIA_Product"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IqviaMarketDefinitionPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyIqviaMarketDerinitionActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "IqviaMarketDeifnitionFileDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingIqviaProductDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_IQVIA_Product"}
                                //Translator = tabularTranslator
                                
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "IqviaProductTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_iqvia_product_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyIqviaMarketDerinitionActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public async Task<bool> CreatePDRPDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);


                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                string FSlinkedServiceName = "CNXFTPLinkedService";

                var fsLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, FSlinkedServiceName);

                if (fsLS == null)
                {
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
                }
                #endregion


                #region Dataset
                string datasetName = "PDRPSourceDataset";
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
                               FolderPath = "sFTP_Accounts/IBSA_IQVIA/Inbound/PDRP",
                               FileName = "RXD_US_C01_UM21401_Y23M01_R01.CSV.001"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash(\\)"
                       }
                   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, fileSystemDataset);


                string datasetName1 = "StagingIqviaPdrpDetailsDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_IQVIA_PdrpDetails"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IqviaPdrpPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyPrdpDetailsActvity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "PDRPSourceDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingIqviaPdrpDetailsDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_IQVIA_PdrpDetails"}
                                //Translator = tabularTranslator
                                
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "PdrpDetailsTransformActivty",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_iqvia_pdrpdetails_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPrdpDetailsActvity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public async Task<bool> CreateNoContactDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + tenantId);
                ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
                AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
                ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
                var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
                {
                    SubscriptionId = subscriptionId
                };


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);


                string resourceGroupName = "ODSDev";
                string dataFactoryName = "ODSAutomationDataFactory";

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sQLLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, linkedServiceName);

                if (sQLLS == null)
                {
                    var sqlLinkedService = new LinkedServiceResource(
                         new AzureSqlDatabaseLinkedService
                         {
                             ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
                         }
                    );

                    // Create or update the SQL Linked Service
                    dataFactoryManagementClient.LinkedServices.CreateOrUpdate(resourceGroupName, dataFactoryName, linkedServiceName, sqlLinkedService);
                    Console.WriteLine("SQL Linked Service created successfully.");
                }

                // Define the File System Linked Service name and its properties
                string FSlinkedServiceName = "CNXFTPLinkedService";

                var fsLS = dataFactoryManagementClient.LinkedServices.Get(resourceGroupName, dataFactoryName, FSlinkedServiceName);

                if (fsLS == null)
                {
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
                }
                #endregion


                #region Dataset
                string datasetName = "NoContactFileDataset";
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
                               FolderPath = "sFTP_Accounts/IBSA_IQVIA/Inbound/No_Contact",
                               FileName = "HCR_PROD_AMA_NO_CONTACTS_APR23.001"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash(\\)"
                       }
                   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, fileSystemDataset);


                string datasetName1 = "StagingIqviaNoContactDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = "ODSSQLLinkedService"
                          },
                          TableName = "Staging_IQVIA_NoContact"

                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IqviaNoContactPipeline";

                var pipeline = new PipelineResource()
                {
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyNoContactctvity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "NoContactFileDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingIqviaNoContactDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_IQVIA_NoContact"}
                                //Translator = tabularTranslator
                                
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "NoContactTransformActivty",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_iqvia_nocontact_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPrdpDetailsActvity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }
    }
}

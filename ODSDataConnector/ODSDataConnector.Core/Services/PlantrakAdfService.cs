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
        private readonly IADFService aDFService;
        private readonly IAppLogger AppLogger;

        public PlantrakAdfService(ICustomerRepository customerRepository, IADFService ADFService, IAppLogger appLogger)
        {
            this.customerRepository = customerRepository;
            this.aDFService = ADFService;
            this.AppLogger = appLogger;
        }

        public async Task<bool> CreatePrescriberSalesPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreatePrescriberSalesPipeline Method Started at {DateTime.UtcNow}");
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);

                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                #region Linked Servcie Creation Section
                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;


                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("FTP Linked Service created successfully.");

                #endregion

                #region Dataset
                string datasetName = "PTFullDataFileDataSet";
                var fileSystemDataset = new DatasetResource
                   (
                       new DelimitedTextDataset
                       {
                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = dsConfig.LinkedService
                           },
                           Location = new FtpServerLocation
                           {
                               FolderPath = dsConfig.Url,
                               FileName = dsConfig.SrcFileName
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           CompressionCodec = "gzip (.gz)",
                           CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)",
                           Folder = new DatasetFolder { Name = "Plantrak" }
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingDDDDemographicDataset);
                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlantrakPrescriberSalesPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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

                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");

                #endregion

                this.AppLogger.LogInformation($"CreatePrescriberSalesPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public async Task<bool> CreateControlDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateControlDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("File system Linked Service created successfully.");
                #endregion

                #region Dataset

                string datasetName = "PTControlBinaryFileDataset";
                var fileSystemDataset = new DatasetResource
                   (
                       new DelimitedTextDataset
                       {

                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = dsConfig.LinkedService
                           },
                           Location = new FtpServerLocation
                           {
                               FolderPath = dsConfig.Url,
                               FileName = dsConfig.SrcFileName
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           CompressionCodec = "gzip (.gz)",
                           CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)",
                           Folder = new DatasetFolder { Name = "Plantrak" }
                       }
                   );
                //var fileSystemDataset = new DatasetResource
                //   (
                //       new BinaryDataset
                //       {

                //           LinkedServiceName = new LinkedServiceReference
                //           {
                //               ReferenceName = dsConfig.LinkedService
                //           },
                //           Location = new FtpServerLocation
                //           {
                //               FolderPath = dsConfig.Url,
                //               FileName = "PTControl.001.GZ"
                //           }
                //       }
                //   );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, fileSystemDataset);


                string datasetName1 = "PTStagingControlDataset";
                var StagingDDDDemographicDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingDDDDemographicDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlantrakControlDataPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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

                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateControlDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreatePBMPlansDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreatePBMPlansDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section

                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the Storage Blob Linked Service name and its properties
                var blobLsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(blobLsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("Blob Linked Service created successfully.");

                #endregion

                #region Dataset
                string datasetName = "PTPBMPlandBlobDataset";
                var blobDataset = new DatasetResource
                   (
                     new ExcelDataset
                     {
                         LinkedServiceName = new LinkedServiceReference
                         {
                             ReferenceName = dsConfig.LinkedService
                         },
                         Location = new AzureBlobStorageLocation
                         {
                             Container = dsConfig.Url.Split('/').First(),
                             FolderPath = dsConfig.Url.Split('/')[1] + "/" + dsConfig.Url.Split('/')[2],
                             FileName = dsConfig.SrcFileName,
                         },
                         SheetName = dsConfig.SheetName,
                         FirstRowAsHeader = true,
                         Folder = new DatasetFolder { Name = "Plantrak" }
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlantrakPBMPlansPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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
                                Name = "PbmPlansTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_pbmplans_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPBMPlansActivity", new List<string> { "Succeeded" })}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingPBMPlansTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_reporting_pt_pbmplans_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("PbmPlansTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreatePBMPlansDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreatePayerPlansDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreatePayerPlansDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("File system Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "PlanTrakPayerPlanFileDataset";
                var fileSystemDataset = new DatasetResource
                   (
                       new DelimitedTextDataset
                       {

                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = dsConfig.LinkedService
                           },
                           Location = new FtpServerLocation
                           {
                               FolderPath = dsConfig.Url,
                               FileName = dsConfig.SrcFileName
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)",
                           FirstRowAsHeader = true,
                           Folder = new DatasetFolder { Name = "Plantrak" }
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlanTrakPayerPlanPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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
                                Name = "PayerPlanTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_payerplan_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPayerPlanActivity", new List<string> { "Succeeded" })}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingPayerPlanTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_reporting_pt_payerplan_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("PayerPlanTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreatePayerPlansDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreateModelDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateModelDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the Storage Blob Linked Service name and its properties
                var blobLsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(blobLsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("Blob Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "PlanModelDataset";
                var blobDataset = new DatasetResource
                   (
                      new ExcelDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = dsConfig.LinkedService
                          },
                          Location = new AzureBlobStorageLocation
                          {
                              Container = dsConfig.Url.Split('/').First(),
                              FolderPath = dsConfig.Url.Split('/')[1] + "/" + dsConfig.Url.Split('/')[2],
                              FileName = dsConfig.SrcFileName,
                          },
                          SheetName = dsConfig.SheetName,
                          FirstRowAsHeader = true,
                          Folder = new DatasetFolder { Name = "Plantrak" }
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "PlanTrakModelPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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
                                Name = "PlanModelTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_pt_planmodel_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPlanModelActivity", new List<string> { "Succeeded" })}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingPlanModelTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_reporting_pt_planmodel_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("PlanModelTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateModelDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreateMarketDefinitionDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateMarketDefinitionDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("File system Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "IqviaMarketDeifnitionFileDataset";
                var fileSystemDataset = new DatasetResource
                   (
                       new DelimitedTextDataset
                       {

                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = dsConfig.LinkedService
                           },
                           Location = new FtpServerLocation
                           {
                               FolderPath = dsConfig.Url,
                               FileName = dsConfig.SrcFileName
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)",
                           Folder = new DatasetFolder { Name = "Plantrak" }
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IqviaMarketDefinitionPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingIqviaProductTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_reporting_iqvia_product_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("IqviaProductTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateMarketDefinitionDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreatePDRPDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreatePDRPDataPipeline Method Started at {DateTime.UtcNow}");
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("File system Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "PDRPSourceDataset";
                var fileSystemDataset = new DatasetResource
                   (
                       new DelimitedTextDataset
                       {

                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = dsConfig.LinkedService
                           },
                           Location = new FtpServerLocation
                           {
                               FolderPath = dsConfig.Url,
                               FileName = dsConfig.SrcFileName
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)",
                           Folder = new DatasetFolder { Name = "Plantrak" }
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IqviaPdrpPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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
                                Name = "PdrpDetailsTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_iqvia_pdrpdetails_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPrdpDetailsActvity", new List<string> { "Succeeded" })}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingPdrpDetailsTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_Reporting_iqvia_pdrpdetails_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("PdrpDetailsTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreatePDRPDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreateNoContactDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateNoContactDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("File system Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "NoContactFileDataset";
                var fileSystemDataset = new DatasetResource
                   (
                       new DelimitedTextDataset
                       {
                           LinkedServiceName = new LinkedServiceReference
                           {
                               ReferenceName = dsConfig.LinkedService
                           },
                           Location = new FtpServerLocation
                           {
                               FolderPath = dsConfig.Url,
                               FileName = dsConfig.SrcFileName
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)",
                           Folder = new DatasetFolder { Name = "Plantrak" }
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IqviaNoContactPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
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
                                Name = "NoContactTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_iqvia_nocontact_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyNoContactctvity", new List<string> { "Succeeded" })}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingNoContactTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_reporting_iqvia_nocontact_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("NoContactTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateNoContactDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreateIQVIACalenderDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateIQVIACalenderDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the Storage Blob Linked Service name and its properties
                var blobLsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(blobLsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("Blob Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "IqviaCalendarBlobDataset";
                var blobDataset = new DatasetResource
                   (
                      new ExcelDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = dsConfig.LinkedService
                          },
                          Location = new AzureBlobStorageLocation
                          {
                              Container = dsConfig.Url.Split('/').First(),
                              FolderPath = dsConfig.Url.Split('/')[1] + "/" + dsConfig.Url.Split('/')[2],
                              FileName = dsConfig.SrcFileName,
                          },
                          SheetName = dsConfig.SheetName,
                          FirstRowAsHeader = true,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                   );

                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, blobDataset);


                string datasetName1 = "IqviaCalendarDbDataset";
                var StagingCalendarDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "Plantrak" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingCalendarDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IQVIACalendarPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "Plantrak" },
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyCalendarActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "IqviaCalendarBlobDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "IqviaCalendarDbDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE IQVIA_Calendar"}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateIQVIACalenderDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreateIQVIAProductMarketDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateIQVIAProductMarketDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the Storage Blob Linked Service name and its properties
                var blobLsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(blobLsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("Blob Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "IqviaProductMarketBlobDataset";
                var blobDataset = new DatasetResource
                   (
                      new ExcelDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = dsConfig.LinkedService
                          },
                          Location = new AzureBlobStorageLocation
                          {
                              Container = dsConfig.Url.Split('/').First(),
                              FolderPath = dsConfig.Url.Split('/')[1] + "/" + dsConfig.Url.Split('/')[2],
                              FileName = dsConfig.SrcFileName,
                          },
                          SheetName = dsConfig.SheetName,
                          FirstRowAsHeader = true,
                          Folder = new DatasetFolder { Name = "IQVIA" }
                      }
                   );

                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, blobDataset);


                string datasetName1 = "StagingIqviaProductMarketDataset";
                var StagingProductMarketDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "IQVIA" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingProductMarketDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IbsaProductMarketPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "IQVIA" },
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyIBSAProductmarketActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "IqviaProductMarketBlobDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingIqviaProductMarketDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_IQVIA_ProductMarket"}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "IqviaProductMarketTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_iqvia_productmarket_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyIBSAProductmarketActivity", new List<string> { "Succeeded" })}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingIqviaProductMarketTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_reporting_iqvia_productmarket_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("IqviaProductMarketTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateIQVIAProductMarketDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreateIQVIASpecialtyDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateIQVIASpecialtyDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("File system Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "IqviaSpecialtyDataset";
                var excelFSDataset = new DatasetResource
                   (
                      new ExcelDataset
                      {
                          Location = new FtpServerLocation
                          {
                              FolderPath = dsConfig.Url,
                              FileName = dsConfig.SrcFileName
                          },
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = dsConfig.LinkedService
                          },
                          SheetName = dsConfig.SheetName,
                          FirstRowAsHeader = true,
                          Folder = new DatasetFolder { Name = "IQVIA" }
                      }
                   );

                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, excelFSDataset);


                string datasetName1 = "StagingIqviaSpecialtyDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "IQVIA" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "IqviaSpecialtyPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "IQVIA" },
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopySpecailtyActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "IqviaSpecialtyDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingIqviaSpecialtyDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_IQVIA_Specialty"}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "IqviaSpecialtyTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_iqvia_specialty_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopySpecailtyActivity", new List<string> { "Succeeded" })}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ReportingSpecialtyTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_reporting_iqvia_specialty_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("IqviaSpecialtyTransformActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateIQVIASpecialtyDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        public async Task<bool> CreateZipToTerrDataPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateZipToTerrDataPipeline Method Started at {DateTime.UtcNow}");
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("File system Linked Service created successfully.");
                #endregion

                #region Dataset
                string datasetName = "ClientZTTFileDataset";
                var excelFSDataset = new DatasetResource
                   (
                      new ExcelDataset
                      {
                          Location = new FtpServerLocation
                          {
                              FolderPath = dsConfig.Url,
                              FileName = dsConfig.SrcFileName
                          },
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = dsConfig.LinkedService
                          },
                          SheetName = dsConfig.SheetName,
                          FirstRowAsHeader = true,
                          Folder = new DatasetFolder { Name = "IQVIA" }
                      }
                   );

                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName, excelFSDataset);


                string datasetName1 = "StagingClientZTTDataset";
                var StagingPBMPlansDataset = new DatasetResource
                    (
                      new AzureSqlTableDataset
                      {
                          LinkedServiceName = new LinkedServiceReference
                          {
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable,
                          Folder = new DatasetFolder { Name = "IQVIA" }
                      }
                    );
                dataFactoryManagementClient.Datasets.CreateOrUpdate(resourceGroupName, dataFactoryName, datasetName1, StagingPBMPlansDataset);

                #endregion

                #region Pipeline
                // Define the pipeline name and its properties
                string pipelineName = "ClientZTTPipeline";

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = "IQVIA" },
                    Activities = new List<Activity>()
                    {
                         new CopyActivity
                            {
                                Name = "CopyClientZTTActivity",
                                Inputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "ClientZTTFileDataset",
                                    }
                                },
                                Outputs = new List<DatasetReference>()
                                {
                                    new DatasetReference()
                                    {
                                        ReferenceName = "StagingClientZTTDataset",
                                    }
                                },
                                Source = new  DelimitedTextSource(),
                                Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE Staging_Client_ZipToTerr"}
                            },

                          new SqlServerStoredProcedureActivity
                            {
                                Name = "ClientZTTTransformActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = "ODSSQLLinkedService"
                                  },
                                 StoredProcedureName = "sp_Client_ziptoterr_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyClientZTTActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
                #endregion

                this.AppLogger.LogInformation($"CreateZipToTerrDataPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        private Entities.LinkedService CreateFSLinkedServiceProperties(string resourceGroupName, string dataFactoryName, CustomerConfiguration dsConfig)
        {
            return new Entities.LinkedService
            {
                ResourceGroupName = resourceGroupName,
                DataFactoryName = dataFactoryName,
                LinkedServiceName = dsConfig.LinkedService,
                Runtime = dsConfig.Server,
                Host = dsConfig.Host,
                Username = dsConfig.Username,
                Password = dsConfig.Password,
                Type = "FTP"
            };
        }

        private Entities.LinkedService createSQLLinkedServiceProperties(string resourceGroupName, string dataFactoryName, Customer customer)
        {
            return new Entities.LinkedService
            {
                ResourceGroupName = resourceGroupName,
                DataFactoryName = dataFactoryName,
                LinkedServiceName = customer.LinkedService,
                Dbserver = customer.Dbserver,
                Dbname = customer.Dbname,
                Username = customer.Username,
                Password = customer.Password,
                Type = "SQL"
            };
        }

        private Entities.LinkedService CreateBlobLinkedServiceProperties(string resourceGroupName, string dataFactoryName, CustomerConfiguration dsConfig)
        {
            return new Entities.LinkedService
            {
                ResourceGroupName = resourceGroupName,
                DataFactoryName = dataFactoryName,
                LinkedServiceName = dsConfig.LinkedService,
                Username = dsConfig.Username,
                Password = dsConfig.Password,
                Type = "STORAGE"
            };
        }


    }
}

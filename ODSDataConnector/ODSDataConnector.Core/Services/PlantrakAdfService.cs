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

        public PlantrakAdfService(ICustomerRepository customerRepository, IADFService ADFService)
        {
            this.customerRepository = customerRepository;
            this.aDFService = ADFService;
        }

        public async Task<bool> CreatePrescriberSalesPipeline(DataRequest request)
        {
            try
            {
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);

                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                #region Linked Servcie Creation Section
                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;


                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                Console.WriteLine("FTP Linked Service created successfully.");

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
                               FileName = "PTFullData.GZ"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           CompressionCodec = "gzip (.gz)",
                           CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)"
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
                          TableName = dsConfig.DestTable

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
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public async Task<bool> CreateControlDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();


                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;


                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                Console.WriteLine("FTP Linked Service created successfully.");
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
                               FileName = "PTControl.001.GZ"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           CompressionCodec = "gzip (.gz)",
                           CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)"
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
                          TableName = dsConfig.DestTable

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
                throw ex;
            }
        }

        public async Task<bool> CreatePBMPlansDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section

                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the Storage Blob Linked Service name and its properties
                var blobLsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(blobLsProperties, dataFactoryManagementClient);
                Console.WriteLine("Blob Linked Service created successfully.");

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
                             FileName = "PBMPlans.xls",
                         },
                         SheetName = "PBM Plans",
                         FirstRowAsHeader = true,
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
                          TableName = dsConfig.DestTable

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
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public async Task<bool> CreatePayerPlansDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                Console.WriteLine("FTP Linked Service created successfully.");
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
                               FileName = "MCWB.001"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)",
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
                              ReferenceName = customer.LinkedService
                          },
                          TableName = dsConfig.DestTable

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

        public async Task<bool> CreateModelDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the Storage Blob Linked Service name and its properties
                var blobLsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(blobLsProperties, dataFactoryManagementClient);
                Console.WriteLine("Blob Linked Service created successfully.");
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
                              FileName = "ModelData.xlsx",
                          },
                          SheetName = "Table 1",
                          FirstRowAsHeader = true,
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
                          TableName = dsConfig.DestTable

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
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public async Task<bool> CreateMarketDefinitionDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                Console.WriteLine("FTP Linked Service created successfully.");
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
                               FileName = "MarketDefinition.001.txt"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)"
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
                          TableName = dsConfig.DestTable

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
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public async Task<bool> CreatePDRPDataPipeline(DataRequest request)
        {
            try
            {
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                Console.WriteLine("FTP Linked Service created successfully.");
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
                               FileName = "PDRP.CSV.001"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)"
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
                          TableName = dsConfig.DestTable

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
                // Create or update the pipeline
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                Console.WriteLine("Pipeline created successfully.");
                #endregion

                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public async Task<bool> CreateNoContactDataPipeline(DataRequest request)
        {
            try
            {
                // Authenticate and Create a data factory management client
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;

                #region Linked Servcie Creation Section
                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateFSLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                Console.WriteLine("FTP Linked Service created successfully.");
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
                               FileName = "NO_CONTACTS.001"
                           },
                           //CompressionLevel = new DatasetCompression { Type = "ZipDeflate (.zip)", Level = "Fastest" },
                           //CompressionCodec = "ZipDeflate (.zip)",
                           //CompressionLevel = "Fastest",
                           ColumnDelimiter = "Comma (,)",
                           RowDelimiter = "Default (\r,\n, or \r\n)",
                           EncodingName = "Default(UTF-8)",
                           QuoteChar = '"',
                           EscapeChar = "Backslash (\\)"
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
                          TableName = dsConfig.DestTable

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
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyNoContactctvity", new List<string> { "Succeeded" })}
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

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

namespace ODSDataConnector.Core.Services
{
    public class DDDAdfService : IDDDAdfService
    {
        private readonly ICustomerRepository customerRepository;

        private readonly IADFService aDFService;

        public DDDAdfService(ICustomerRepository customerRepository, IADFService ADFService)
        {
            this.customerRepository = customerRepository;
            this.aDFService = ADFService;
        }

        public async Task<bool> CreateDemographicPipeline(DataRequest request)
        {
            try
            {
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);

                #region Linked Servcie Creation Section
                string resourceGroupName = "ODSDev";
                string dataFactoryName = customer.Adfname;


                // Define the SQL Linked Service name and its properties
                string linkedServiceName = "ODSSQLLinkedService";

                var sqlLinkedService = new LinkedServiceResource(
                     new AzureSqlDatabaseLinkedService
                     {
                         ConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password
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

                return true;
            }
            catch { }
            {
                return false;
            }
        }
    }
}

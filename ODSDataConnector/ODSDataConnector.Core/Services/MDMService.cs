using DocumentFormat.OpenXml.Office2019.Excel.RichData;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using ODSDataConnector.Core.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Services
{
    public class MDMService : IMDMService
    {
        private readonly ICustomerRepository customerRepository;
        private readonly IADFService aDFService;
        private readonly IAppLogger AppLogger;

        public MDMService(ICustomerRepository customerRepository, IADFService ADFService, IAppLogger appLogger)
        {
            this.customerRepository = customerRepository;
            this.aDFService = ADFService;
            this.AppLogger = appLogger;
        }

        public async Task<bool> CreateMDMPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreateMDMPipeline Method Started at {DateTime.UtcNow}");
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
                var fslsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("Blob Linked Service created successfully.");

                // Define the Azure Batch Linked Service name and its properties
                var batchlsProperties = CreateAzureBatchLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(batchlsProperties, dataFactoryManagementClient);
                this.AppLogger.LogInformation("Batch Linked Service created successfully.");

                #endregion
                string pipelineFolderName = "MDM";
                string pipelineName = "VeevaToCMSPipeline";
                string pipelineName1 = "PlantrakToCMSPipeline";

                if (!customer.IsMdm)
                {
                    pipelineFolderName = "No_MDM";
                    pipelineName = "VeevaToCMSPipeline_NoMDM";
                    pipelineName1 = "PlantrakToCMSPipeline_NoMDM";
                }

                var pipeline = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = pipelineFolderName },
                    Activities = new List<Activity>()
                    {
                          new SqlServerStoredProcedureActivity
                            {
                                Name = "CopyOdsToCmsActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_ods_to_cms_transform"
                                 //DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyFullDataActivity", new List<string> { "Succeeded" })}
                            },

                           new SqlServerStoredProcedureActivity
                            {
                                Name = "TransformGoldenRecordForVeevaActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_cms_goldenrecord_dataload_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyOdsToCmsActivity", new List<string> { "Succeeded" })},
                                 StoredProcedureParameters = new List<StoredProcedureParameter>{ new StoredProcedureParameter
                                                                                                    {
                                                                                                        Type = "String",
                                                                                                        Value = "Veeva"
                                                                                                    }
                                                                                                }
                            },
                           new SqlServerStoredProcedureActivity
                            {
                                Name = "CreateIdentifierMatchesActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_cms_create_identifier_matches",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("TransformGoldenRecordForVeevaActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };

                var pipeline1 = new PipelineResource()
                {
                    Folder = new PipelineFolder { Name = pipelineFolderName },
                    Activities = new List<Activity>()
                    {
                          new SqlServerStoredProcedureActivity
                            {
                                Name = "CopyPlanTrakToCmsActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_plantrak_to_cms_transform"
                                 //DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyFullDataActivity", new List<string> { "Succeeded" })}
                            },

                           new SqlServerStoredProcedureActivity
                            {
                                Name = "TransformGoldenRecordForPlanTrakActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_cms_goldenrecord_dataload_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPlanTrakToCmsActivity", new List<string> { "Succeeded" })},
                                 StoredProcedureParameters = new List<StoredProcedureParameter>{ new StoredProcedureParameter
                                                                                                    {
                                                                                                        Type = "String",
                                                                                                        Value = "Plantrak"
                                                                                                    }
                                                                                                }
                            },
                            new SqlServerStoredProcedureActivity
                            {
                                Name = "CreateIdentifierMatchesActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_cms_create_identifier_matches",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("TransformGoldenRecordForPlanTrakActivity", new List<string> { "Succeeded" })}
                            }
                    }
                };


                var veevaToCMSActivity = new List<Activity>();
                var plantrakToCMSActivity = new List<Activity>();
                var prevActivityName = string.Empty;

                this.AppLogger.LogInformation($"Is MDM required : {customer.IsMdm}");
                if (customer.IsMdm)
                {
                    veevaToCMSActivity.Add(
                        new CustomActivity
                        {
                            Name = "FuzzyMatchingActivity",
                            Command = "FuzzyMatchingActivity.exe -s \"VEEVA\"",
                            FolderPath = dsConfig.Url,
                            ResourceLinkedService = new LinkedServiceReference
                            {
                                ReferenceName = dsConfig.LinkedService
                            },
                            LinkedServiceName = new LinkedServiceReference
                            {
                                ReferenceName = "BatchLinkedService"
                            },

                            DependsOn = new List<ActivityDependency> { new ActivityDependency("CreateIdentifierMatchesActivity", new List<string> { "Succeeded" }) }

                        });


                    plantrakToCMSActivity.Add(
                    new CustomActivity
                    {
                        Name = "FuzzyMatchingActivity",
                        Command = "FuzzyMatchingActivity.exe -s \"PLANTRAK\"",
                        FolderPath = dsConfig.Url,
                        ResourceLinkedService = new LinkedServiceReference
                        {
                            ReferenceName = dsConfig.LinkedService
                        },
                        LinkedServiceName = new LinkedServiceReference
                        {
                            ReferenceName = "BatchLinkedService"
                        },

                        DependsOn = new List<ActivityDependency> { new ActivityDependency("CreateIdentifierMatchesActivity", new List<string> { "Succeeded" }) }

                    });

                    prevActivityName = "FuzzyMatchingActivity";
                }
                else
                {
                    prevActivityName = "CreateIdentifierMatchesActivity";
                }

                var activities = new List<Activity>()
                    {
                        new SqlServerStoredProcedureActivity
                            {
                                Name = "AutoMergeActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_cms_automerge_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency(prevActivityName, new List<string> { "Succeeded" })}
                            },
                        new SqlServerStoredProcedureActivity
                            {
                                Name = "TransformCmsMatchesActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_cms_matches_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("AutoMergeActivity", new List<string> { "Succeeded" })}
                            },
                        new SqlServerStoredProcedureActivity
                            {
                                Name = "TransformGoldenRecordActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_cms_goldenrecord_dataload_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("TransformCmsMatchesActivity", new List<string> { "Succeeded" })}
                            },
                        new SqlServerStoredProcedureActivity
                            {
                                Name = "TransformVeevaCallforActionActivity",
                                 LinkedServiceName= new LinkedServiceReference
                                  {
                                      ReferenceName = customer.LinkedService
                                  },
                                 StoredProcedureName = "sp_Veeva_CallforAction_transform",
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("TransformGoldenRecordActivity", new List<string> { "Succeeded" })}
                            }
                    };

                foreach (var act in veevaToCMSActivity)
                {
                    pipeline.Activities.Add(act);
                }

                foreach (var act in plantrakToCMSActivity)
                {
                    pipeline1.Activities.Add(act);
                }

                foreach (var act in activities)
                {
                    pipeline.Activities.Add(act);
                    pipeline1.Activities.Add(act);
                }
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);
                dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName1, pipeline1);

                this.AppLogger.LogInformation($" {pipelineName} and {pipelineName1} Pipeline created successfully.");

                this.AppLogger.LogInformation($"CreateMDMPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                this.AppLogger.LogError(ex);
                throw ex;
            }
        }

        private Entities.LinkedService CreateAzureBatchLinkedServiceProperties(string resourceGroupName, string dataFactoryName, CustomerConfiguration dsConfig)
        {
            return new Entities.LinkedService
            {
                ResourceGroupName = resourceGroupName,
                DataFactoryName = dataFactoryName,
                LinkedServiceName = "BatchLinkedService",
                Runtime = "CNXIntegrationRuntime",
                Type = "Batch"
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

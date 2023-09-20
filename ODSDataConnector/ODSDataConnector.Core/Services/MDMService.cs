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

        public MDMService(ICustomerRepository customerRepository, IADFService ADFService)
        {
            this.customerRepository = customerRepository;
            this.aDFService = ADFService;
        }

        public async Task<bool> CreateMDMPipeline(DataRequest request)
        {
            try
            {
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);

                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                #region Linked Servcie Creation Section
                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;


                // Define the SQL Linked Service name and its properties
                var sQLlsProperties = createSQLLinkedServiceProperties(resourceGroupName, dataFactoryName, customer);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(sQLlsProperties, dataFactoryManagementClient);
                Console.WriteLine("SQL Linked Service created successfully.");

                // Define the File System Linked Service name and its properties
                var fslsProperties = CreateBlobLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(fslsProperties, dataFactoryManagementClient);
                Console.WriteLine("Blob Linked Service created successfully.");

                // Define the Azure Batch Linked Service name and its properties
                var batchlsProperties = CreateAzureBatchLinkedServiceProperties(resourceGroupName, dataFactoryName, dsConfig);

                dataFactoryManagementClient = this.aDFService.CreateLinkedService(batchlsProperties, dataFactoryManagementClient);
                Console.WriteLine("Batch Linked Service created successfully.");

                #endregion
                string pipelineFolderName = "MDM";
                string pipelineName = "VeevaToCMSPipeline";
                string pipelineName1 = "PlantrakToCMSPipeline";

                if(!customer.IsMdm)
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
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyOdsToCmsActivity", new List<string> { "Succeeded" })}
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
                                 DependsOn = new List<ActivityDependency>{ new ActivityDependency("CopyPlanTrakToCmsActivity", new List<string> { "Succeeded" })}
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

                if (customer.IsMdm)
                {
                    veevaToCMSActivity.Add(
                        new CustomActivity
                        {
                            Name = "FuzzyMatchingActivity",
                            Command = "FuzzyMatchingActivity.exe -s \"VEEVA\"",
                            FolderPath = "turnkey/CustomActivity/MDM/FuzzyMatch",
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
                        FolderPath = "turnkey/CustomActivity/MDM/FuzzyMatch",
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

                Console.WriteLine("Pipeline created successfully.");

                return true;
            }
            catch (Exception ex)
            {
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
                //Dbserver = customer.Dbserver,
                //Dbname = customer.Dbname,
                //Username = customer.Username,
                //Password = customer.Password,
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

using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Services
{
    public class VeevaPTReportingService : IVeevaPTReportingService
    {
        private readonly ICustomerRepository customerRepository;
        private readonly IADFService aDFService;
        private readonly IAppLogger AppLogger;

        public VeevaPTReportingService(ICustomerRepository customerRepository, IADFService ADFService, IAppLogger appLogger)
        {
            this.customerRepository = customerRepository;
            this.aDFService = ADFService;
            this.AppLogger = appLogger;
        }

        public async Task<bool> CreateReportingPipeline(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"CreatePrescriberSalesPipeline Method Started at {DateTime.UtcNow}");
                var dataFactoryManagementClient = this.aDFService.GetADFClient();

                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);

                var dsConfig = await this.customerRepository.GetDataSourceConfigAsync(request);

                string resourceGroupName = customer.ResourceGroup;
                string dataFactoryName = customer.Adfname;

                #region Pipeline

                CreateCommonReportingPipeline(dataFactoryManagementClient, resourceGroupName, dataFactoryName);

                CreateCallReportingPipeline(dataFactoryManagementClient, resourceGroupName, dataFactoryName);

                CreateNGDReportingPipeline(dataFactoryManagementClient, resourceGroupName, dataFactoryName);

                CreatePrescriberReportingPipeline(dataFactoryManagementClient, resourceGroupName, dataFactoryName);

                CreateTerritoryPerfReportingPipeline(dataFactoryManagementClient, resourceGroupName, dataFactoryName);

                #endregion

                this.AppLogger.LogInformation($"CreatePrescriberSalesPipeline Method completed at {DateTime.UtcNow}");
                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void CreateTerritoryPerfReportingPipeline(DataFactoryManagementClient dataFactoryManagementClient, string resourceGroupName, string dataFactoryName)
        {
            // Define the pipeline name and its properties
            string pipelineName = "TerritoryPerformanceReportingPipeline";

            var spList = new List<string>() { "sp_reporting_bi_territoryperformancesummary_transform",
                "sp_reporting_bi_territoryperformanceoverview_transform"};

            var pipeline = new PipelineResource()
            {
                Folder = new PipelineFolder { Name = "Reporting" },
                Activities = CreateStoredProcActivities(spList)
            };

            // Create or update the pipeline
            dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);

            this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
        }

        private void CreatePrescriberReportingPipeline(DataFactoryManagementClient dataFactoryManagementClient, string resourceGroupName, string dataFactoryName)
        {
            // Define the pipeline name and its properties
            string pipelineName = "PrescriberOverviewReportingPipeline";

            var spList = new List<string>() { "sp_reporting_bi_prescriberprofile_transform",
                "sp_reporting_bi_prescriberoverview_transform",
            "sp_reporting_bi_prescriberpaymentplansummary_transform"};

            var pipeline = new PipelineResource()
            {
                Folder = new PipelineFolder { Name = "Reporting" },
                Activities = CreateStoredProcActivities(spList)
            };

            // Create or update the pipeline
            dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);

            this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
        }

        private void CreateNGDReportingPipeline(DataFactoryManagementClient dataFactoryManagementClient, string resourceGroupName, string dataFactoryName)
        {
            // Define the pipeline name and its properties
            string pipelineName = "NGDReportingPipeline";

            var spList = new List<string>() { "sp_reporting_bi_ngd_transform" };

            var pipeline = new PipelineResource()
            {
                Folder = new PipelineFolder { Name = "Reporting" },
                Activities = CreateStoredProcActivities(spList)
            };

            // Create or update the pipeline
            dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);

            this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
        }

        private void CreateCallReportingPipeline(DataFactoryManagementClient dataFactoryManagementClient, string resourceGroupName, string dataFactoryName)
        {
            // Define the pipeline name and its properties
            string pipelineName = "CallReportingPipeline";

            var spList = new List<string>() { "sp_reporting_bi_callactivity_transform",
                "sp_reporting_bi_callattainmentterritorysummary_transform",
            "sp_reporting_bi_callattainmenttiersummary_transform",
            "sp_reporting_bi_TrxNrxSampleSummary_Transform",
            "sp_reporting_bi_detailandsamplesummary_transform"};

            var pipeline = new PipelineResource()
            {
                Folder = new PipelineFolder { Name = "Reporting" },
                Activities = CreateStoredProcActivities(spList)
            };

            // Create or update the pipeline
            dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);

            this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
        }

        private void CreateCommonReportingPipeline(DataFactoryManagementClient dataFactoryManagementClient, string resourceGroupName, string dataFactoryName)
        {
            // Define the pipeline name and its properties
            string pipelineName = "PTCommonReportingPipeline";

            var spPTCommonList = new List<string>() { "sp_reporting_bi_accountextract_transform",
                "sp_reporting_bi_callextract_transform",
                "sp_reporting_bi_salesextract_transform" };

            var pipeline = new PipelineResource()
            {
                Folder = new PipelineFolder { Name = "Reporting" },
                Activities = CreateStoredProcActivities(spPTCommonList)
            };

            // Create or update the pipeline
            dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName, pipeline);

            this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");

            string pipelineName_Veeva = "VeevaCommonReportingPipeline";

            var spVeevaCommonList = new List<string>() { "sp_reporting_bi_transform",
                "sp_reporting_userterritorydetails_transform",
                "sp_timeoffterritory_transform" };

            var pipeline_Veeva = new PipelineResource()
            {
                Folder = new PipelineFolder { Name = "Reporting" },
                Activities = CreateStoredProcActivities(spVeevaCommonList)
            };

            // Create or update the pipeline
            dataFactoryManagementClient.Pipelines.CreateOrUpdate(resourceGroupName, dataFactoryName, pipelineName_Veeva, pipeline_Veeva);

            this.AppLogger.LogInformation($"{pipelineName} Pipeline created successfully.");
        }

        private List<Activity> CreateStoredProcActivities(List<string> spList)
        {
            var activities = new List<Activity>();

            for (int i = 0; i < spList.Count; i++)
            {
                var dependencyActivity = i == 0 ? string.Empty : spList[i - 1];
                var activity = new SqlServerStoredProcedureActivity
                {
                    Name = spList[i],
                    LinkedServiceName = new LinkedServiceReference
                    {
                        ReferenceName = "ODSSQLLinkedService"
                    },
                    StoredProcedureName = spList[i],
                    DependsOn = new List<ActivityDependency> { new ActivityDependency(dependencyActivity, new List<string> { "Succeeded" }) }
                };

                activities.Add(activity);
            }

            return activities;
        }
    }
}

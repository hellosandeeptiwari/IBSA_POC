using JobMonitor.DatabaseModels;
using JobMonitor.Models;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.Rest;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Text;

/// <summary>
/// Install-Package Microsoft.Azure.Management.DataFactory
/// Install-Package Microsoft.Azure.Management.ResourceManager -IncludePrerelease
/// Install-Package Microsoft.IdentityModel.Clients.ActiveDirectory
/// Install-Package log4net -Version 2.0.8
/// </summary>
namespace JobMonitor
{
    class Program
    {
        #region App Settings

        static string strSQLConnectionString = ConfigurationManager.AppSettings["strSQLConnectionString"].ToString();

        static string strAzureTenantId = ConfigurationManager.AppSettings["strAzureTenantId"].ToString();
        static string strAzureApplicationId = ConfigurationManager.AppSettings["strAzureApplicationId"].ToString();
        static string strAzureSubscriptionId = ConfigurationManager.AppSettings["strAzureSubscriptionId"].ToString();
        static string strAzureAuthenticationKey = ConfigurationManager.AppSettings["strAzureAuthenticationKey"].ToString();
        static string strResourceGroupList = ConfigurationManager.AppSettings["strResourceGroupList"].ToString();
        static string strAzureDataFactoryList = ConfigurationManager.AppSettings["strAzureDataFactoryList"].ToString();

        static Dictionary<string, int> dicDataFactoryCustomerIdMapping = new Dictionary<string, int>()
        {
            ["ADCTProdDataFactory"] = 47,
            ["BIPIProdDataFactory"] = 38,
            ["BrfProdPACPDataFactory"] = 31,
            ["EGALDataFactory"] = -1,
            ["FidiaProdDataFactory"] = 41,
            ["HBSDatafactory"] = 19,
            ["MonitoringProdDataFactory"] = -1,
            ["MTPAProdDataFactory"] = 30,
            ["OdsProdINDCallPlanningDatafactory"] = -1,
            ["OdsProdSONOMADataFactory"] = -1,
            ["OPTIDatafactory"] = -1,
            ["PACPDataFactory"] = 31,
            ["THVProdDataFactory"] = 29,
            ["URGNProdDataFactory"] = 34
        };

        #endregion

        static void Main(string[] args)
        {
            // Authenticate and Create a data factory management client
            AuthenticationContext objAuthenticationContext = new AuthenticationContext("https://login.windows.net/" + strAzureTenantId);
            ClientCredential objClientCredential = new ClientCredential(strAzureApplicationId, strAzureAuthenticationKey);
            AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync("https://management.azure.com/", objClientCredential).Result;
            ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
            var objClient = new DataFactoryManagementClient(objTokenCredentials)
            {
                SubscriptionId = strAzureSubscriptionId
            };

            // Monitor the pipeline run
            Console.WriteLine("Job Started...");

            string[] arrResourceGroupList = strResourceGroupList.Split(',');
            string[] arrAzureDataFactoryList = strAzureDataFactoryList.Split(',');
            List<PipelineModel> lstPipelines = new List<PipelineModel>();

            for (int iRGIndex = 0; iRGIndex < arrResourceGroupList.Length; iRGIndex++)
            {
                foreach (var objDataFactory in objClient.Factories.ListByResourceGroup(arrResourceGroupList[iRGIndex]))
                {
                    if (strAzureDataFactoryList.Contains(objDataFactory.Name) || strAzureDataFactoryList.ToUpper() == "ALL")
                    {
                        foreach (var objPipeline in objClient.Pipelines.ListByFactory(arrResourceGroupList[iRGIndex], objDataFactory.Name))
                        {
                            lstPipelines.Add(new PipelineModel
                            {
                                PipelineName = objPipeline.Name,
                                ResourceGroupName = arrResourceGroupList[iRGIndex],
                                DataFactoryName = objDataFactory.Name,
                                CustomerId = dicDataFactoryCustomerIdMapping[objDataFactory.Name]
                            });
                        }

                        foreach (var objTrigger in objClient.Triggers.ListByFactory(arrResourceGroupList[iRGIndex], objDataFactory.Name))
                        {
                            foreach (var objPipelineReference in ((Microsoft.Azure.Management.DataFactory.Models.MultiplePipelineTrigger)objTrigger.Properties).Pipelines)
                            {
                                var objPipeline = lstPipelines.FirstOrDefault(p => p.PipelineName == objPipelineReference.PipelineReference.ReferenceName);
                                objPipeline.TriggerName = objTrigger.Name;
                                objPipeline.TriggerStatus = objTrigger.Properties.RuntimeState;

                                TriggerModel objTriggerJSON = JsonConvert.DeserializeObject<TriggerModel>(objTrigger.Properties.AdditionalProperties.Values.First().ToString());
                                objPipeline.ScheduledFrequency = objTriggerJSON.recurrence.frequency;
                                objPipeline.ScheduledTime = objTriggerJSON.recurrence.schedule == null ? "" :
                                                                            (objTriggerJSON.recurrence.schedule.monthDays == null ? "" : "MonthDays=" + string.Join(",", objTriggerJSON.recurrence.schedule.monthDays) + ";") +
                                                                            (objTriggerJSON.recurrence.schedule.weekDays == null ? "" : "WeekDays=" + string.Join(",", objTriggerJSON.recurrence.schedule.weekDays) + ";") +
                                                                            (objTriggerJSON.recurrence.schedule.hours == null ? "" : "Hours=" + objTriggerJSON.recurrence.schedule.hours[0] + ";") +
                                                                            (objTriggerJSON.recurrence.schedule.minutes == null ? "" : "Minutes=" + objTriggerJSON.recurrence.schedule.minutes[0] + ";");
                                objPipeline.ScheduledTimeZone = objTriggerJSON.recurrence.timeZone;
                                objPipeline.StartTime = objTriggerJSON.recurrence.startTime;
                                objPipeline.EndTime = objTriggerJSON.recurrence.endTime;
                            }
                        }
                    }
                }
            }

            InsertPipelineDetails(lstPipelines);

            List<PipelineRunModel> lstPipelineRuns = new List<PipelineRunModel>();
            lstPipelines = GetPipelineDetailsForMonitoring();

            for (int iRGIndex = 0; iRGIndex < arrResourceGroupList.Length; iRGIndex++)
            {
                foreach (var objDataFactory in objClient.Factories.ListByResourceGroup(arrResourceGroupList[iRGIndex]))
                {
                    if (strAzureDataFactoryList.Contains(objDataFactory.Name) || strAzureDataFactoryList.ToUpper() == "ALL")
                    {
                        foreach(string strPipeline in lstPipelines.Where(p => p.DataFactoryName == objDataFactory.Name).Select(p => p.PipelineName))
                        {
                            //var runParams = new RunFilterParameters() { LastUpdatedAfter = DateTime.Now.AddDays(-10), LastUpdatedBefore = DateTime.Now };
                            var runParams = new RunFilterParameters()
                            {
                                LastUpdatedAfter = DateTime.Now.AddDays(-3000),
                                LastUpdatedBefore = DateTime.Now,
                                Filters = new List<RunQueryFilter>() { new RunQueryFilter(operand: "PipelineName", operatorProperty: "Equals", values: new List<string>() { strPipeline }) }
                            };

                            var objPipelineRunList = objClient.PipelineRuns.QueryByFactory(arrResourceGroupList[iRGIndex], objDataFactory.Name, runParams);
                            foreach (var objPipelineRun in objPipelineRunList.Value)
                            {
                                var objPipeline = lstPipelines.FirstOrDefault(p => p.PipelineName == objPipelineRun.PipelineName && p.ResourceGroupName == arrResourceGroupList[iRGIndex] && p.DataFactoryName == objDataFactory.Name);
                                if (objPipeline != null)
                                {
                                    lstPipelineRuns.Add(new PipelineRunModel
                                    {
                                        RunId = Guid.Parse(objPipelineRun.RunId),
                                        PipelineId = objPipeline.PipelineId,
                                        RunStart = objPipelineRun.RunStart,
                                        RunEnd = objPipelineRun.RunEnd,
                                        RunStatus = objPipelineRun.Status,
                                        LastUpdated = objPipelineRun.LastUpdated,
                                        DurationInMilliSeconds = objPipelineRun.DurationInMs,
                                        InvokedById = objPipelineRun.InvokedBy.Id,
                                        InvokedByType = objPipelineRun.InvokedBy.InvokedByType,
                                        InvokedByName = objPipelineRun.InvokedBy.Name,
                                        ErrorMessage = objPipelineRun.Message,
                                        RunGroupId = Guid.Parse(objPipelineRun.RunGroupId)
                                    });
                                }
                            }
                        }
                    }
                }
            }

            InsertPipelineRunDetails(lstPipelineRuns);

            //var runPipelines = client.PipelineRuns.QueryByFactory("thvprodresourcegrp", "thvproddatafactory", runParams);
            //var runActivities = client.ActivityRuns.QueryByPipelineRun("thvprodresourcegrp", "thvproddatafactory", "27f751a2-bbd3-49de-acf3-a9ec6b7e0d47", runParams);


            //var pipelines = client.Pipelines.ListByFactory("TestResourceGroup", "TestPipeline579");

            Console.WriteLine("Job Completed...");
        }

        private static void InsertPipelineRunDetails(List<PipelineRunModel> lstPipelineRunDetails)
        {
            if (lstPipelineRunDetails.Count > 0)
            {
                StringBuilder sbInsertQueries = new StringBuilder("TRUNCATE TABLE ADF_PipelineRun;");
                foreach (PipelineRunModel item in lstPipelineRunDetails)
                {
                    sbInsertQueries.AppendLine($"INSERT INTO ADF_PipelineRun VALUES('{item.RunId}', {item.PipelineId}, {(item.RunStart.HasValue ? "'" + item.RunStart.Value.ToString("yyyy-MM-dd HH:mm:ss") + "'" : "NULL")}, {(item.RunEnd.HasValue ? "'" + item.RunEnd.Value.ToString("yyyy-MM-dd HH:mm:ss") + "'" : "NULL")}, {(string.IsNullOrWhiteSpace(item.RunStatus) ? "NULL" : "'" + item.RunStatus + "'")}, {(item.LastUpdated.HasValue ? "'" + item.LastUpdated.Value.ToString("yyyy-MM-dd HH:mm:ss") + "'" : "NULL")}, {(item.DurationInMilliSeconds.HasValue ? item.DurationInMilliSeconds.Value.ToString() : "NULL")}, '{item.InvokedById}', '{item.InvokedByType}', '{item.InvokedByName}', {(string.IsNullOrWhiteSpace(item.ErrorMessage) ? "NULL" : "'" + item.ErrorMessage.Replace("'", "''") + "'")}, '{item.RunGroupId}');");
                }

                ExecuteQuery(sbInsertQueries.ToString());
            }
        }

        private static void InsertPipelineDetails(List<PipelineModel> lstPipelineDetails)
        {
            if(lstPipelineDetails.Count > 0)
            {
                StringBuilder sbInsertQueries = new StringBuilder("TRUNCATE TABLE ADF_Pipeline;");
                foreach (PipelineModel item in lstPipelineDetails)
                {
                    sbInsertQueries.AppendLine($"INSERT INTO ADF_Pipeline VALUES({item.CustomerId}, '{item.ResourceGroupName}', '{item.DataFactoryName}', '{item.PipelineName}', {(string.IsNullOrWhiteSpace(item.TriggerName) ? "NULL" : "'" + item.TriggerName + "'")}, {(string.IsNullOrWhiteSpace(item.TriggerStatus) ? "NULL" : "'" + item.TriggerStatus + "'")}, {(string.IsNullOrWhiteSpace(item.ScheduledFrequency) ? "NULL" : "'" + item.ScheduledFrequency + "'")}, {(string.IsNullOrWhiteSpace(item.ScheduledTime) ? "NULL" : "'" + item.ScheduledTime + "'")}, {(string.IsNullOrWhiteSpace(item.ScheduledTimeZone) ? "NULL" : "'" + item.ScheduledTimeZone + "'")}, {(item.StartTime.ToString() == "01-01-0001 00:00:00" ? "NULL" : "'" + item.StartTime.ToString("yyyy-MM-dd HH:mm:ss.fff") + "'")}, {(item.EndTime.ToString() == "01-01-0001 00:00:00" ? "NULL" : "'" + item.EndTime.ToString("yyyy-MM-dd HH:mm:ss.fff") + "'")});");
                }

                ExecuteQuery(sbInsertQueries.ToString());
            }
        }

        private static List<PipelineModel> GetPipelineDetailsForMonitoring()
        {
            try
            {
                List<PipelineModel> lstPipelines = new List<PipelineModel>();
                using (SqlConnection sqlConn = new SqlConnection(strSQLConnectionString))
                {
                    // Add any specific WHERE condition if any existing Staging tables have to be excluded for creating in Azure.
                    // Added the condition in below SQL ( AND t.name NOT LIKE 'Staging_SR%')
                    string strQuery = @"
SELECT PipelineId, ResourceGroupName, DataFactoryName, PipelineName, TriggerName, TriggerStatus 
FROM ADF_Pipeline (NOLOCK)
WHERE CustomerId <> -1; ";
                    using (SqlCommand cmd = new SqlCommand(strQuery, sqlConn))
                    {
                        sqlConn.Open();
                        SqlDataReader drPipeline = cmd.ExecuteReader();
                        while (drPipeline.Read())
                        {
                            lstPipelines.Add(new PipelineModel
                            {
                                PipelineId = drPipeline.GetInt32(0),
                                ResourceGroupName = drPipeline.GetString(1),
                                DataFactoryName = drPipeline.GetString(2),
                                PipelineName = drPipeline.GetString(3),
                                TriggerName = drPipeline.IsDBNull(4) ? string.Empty : drPipeline.GetString(4),
                                TriggerStatus = drPipeline.IsDBNull(5) ? string.Empty : drPipeline.GetString(5),
                            });
                        }
                    }
                }

                return lstPipelines;
            }
            catch (Exception ex)
            {
                LogHelper.WriteDebugLog(ex.Message);
                LogHelper.WriteDebugLog(ex.StackTrace);
                return null;
            }
        }

        private static void ExecuteQuery(string sqlQuery)
        {
            try
            {
                //LogHelper.WriteDebugLog(sqlQuery);
                using (SqlConnection sqlConn = new SqlConnection(strSQLConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand(sqlQuery, sqlConn))
                    {
                        cmd.CommandTimeout = 300;
                        sqlConn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                LogHelper.WriteDebugLog(ex.Message);
                LogHelper.WriteDebugLog(ex.StackTrace);
                throw ex;
            }
        }
    }
}

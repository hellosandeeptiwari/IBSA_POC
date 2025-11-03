using System;
using System.IO;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using Excel = Microsoft.Office.Interop.Excel;
using Microsoft.Rest;
using Microsoft.Azure.Management.ResourceManager;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.Rest.Serialization;
using System.Management.Automation;

/// <summary>
/// Install-Package Microsoft.Azure.Management.DataFactory
/// Install-Package Microsoft.Azure.Management.ResourceManager -IncludePrerelease
/// Install-Package Microsoft.IdentityModel.Clients.ActiveDirectory
/// Install-Package log4net -Version 2.0.8
/// </summary>
namespace ODSAutomationUtility
{
    class Program
    {
        #region App Settings

        static string strSQLConnectionString = ConfigurationManager.AppSettings["strSQLConnectionString"].ToString();
        static string strDIIFileName = ConfigurationManager.AppSettings["strDIIFileName"].ToString();
        static string strODSScriptsOutputFilePath = ConfigurationManager.AppSettings["strODSScriptsOutputFilePath"].ToString();

        static string strAzureTenantId = ConfigurationManager.AppSettings["strAzureTenantId"].ToString();
        static string strAzureApplicationId = ConfigurationManager.AppSettings["strAzureApplicationId"].ToString();
        static string strAzureSubscriptionId = ConfigurationManager.AppSettings["strAzureSubscriptionId"].ToString();
        static string strAzureAuthenticationKey = ConfigurationManager.AppSettings["strAzureAuthenticationKey"].ToString();
        static string strResourceGroupName = ConfigurationManager.AppSettings["strResourceGroupName"].ToString();
        static string strAzureDataFactoryName = ConfigurationManager.AppSettings["strAzureDataFactoryName"].ToString();
        static string strVeevaEnvironemntUrl = ConfigurationManager.AppSettings["strVeevaEnvironemntUrl"].ToString();
        static string strVeevaUsername = ConfigurationManager.AppSettings["strVeevaUsername"].ToString();
        static string strVeevaPassword = ConfigurationManager.AppSettings["strVeevaPassword"].ToString();
        static string strVeevaSecurityToken = ConfigurationManager.AppSettings["strVeevaSecurityToken"].ToString();

        static string strVeevaObjectsDataLoadOrder = ConfigurationManager.AppSettings["strVeevaObjectsDataLoadOrder"].ToString();
        static string strObjectsWithDeleteSupport = ConfigurationManager.AppSettings["strObjectsWithDeleteSupport"].ToString();
        static bool bCreateOdsObjects = Convert.ToBoolean(ConfigurationManager.AppSettings["strCreateOdsObjects"]);
        static string strPipelineDataLoadMode = ConfigurationManager.AppSettings["strPipelineDataLoadMode"].ToString();
        static bool bSCDNeeded = ConfigurationManager.AppSettings["strSCDNeeded"].ToString().ToUpper() == "NO" ? false : true;
        static int iVeevaDataLoadForLastNDays = Convert.ToInt32(ConfigurationManager.AppSettings["iVeevaDataLoadForLastNDays"]);

        #endregion

        static void Main(string[] args)
        {
            LogHelper.WriteDebugLog("Started....");

            try
            {
                CreateOdsDatabase();

                CreateAzurePipeline();
            }
            catch (Exception ex)
            {
                LogHelper.WriteDebugLog(ex.Message);
                LogHelper.WriteDebugLog(ex.StackTrace);
                throw ex;
            }

            LogHelper.WriteDebugLog("Completed....");
        }

        private static void ExecutePowerShellScript(string strScript)
        {
            PowerShell ps = PowerShell.Create();

            ps.AddCommand(strScript);

            ps.Invoke();
        }

        private static void CreateOdsDatabase()
        {

            CreateOdsAutomationDatabseObjects();
            LogHelper.WriteDebugLog("ODS Automation specific database objects have been created");

            LoadDIIDetails();
            LogHelper.WriteDebugLog("DII document contents have been loaded into database");

            CreateScdDatabseObjects();
            LogHelper.WriteDebugLog("SCD specific database objects have been created");

            CreateOdsDatabaseObjects();
            LogHelper.WriteDebugLog("ODS database objects have been created");

            List<OdsObjectSchemaModel> lstSchemas = GetOdsGeneratedSchema();
            foreach (OdsObjectSchemaModel objSchema in lstSchemas)
            {
                if (objSchema.ObjectType == OdsObjectTypeEnum.Table)
                {
                    // Create the Tables directory unless it alreasy exists
                    Directory.CreateDirectory(strODSScriptsOutputFilePath + "Tables\\");
                    File.WriteAllText(strODSScriptsOutputFilePath + "Tables\\" + objSchema.ObjectName + ".sql", objSchema.ObjectScript);
                }
                else
                {
                    // Create the Stored Procedures directory unless it alreasy exists
                    Directory.CreateDirectory(strODSScriptsOutputFilePath + "Stored Procedures\\");
                    File.WriteAllText(strODSScriptsOutputFilePath + "Stored Procedures\\" + objSchema.ObjectName + ".sql", objSchema.ObjectScript);
                }
            }


            LogHelper.WriteDebugLog("ODS database object schema files have been created");
        }

        private static void CreateAzurePipeline()
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

            #region Linked Servcie Creation Section

            // Create an Azure ODS Sql Database linked service
            LogHelper.WriteDebugLog("Creating linked service " + "OdsSqlLinkedService" + "...");

            LinkedServiceResource objOdsSqlLinkedService = new LinkedServiceResource(
                new AzureSqlDatabaseLinkedService
                {
                    ConnectionString = new SecureString(strSQLConnectionString)
                }
            );

            objClient.LinkedServices.CreateOrUpdate(strResourceGroupName, strAzureDataFactoryName, "OdsSqlLinkedService", objOdsSqlLinkedService);

            // We have commented the below logging statement since it is logging credentials as free-text which is a security risk.
            //LogHelper.WriteDebugLog(SafeJsonConvert.SerializeObject(objOdsSqlLinkedService, objClient.SerializationSettings));

            // Create an Veeva linked service
            LogHelper.WriteDebugLog("Creating linked service " + "VeevaProdLinkedService" + "...");

            LinkedServiceResource objVeevaProdLinkedService = new LinkedServiceResource(
                new SalesforceLinkedService
                {
                    EnvironmentUrl = strVeevaEnvironemntUrl,
                    Username = strVeevaUsername,
                    Password = new SecureString(strVeevaPassword),
                    SecurityToken = new SecureString(strVeevaSecurityToken)
                }
            );

            objClient.LinkedServices.CreateOrUpdate(strResourceGroupName, strAzureDataFactoryName, "VeevaProdLinkedService", objVeevaProdLinkedService);

            // We have commented the below logging statement since it is logging credentials as free-text which is a security risk.
            //LogHelper.WriteDebugLog(SafeJsonConvert.SerializeObject(objVeevaProdLinkedService, objClient.SerializationSettings));

            #endregion

            List<VeevaOdsFieldMappingModel> lstVeevaOdsFieldMappingModel = GetVeevaOdsFielMappingDetails();

            #region Dataset Creation Section

            // Create Azure SQL Database datasets
            foreach (string strOdsTableName in lstVeevaOdsFieldMappingModel.Select(item => item.OdsTableName).Distinct())
            {
                LogHelper.WriteDebugLog("Creating dataset " + strOdsTableName.Replace("_", "") + "Dataset" + "...");
                DatasetResource sqlDataset = new DatasetResource(
                    new AzureSqlTableDataset
                    {
                        LinkedServiceName = new LinkedServiceReference
                        {
                            ReferenceName = "OdsSqlLinkedService"
                        },
                        TableName = strOdsTableName,
                        Folder = new DatasetFolder("StagingODSDatasets")
                    }
                );

                objClient.Datasets.CreateOrUpdate(strResourceGroupName, strAzureDataFactoryName, strOdsTableName.Replace("_", "") + "Dataset", sqlDataset);
                Console.WriteLine(SafeJsonConvert.SerializeObject(sqlDataset, objClient.SerializationSettings));
            }

            // Create Veeva datasets
            foreach (var objModel in lstVeevaOdsFieldMappingModel.Select(item => new { item.VeevaObjectAPIName, item.OdsTableName }).Distinct())
            {
                LogHelper.WriteDebugLog("Creating dataset " + objModel.OdsTableName.Replace("Staging_", "Veeva").Replace("_", "") + "Dataset" + "...");
                DatasetResource sqlDataset = new DatasetResource(
                    new SalesforceObjectDataset
                    {
                        LinkedServiceName = new LinkedServiceReference
                        {
                            ReferenceName = "VeevaProdLinkedService"
                        },
                        ObjectApiName = objModel.VeevaObjectAPIName,
                        Folder = new DatasetFolder("VeevaODSDatasets")
                    }
                );

                objClient.Datasets.CreateOrUpdate(strResourceGroupName, strAzureDataFactoryName, objModel.OdsTableName.Replace("Staging_", "Veeva").Replace("_", "") + "Dataset", sqlDataset);
                Console.WriteLine(SafeJsonConvert.SerializeObject(sqlDataset, objClient.SerializationSettings));
            }

            #endregion

            #region Pipeline Creation Section

            // Create a pipeline with copy and transformation activities
            LogHelper.WriteDebugLog("Creating pipeline " + "VeevaToODSPipeline" + "...");

            int loopLimit = 18;
            int pipelineNum = 1;

            string[] tempArrVeevaObjects = strVeevaObjectsDataLoadOrder.Split(',');
            string[] arrObjectsWithDeleteSupport = strObjectsWithDeleteSupport.Split(',');

            for (int i = 0; i < tempArrVeevaObjects.Length; i = i + loopLimit)
            {
                PipelineResource objPipeline = new PipelineResource();
                objPipeline.Activities = new List<Activity>();

                var arrVeevaObjectsDataLoadOrder = tempArrVeevaObjects.Skip(i).Take(loopLimit).ToList();
                for (int iObjectIndex = 0; iObjectIndex < arrVeevaObjectsDataLoadOrder.Count; iObjectIndex++)
                {

                    var objModel = lstVeevaOdsFieldMappingModel.Where(item => item.OdsTableName == "Staging_" + arrVeevaObjectsDataLoadOrder[iObjectIndex]).Select(item => new { item.VeevaObjectAPIName, item.OdsTableName }).Distinct().First();
                    string strVeevaFieldList = lstVeevaOdsFieldMappingModel.Where(item => item.OdsTableName == objModel.OdsTableName).Select(item => item.VeevaFieldAPIName.Replace(" ", "")).CommaSeparate(item => item);
                    string strSOQLWhereClase = $" WHERE SystemModstamp >= LAST_N_DAYS:{iVeevaDataLoadForLastNDays} ";
                    string strAdditionalSOQLWhereClase = string.Empty;

                    // If the Delete support is needed for an object, then we need to load full data everyday.
                    if (strPipelineDataLoadMode == "FULL" || arrObjectsWithDeleteSupport.Contains(objModel.OdsTableName.Replace("Staging_", "")))
                    {
                        strSOQLWhereClase = string.Empty;
                    }

                    // Additional filter for call specific tables.
                    // Load only submitted calls into ODS.
                    switch (objModel.OdsTableName.Replace("Staging_", ""))
                    {
                        case "Call":
                            strAdditionalSOQLWhereClase = " Status_vod__c = 'Submitted_vod' ";
                            break;
                        case "CallDetail":
                        case "CallSample":
                        case "CallDiscussion":
                        case "CallKeyMessage":
                            strAdditionalSOQLWhereClase = " Call2_vod__r.Status_vod__c = 'Submitted_vod' ";
                            break;
                    }

                    // If there are any additional WHERE clauses, append them to the main WHERE clause string.
                    if (!string.IsNullOrWhiteSpace(strAdditionalSOQLWhereClase))
                    {
                        if (string.IsNullOrWhiteSpace(strSOQLWhereClase))
                        {
                            strSOQLWhereClase = $" WHERE {strAdditionalSOQLWhereClase}";
                        }
                        else
                        {
                            strSOQLWhereClase = $"{strSOQLWhereClase} AND {strAdditionalSOQLWhereClase}";
                        }
                    }

                    if (iObjectIndex < 3)
                    {
                        objPipeline.Activities.Add(new CopyActivity()
                        {
                            Name = $"Copy{objModel.OdsTableName.Replace("Staging_", "").Replace("_", "")}Activity",
                            Inputs = new List<DatasetReference>
                        {
                            new DatasetReference() { ReferenceName = objModel.OdsTableName.Replace("Staging_", "Veeva").Replace("_", "") + "Dataset" }
                        },
                            Outputs = new List<DatasetReference>
                        {
                            new DatasetReference { ReferenceName = objModel.OdsTableName.Replace("_", "") + "Dataset" }
                        },
                            Source = new SalesforceSource { Query = $"SELECT {strVeevaFieldList} FROM {objModel.VeevaObjectAPIName} {strSOQLWhereClase}", ReadBehavior = "query" },
                            Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE {objModel.OdsTableName}" }
                        });
                    }
                    else
                    {
                        objPipeline.Activities.Add(new CopyActivity()
                        {
                            Name = $"Copy{objModel.OdsTableName.Replace("Staging_", "").Replace("_", "")}Activity",
                            Inputs = new List<DatasetReference>
                        {
                            new DatasetReference() { ReferenceName = objModel.OdsTableName.Replace("Staging_", "Veeva").Replace("_", "") + "Dataset" }
                        },
                            Outputs = new List<DatasetReference>
                        {
                            new DatasetReference { ReferenceName = objModel.OdsTableName.Replace("_", "") + "Dataset" }
                        },
                            Source = new SalesforceSource { Query = $"SELECT {strVeevaFieldList} FROM {objModel.VeevaObjectAPIName} {strSOQLWhereClase}", ReadBehavior = "query" },
                            Sink = new SqlSink { PreCopyScript = $"TRUNCATE TABLE {objModel.OdsTableName}" },
                            DependsOn = new List<ActivityDependency>
                        {
                            /* Three activities are chained together to run in parallel.
                             * This is because Salesforce throws an error if there are too many activities running in parallel.
                             * The activities are also grouped in a group of 3 activities and in each group we have large and small objects.
                             * The object indexes are calculated using the below logic.
                             * (0,1,2) are the indexes of acitivities in first group.
                             * (3,4,5) are the indexes of acitivities in second group. These should start only after (0,1,2) are completed.
                             * (6,7,8) are the indexes of acitivities in second group. These should start only after (3,4,5) are completed.
                             * Below is the diagram of how the activities are going to be chained.
                             * 
                             * 0                      3                      6
                             * Copy---Transform---|---Copy---Transform---|---Copy---Transform
                             *                    |                      |
                             * 1                  |   4                  |   7
                             * Copy---Transform---|---Copy---Transform---|---Copy---Transform
                             *                    |                      |
                             * 2                  |   5                  |   8
                             * Copy---Transform---|---Copy---Transform---|---Copy---Transform
                             */
                            new ActivityDependency($"Transform{arrVeevaObjectsDataLoadOrder[iObjectIndex - 3 - (iObjectIndex % 3)]}Activity", new List<string> { "Succeeded" }),
                            new ActivityDependency($"Transform{arrVeevaObjectsDataLoadOrder[iObjectIndex - 2 - (iObjectIndex % 3)]}Activity", new List<string> { "Succeeded" }),
                            new ActivityDependency($"Transform{arrVeevaObjectsDataLoadOrder[iObjectIndex - 1 - (iObjectIndex % 3)]}Activity", new List<string> { "Succeeded" })
                        }
                        });
                    }

                    objPipeline.Activities.Add(new SqlServerStoredProcedureActivity
                    {
                        Name = $"Transform{objModel.OdsTableName.Replace("Staging_", "").Replace("_", "")}Activity",
                        StoredProcedureName = $"sp_{objModel.OdsTableName.Replace("Staging_", "").Replace("_", "").ToLower()}_transform",
                        LinkedServiceName = new LinkedServiceReference
                        {
                            ReferenceName = "OdsSqlLinkedService"
                        },
                        DependsOn = new List<ActivityDependency> { new ActivityDependency($"Copy{objModel.OdsTableName.Replace("Staging_", "").Replace("_", "")}Activity", new List<string> { "Succeeded" }) }
                    });
                }

                // Add the Veeva Data Health Activity to the pipeline.
                objPipeline.Activities.Add(new SqlServerStoredProcedureActivity
                {
                    Name = $"VeevaDataHealthCheckActivity",
                    StoredProcedureName = $"sp_veeva_datahealthcheck",
                    LinkedServiceName = new LinkedServiceReference
                    {
                        ReferenceName = "OdsSqlLinkedService"
                    },
                    DependsOn = new List<ActivityDependency> { new ActivityDependency(objPipeline.Activities.Last().Name, new List<string> { "Succeeded" }) }
                });

                objClient.Pipelines.CreateOrUpdate(strResourceGroupName, strAzureDataFactoryName, "VeevaToODSPipline" + pipelineNum, objPipeline);

                pipelineNum = pipelineNum + 1;
            }



            //Console.WriteLine(SafeJsonConvert.SerializeObject(objPipeline, objClient.SerializationSettings));

            #endregion

            for (int i = 1; i <= pipelineNum - 1; i++)
            {
                var objList = objClient.Pipelines.Get(strResourceGroupName, strAzureDataFactoryName, "VeevaToODSPipline" + i);
                //Console.WriteLine(SafeJsonConvert.SerializeObject(objList, objClient.SerializationSettings));

                string strPipelineJSON = SafeJsonConvert.SerializeObject(objList, objClient.SerializationSettings);
                strPipelineJSON = @"{
    ""name"": ""VeevaToODSPipline"",
    ""type"": ""Microsoft.DataFactory/factories/pipelines""," + strPipelineJSON.Substring(2);

                foreach (var objModel in lstVeevaOdsFieldMappingModel.Select(item => new { item.VeevaObjectAPIName, item.OdsTableName }).Distinct())
                {
                    //var objModel = lstVeevaOdsFieldMappingModel.Where(item => item.OdsTableName == "Staging_Address").Select(item => new { item.VeevaObjectAPIName, item.OdsTableName }).Distinct().First();

                    string strVeevaFieldList = @",
                    ""translator"": {
	                    ""type"": ""TabularTranslator"",
	                    ""columnMappings"": {" +
                            lstVeevaOdsFieldMappingModel.Where(item => item.OdsTableName == objModel.OdsTableName).Select(item => "\r\n\"" + item.VeevaFieldAPIName.Replace(" ", "") + "\": \"" + item.OdsColumnName + "\"").CommaSeparate(item => item) +
                            @"
	                    }
                    }";

                    int iPreCopyScriptIndex = strPipelineJSON.IndexOf(@"""preCopyScript"": ""TRUNCATE TABLE " + objModel.OdsTableName);

                    if (iPreCopyScriptIndex > 0)
                        strPipelineJSON = strPipelineJSON.Insert(strPipelineJSON.IndexOf("}", iPreCopyScriptIndex) + 1, strVeevaFieldList);
                }

                File.WriteAllText(@"C:\Users\ManjuH\Turnkey\Pipeline.json", strPipelineJSON);
            }

            //LogHelper.WriteDebugLog(strPipelineJSON);
        }

        public static bool LoadDIIDetails()
        {
            Excel.Application xlApp = null;
            Excel.Workbook xlWorkbook = null;
            Excel._Worksheet xlWorksheet = null;
            Excel.Range xlRange = null;
            try
            {
                //Create COM Objects. Create a COM object for everything that is referenced
                xlApp = new Excel.Application();
                xlWorkbook = xlApp.Workbooks.Open(strDIIFileName);
                List<FieldDefinitionModel> lstFieldDefinitions = new List<FieldDefinitionModel>();

                // Loop through all the excel sheets
                for (int iSheet = 1; iSheet <= xlWorkbook.Sheets.Count; iSheet++)
                {
                    xlWorksheet = xlWorkbook.Sheets[iSheet];
                    xlRange = xlWorksheet.UsedRange;

                    if (xlWorksheet.Name.Contains("LOV"))
                    {

                        continue;
                    }

                    // We are not exactly sure as to which column is present in which index. 
                    // Hence finding the index of each column that we are interested in.
                    int iObjectNameIndex = -1, iObjectAPINameIndex = -1, iFieldNameIndex = -1, iFieldAPINameIndex = -1, iDataTypeIndex = -1, iSCDRequiredIndex = -1;
                    for (int column = 1; column <= xlRange.Columns.Count; column++)
                    {
                        if (xlRange.Cells[1, column] != null && xlRange.Cells[1, column].Value2 != null)
                        {
                            string strColumnName = ((string)xlRange.Cells[1, column].Value2).ToUpper();
                            if (strColumnName.Contains("OBJECT") && !strColumnName.Contains("API"))
                                iObjectNameIndex = column;
                            else if (strColumnName.Contains("OBJECT") && strColumnName.Contains("API"))
                                iObjectAPINameIndex = column;
                            else if (strColumnName.Contains("LABEL"))
                                iFieldNameIndex = column;
                            else if (strColumnName.Contains("API") && strColumnName.Contains("ATTRIBUTE"))
                                iFieldAPINameIndex = column;
                            else if (strColumnName.Contains("TYPE"))
                                iDataTypeIndex = column;
                            else if (strColumnName.Contains("SCD"))
                                iSCDRequiredIndex = column;
                        }
                    }

                    if (iObjectNameIndex > 0 && iObjectAPINameIndex > 0 && iFieldNameIndex > 0 && iFieldAPINameIndex > 0 && iDataTypeIndex > 0)
                    {
                        for (int row = 2; row <= xlRange.Rows.Count; row++)
                        {
                            // Check if there is value for each of the following fields, ObjectName, FieldLabel, FieldName, DataType
                            // If the value is not present, then throw an error.
                            if ((xlRange.Cells[row, iObjectNameIndex] != null && xlRange.Cells[row, iObjectNameIndex].Value2 != null) &&
                                (xlRange.Cells[row, iObjectAPINameIndex] != null && xlRange.Cells[row, iObjectAPINameIndex].Value2 != null) &&
                                (xlRange.Cells[row, iFieldNameIndex] != null && xlRange.Cells[row, iFieldNameIndex].Value2 != null) &&
                                (xlRange.Cells[row, iFieldAPINameIndex] != null && xlRange.Cells[row, iFieldAPINameIndex].Value2 != null) &&
                                (xlRange.Cells[row, iDataTypeIndex] != null && xlRange.Cells[row, iDataTypeIndex].Value2 != null))
                            {
                                // SCD field is optional since some Veeva objects may not need SCD completely, 
                                // in which case DII dcoument may not contain this column altogether.
                                if (iSCDRequiredIndex > 0 &&
                                    xlRange.Cells[row, iSCDRequiredIndex] != null &&
                                    xlRange.Cells[row, iSCDRequiredIndex].Value2 != null)
                                {
                                    lstFieldDefinitions.Add(new FieldDefinitionModel
                                    {
                                        ObjectName = ((string)xlRange.Cells[row, iObjectNameIndex].Value2).Trim(),
                                        ObjectAPIName = ((string)xlRange.Cells[row, iObjectAPINameIndex].Value2).Trim(),
                                        FieldName = ((string)xlRange.Cells[row, iFieldNameIndex].Value2).Trim(),
                                        FieldAPIName = ((string)xlRange.Cells[row, iFieldAPINameIndex].Value2).Trim(),
                                        DataType = ((string)xlRange.Cells[row, iDataTypeIndex].Value2).Trim(),
                                        SCDRequired = (((string)xlRange.Cells[row, iSCDRequiredIndex].Value2).Trim()).ToUpper() == "YES" ? true : false
                                    });
                                }
                                else
                                {
                                    lstFieldDefinitions.Add(new FieldDefinitionModel
                                    {
                                        ObjectName = ((string)xlRange.Cells[row, iObjectNameIndex].Value2).Trim(),
                                        ObjectAPIName = ((string)xlRange.Cells[row, iObjectAPINameIndex].Value2).Trim(),
                                        FieldName = ((string)xlRange.Cells[row, iFieldNameIndex].Value2).Trim(),
                                        FieldAPIName = ((string)xlRange.Cells[row, iFieldAPINameIndex].Value2).Trim(),
                                        DataType = ((string)xlRange.Cells[row, iDataTypeIndex].Value2).Trim(),
                                        SCDRequired = false
                                    });
                                }
                            }
                            else if (xlRange.Cells[row, iObjectNameIndex] != null && xlRange.Cells[row, iObjectNameIndex].Value2 != null)
                            {
                                LogHelper.WriteDebugLog($"Missing data for few fields in Object: {(string)xlRange.Cells[row, iObjectNameIndex].Value2}");
                            }
                        }
                    }
                }

                if (lstFieldDefinitions.Count > 0)
                {
                    InsertFieldDefinitions(lstFieldDefinitions);
                }

                return true;
            }
            catch (Exception ex)
            {
                LogHelper.WriteDebugLog(ex.StackTrace);
                throw ex;
            }
            finally
            {
                //cleanup
                GC.Collect();
                GC.WaitForPendingFinalizers();

                //rule of thumb for releasing com objects:
                //  never use two dots, all COM objects must be referenced and released individually
                //  ex: [somthing].[something].[something] is bad

                //release com objects to fully kill excel process from running in the background
                Marshal.ReleaseComObject(xlRange);
                Marshal.ReleaseComObject(xlWorksheet);

                //close and release
                xlWorkbook.Close();
                Marshal.ReleaseComObject(xlWorkbook);

                //quit and release
                xlApp.Quit();
                Marshal.ReleaseComObject(xlApp);
            }
        }

        private static void InsertFieldDefinitions(List<FieldDefinitionModel> lstFieldDefinitions)
        {
            StringBuilder sbInsertQueries = new StringBuilder();
            foreach (FieldDefinitionModel item in lstFieldDefinitions)
            {
                sbInsertQueries.AppendLine($"INSERT INTO FieldDefinition VALUES('{item.ObjectName}', '{item.ObjectAPIName}', '{item.FieldName}', '{item.FieldAPIName}', '{item.DataType}', {(item.SCDRequired == true ? "1" : "0")});");
            }

            ExecuteQuery(sbInsertQueries.ToString());
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

        private static void CreateOdsAutomationDatabseObjects()
        {
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\FieldDefinition.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\VeevaOdsDataTypeMapping.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\VeevaOdsFieldMapping.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\OdsGeneratedSchema.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\fn_GetCamelCase.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\fn_GetStringWithoutDigits.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\sp_generate_veeva_ods_field_mapping.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\sp_generate_ods_objects.sql"));
        }

        private static void CreateScdDatabseObjects()
        {
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\AuditTableDefinition.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\AuditColumnDefinition.sql"));
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\sp_generate_trigger.sql"));
        }

        private static void CreateOdsDatabaseObjects()
        {
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\LogMessage.sql"));
            ExecuteQuery("EXEC sp_generate_veeva_ods_field_mapping");
            ExecuteQuery($"EXEC sp_generate_ods_objects 'All', {(bCreateOdsObjects ? "1" : "0")}, {(bSCDNeeded ? "1" : "0")}");
            ExecuteQuery(File.ReadAllText(@"DatabaseObjects\sp_generate_datahealthcheck_procedure.sql"));
            ExecuteQuery("EXEC sp_generate_datahealthcheck_procedure");
        }

        private static List<OdsObjectSchemaModel> GetOdsGeneratedSchema()
        {
            try
            {
                List<OdsObjectSchemaModel> lstSchemas = new List<OdsObjectSchemaModel>();
                using (SqlConnection sqlConn = new SqlConnection(strSQLConnectionString))
                {
                    string strQuery = "SELECT OdsTableName, StagingTableSchema, ProductionTableSchema, TransformationSPSchema FROM OdsGeneratedSchema";
                    using (SqlCommand cmd = new SqlCommand(strQuery, sqlConn))
                    {
                        sqlConn.Open();
                        SqlDataReader drSchema = cmd.ExecuteReader();
                        while (drSchema.Read())
                        {
                            // Staging Table Schema
                            lstSchemas.Add(new OdsObjectSchemaModel
                            {
                                ObjectName = "Staging_" + drSchema.GetString(0),
                                ObjectScript = drSchema.GetString(1),
                                ObjectType = OdsObjectTypeEnum.Table,
                            });

                            // Production Table Schema
                            lstSchemas.Add(new OdsObjectSchemaModel
                            {
                                ObjectName = drSchema.GetString(0),
                                ObjectScript = drSchema.GetString(2),
                                ObjectType = OdsObjectTypeEnum.Table,
                            });

                            // Transformation Stored Procedure Schema
                            lstSchemas.Add(new OdsObjectSchemaModel
                            {
                                ObjectName = "sp_" + drSchema.GetString(0).ToLower() + "_transform",
                                ObjectScript = drSchema.GetString(3),
                                ObjectType = OdsObjectTypeEnum.StoredProcedure,
                            });
                        }
                    }
                }

                using (SqlConnection sqlConn = new SqlConnection(strSQLConnectionString))
                {
                    string strQuery = @"SELECT name, REPLACE(Object_definition(object_id), 'CREATE   PROCEDURE', 'CREATE OR ALTER PROCEDURE')
                                FROM sys.procedures WHERE name IN ('sp_veeva_datahealthcheck')";
                    using (SqlCommand cmd = new SqlCommand(strQuery, sqlConn))
                    {
                        sqlConn.Open();
                        SqlDataReader drSchema = cmd.ExecuteReader();
                        while (drSchema.Read())
                        {
                            // Stored Procedure Schema
                            lstSchemas.Add(new OdsObjectSchemaModel
                            {
                                ObjectName = drSchema.GetString(0),
                                ObjectScript = drSchema.GetString(1),
                                ObjectType = OdsObjectTypeEnum.StoredProcedure,
                            });
                        }
                    }
                }

                return lstSchemas;
            }
            catch (Exception ex)
            {
                LogHelper.WriteDebugLog(ex.Message);
                LogHelper.WriteDebugLog(ex.StackTrace);
                return null;
            }
        }

        private static List<VeevaOdsFieldMappingModel> GetVeevaOdsFielMappingDetails()
        {
            try
            {
                List<VeevaOdsFieldMappingModel> lstSchemas = new List<VeevaOdsFieldMappingModel>();
                using (SqlConnection sqlConn = new SqlConnection(strSQLConnectionString))
                {
                    // Add any specific WHERE condition if any existing Staging tables have to be excluded for creating in Azure.
                    // Added the condition in below SQL ( AND t.name NOT LIKE 'Staging_SR%')
                    string strQuery = @"
WITH cte_VeevaOdsFieldMapping AS
(
	SELECT CASE 
			WHEN M.VeevaFieldAPIName IS NULL AND c.name = 'VeevaId' THEN 'Id'
			WHEN M.VeevaFieldAPIName IS NULL THEN c.name
			ELSE M.VeevaFieldAPIName
		END AS VeevaFieldAPIName,
		t.name AS OdsTableName, c.name AS OdsColumnName, M.VeevaObjectAPIName
	FROM sys.tables t
	INNER JOIN sys.columns c on t.object_id = c.object_id
	LEFT OUTER JOIN VeevaOdsFieldMapping M ON t.name = 'Staging_' + M.OdsTableName AND c.name = M.OdsColumnName
	WHERE t.name LIKE 'Staging_%' AND t.name NOT LIKE 'Staging_SR%'
)
SELECT
	M.OdsTableName, OdsColumnName, ISNULL(M.VeevaObjectAPIName, D.VeevaObjectAPIName) AS VeevaObjectAPIName, VeevaFieldAPIName
FROM cte_VeevaOdsFieldMapping M
LEFT OUTER JOIN 
	(
		SELECT DISTINCT OdsTableName, VeevaObjectAPIName 
		FROM cte_VeevaOdsFieldMapping 
		WHERE VeevaObjectAPIName IS NOT NULL
	) AS D ON M.OdsTableName = D.OdsTableName
;";
                    using (SqlCommand cmd = new SqlCommand(strQuery, sqlConn))
                    {
                        sqlConn.Open();
                        SqlDataReader drSchema = cmd.ExecuteReader();
                        while (drSchema.Read())
                        {
                            lstSchemas.Add(new VeevaOdsFieldMappingModel
                            {
                                OdsTableName = drSchema.GetString(0),
                                OdsColumnName = drSchema.GetString(1),
                                VeevaObjectAPIName = drSchema.GetString(2),
                                VeevaFieldAPIName = drSchema.GetString(3),
                            });
                        }
                    }
                }

                return lstSchemas;
            }
            catch (Exception ex)
            {
                LogHelper.WriteDebugLog(ex.Message);
                LogHelper.WriteDebugLog(ex.StackTrace);
                return null;
            }
        }
    }
}

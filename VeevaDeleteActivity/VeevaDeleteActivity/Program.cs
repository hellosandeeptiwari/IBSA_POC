using Newtonsoft.Json;
using SFBulkAPIStarter;
using System;
using System.Collections.Generic;
using System.IO;

/// <summary>
/// Install-Package Newtonsoft.Json -Version 12.0.3
/// 
/// Issue - 1:
/// https://developer.salesforce.com/forums/?id=906F0000000Aj5kIAC
/// Error with ListViewRecordColumn[][]. Removed extra [] in Reference.cs class.
/// You should not update the Web Reference. Doing so will overwrite your changes since the class will be re-generated.
/// 
/// Issue - 2: Any application which is above .Net Framework 4.6.1 is not working in ADFv2.
/// It is throwing an error with ErrorCode: 2010. Hit Unexpected error.
/// </summary>
namespace VeevaDeleteActivity
{
    class Program
    {
        private static CreateJobRequest BuildDefaultUpsertAccountCreateJobRequest(String externalIdFieldName, string tableName)
        {
            CreateJobRequest request = BuildDefaultCreateJobRequest(JobOperation.Upsert, tableName);
            request.ExternalIdFieldName = externalIdFieldName;
            return request;
        }

        private static CreateJobRequest BuildDefaultCreateJobRequest(JobOperation operation, string tableName)
        {
            CreateJobRequest jobRequest = new CreateJobRequest();
            jobRequest.ContentType = JobContentType.CSV;
            jobRequest.Operation = operation;
            jobRequest.Object = tableName;

            return jobRequest;
        }

        private static CreateBatchRequest BuildCreateBatchRequest(String jobId, String batchContents)
        {
            return new CreateBatchRequest()
            {
                JobId = jobId,
                BatchContents = batchContents,
                BatchContentType = BatchContentType.CSV
            };
        }

        private static string strVeevaUserId;
        private static string strVeevaPasswordAndSecurityToken;
        private static string strVeevaUrl;

        static void Main(string[] args)
        {
            //// Prod
            strVeevaUserId = "conexus.admin@mtpa.com";
            strVeevaPasswordAndSecurityToken = "[7=D,4szH'C!" + "X0grEq1hfIDPHhxlwbfR5wug";
            strVeevaUrl = "https://login.salesforce.com/services/Soap/u/49.0";


            //// Dev
            //strVeevaUserId = "conexus.admin@mtpa.com.full";
            //strVeevaPasswordAndSecurityToken = "S_rsr9*C!" + "yycz2WFiIPUiY8vFszPqN6Q1";
            ////strVeevaUrl = "https://test.salesforce.com/services/Soap/c/40.0/0DF1D000000003K";
            //strVeevaUrl = "https://test.salesforce.com/services/Soap/u/49.0";

            //strVeevaUserId = "conexus.admin@cnxpharma.com.trg14";
            //strVeevaPasswordAndSecurityToken = "Conexus123!" + "Xl4npK6E0gDVKftIB05IkVb6";
            ////strVeevaUrl = "https://test.salesforce.com/services/Soap/c/40.0/0DF1D000000003K";
            //strVeevaUrl = "https://test.salesforce.com/services/Soap/u/49.0";

            //string strVeevaObjects = "PS_Area_of_Interest_CNX__c,PS_OnTopic_CNX__c";
            //DeleteByObjectList(strVeevaObjects.Split(','));

            //DeleteById("Account_Territory_Loader_vod__c", "a0w2f000000NlDzAAK");

            // Pull the Veeva object list from Extend Properties
            Console.WriteLine("Printing the acitivty properties");
            dynamic objActitivy = JsonConvert.DeserializeObject(File.ReadAllText("activity.json"));
            Console.WriteLine(objActitivy);

            if (!(objActitivy.typeProperties.ToString().Contains("extendedProperties")))
            {
                throw new Exception("extendedProperties are mandatory. Please add extendedProperties(VeevaObjects,VeevaQueries) to the Azure activity" +
                    "(VeevaObjects or VeevaQueries property should be Pipe(|) delimited).");
            }
            Console.WriteLine("Printing the Extended properies");
            //if (!(objActitivy.typeProperties.extendedProperties.ToString().Contains("strVeevaUserId") && objActitivy.typeProperties.extendedProperties.ToString().Contains("strVeevaPasswordAndSecurityToken") && objActitivy.typeProperties.extendedProperties.ToString().Contains("strVeevaUrl")))
            //{
            //    throw new Exception("strVeevaUserId, strVeevaPasswordAndSecurityToken(UserName+Password) and strVeevaUrl are mandatory." +
            //        " Please add strVeevaUserId, strVeevaPasswordAndSecurityToken(UserName+Password) and strVeevaUrl properties to the Extended Properties " +
            //        "in the Azure activity");
            //}
            //else
            //{
            //    strVeevaUserId = objActitivy.typeProperties.extendedProperties.strVeevaUserId.ToString();
            //    strVeevaPasswordAndSecurityToken = objActitivy.typeProperties.extendedProperties.strVeevaPasswordAndSecurityToken.ToString();
            //    strVeevaUrl = objActitivy.typeProperties.extendedProperties.strVeevaUrl.ToString();
            //}
            if (!(objActitivy.typeProperties.extendedProperties.ToString().Contains("VeevaObjects") || objActitivy.typeProperties.extendedProperties.ToString().Contains("VeevaQueries")))
            {
                throw new Exception("VeevaObjects or VeevaQueries property is mandatory." +
                    " Please enter either of one(VeevaObjects Or VeevaQueries property should be Pipe(|) delemited.");
            }
            if (objActitivy.typeProperties.extendedProperties.ToString().Contains("VeevaObjects"))
            {
                string strVeevaObjects = objActitivy.typeProperties.extendedProperties.VeevaObjects.ToString();
                Console.WriteLine($"Deleting data from the following Veeva objects: {strVeevaObjects}");
                DeleteByObjectList(strVeevaObjects.Split('|'));
            }
            if (objActitivy.typeProperties.extendedProperties.ToString().Contains("VeevaQueries"))
            {
                string strVeevaQueries = objActitivy.typeProperties.extendedProperties.VeevaQueries.ToString();
                Console.WriteLine($"Deleting data from the following Veeeva Query: {strVeevaQueries}");
                DeleteBySOQLQueryList(strVeevaQueries.Split('|'));
            }
        }

        private static bool DeleteById(string strVeevaObjectName, string idToDelete)
        {
            string strBatchContents = string.Empty, strResultJSON = string.Empty;
            SFBulkAPIStarter.BulkApiClient apiClient;
            CreateJobRequest deleteJobRequest;
            Job deleteJob, queryJob;
            try
            {
                // Create BulkAPI client object.
                apiClient = new SFBulkAPIStarter.BulkApiClient(strVeevaUserId, strVeevaPasswordAndSecurityToken, strVeevaUrl);

                // Create Job request object
                deleteJobRequest = BuildDefaultCreateJobRequest(JobOperation.Delete, strVeevaObjectName);

                // Create Job
                deleteJob = apiClient.CreateJob(deleteJobRequest);

                // Create CSV batch request contents
                strBatchContents = $"Id{Environment.NewLine}{idToDelete}";

                // Create batch request
                CreateBatchRequest insertAccountBatchRequest = BuildCreateBatchRequest(deleteJob.Id, strBatchContents);

                // Create batch object
                Batch insertMergeBatch = apiClient.CreateBatch(insertAccountBatchRequest);

                // Close job so no more batches are added.
                apiClient.CloseJob(deleteJob.Id);

                // Complete the job since we will not be able to fetch the results until the job is completed.
                queryJob = apiClient.GetCompletedJob(deleteJob.Id);

                // Fetch the batch response JSON.
                strResultJSON = apiClient.GetBatchResult(deleteJob.Id, insertMergeBatch.Id);
                Console.WriteLine("Below is the complete response JSON from Veeva:");
                Console.WriteLine(strResultJSON);

                // Check for the status of each record and update status accordingly.
                var lstBulkAPIResults = apiClient.GetBulkAPIResult(strResultJSON);
                Console.WriteLine($"Id: {lstBulkAPIResults[0].Id}, Success: {lstBulkAPIResults[0].Success}, Failure: {lstBulkAPIResults[0].Error}");
                if (lstBulkAPIResults[0].Success)
                {
                    Console.WriteLine("Record: {lstBulkAPIResults[0].Id} deleted successfully");
                    return true;
                }
                else
                {
                    Console.WriteLine($"Error: { lstBulkAPIResults[0].Error}");
                    return false;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(strBatchContents);
                Console.WriteLine(strResultJSON);
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
                throw ex;
            }
            finally
            {
                //Explicitely clearing variables
                deleteJob = null;
                queryJob = null;
                deleteJob = null;
                apiClient = null;
            }
        }

        private static bool DeleteByIds(string strVeevaObjectName, IEnumerable<string> lstIdToDelete)
        {

            return false;
        }

        private static bool DeleteByObject(string strVeevaObjectName)
        {

            return false;
        }

        private static bool DeleteByObjectList(IEnumerable<string> lstVeevaObjectNames)
        {
            foreach (string strVeevaObjectName in lstVeevaObjectNames)
            {
                DeleteByQuery($"SELECT Id FROM {strVeevaObjectName}", strVeevaObjectName);
            }

            return false;
        }

        //select Id from Account|select Id from Task
         //select Id from Account where Id = 'tttt'
        private static bool DeleteBySOQLQueryList(IEnumerable<string> lstSOQLQueries)
        {
            foreach (string strSOQLQuery in lstSOQLQueries)
            {
                string strSelectSOQLQuery = strSOQLQuery;
                // To get the Veeva Object Name 
                while (strSelectSOQLQuery.IndexOf("  ") > 0)
                {
                    strSelectSOQLQuery = strSelectSOQLQuery.Replace("  ", " ");
                }

                strSelectSOQLQuery = strSelectSOQLQuery.ToUpper();
                int iStartIndex = strSelectSOQLQuery.IndexOf(" ", strSelectSOQLQuery.IndexOf("FROM")) + 1;
                int iEndIndex = strSelectSOQLQuery.IndexOf(" ", iStartIndex);
                string strVeevaObjectName;
                if (iEndIndex > 0)
                {
                    strVeevaObjectName = strSelectSOQLQuery.Substring(iStartIndex, iEndIndex - iStartIndex);
                    Console.WriteLine(strVeevaObjectName);
                }
                else
                {
                    strVeevaObjectName = strSelectSOQLQuery.Substring(iStartIndex);
                    Console.WriteLine(strVeevaObjectName);
                }
                DeleteByQuery(strSOQLQuery, strVeevaObjectName);
            }
            return false;
        }

        private static bool DeleteByQuery(string strSOQLQuery, string strVeevaObjectName)
        {
            string strBatchContents = SelectByQuery(strSOQLQuery, strVeevaObjectName);

            // The input batch should have atleast one Id to delete. Otherwise there is no point in making a delete api call.
            if (string.IsNullOrWhiteSpace(strBatchContents) || strBatchContents == "Records not found for this query")
            {
                Console.WriteLine("Input batch is Empty. Hence there is nothing to delete");
                return false;
            }

            string strResultJSON = string.Empty;
            SFBulkAPIStarter.BulkApiClient apiClient;
            CreateJobRequest deleteJobRequest;
            Job deleteJob, queryJob;
            try
            {
                // Create BulkAPI client object.
                apiClient = new SFBulkAPIStarter.BulkApiClient(strVeevaUserId, strVeevaPasswordAndSecurityToken, strVeevaUrl);

                // Create Job request object
                deleteJobRequest = BuildDefaultCreateJobRequest(JobOperation.Delete, strVeevaObjectName);

                // Create Job
                deleteJob = apiClient.CreateJob(deleteJobRequest);

                // Create batch request
                CreateBatchRequest insertAccountBatchRequest = BuildCreateBatchRequest(deleteJob.Id, strBatchContents);

                // Create batch object
                Batch insertMergeBatch = apiClient.CreateBatch(insertAccountBatchRequest);

                // Close job so no more batches are added.
                apiClient.CloseJob(deleteJob.Id);

                // Complete the job since we will not be able to fetch the results until the job is completed.
                queryJob = apiClient.GetCompletedJob(deleteJob.Id);

                // Fetch the batch response JSON.
                strResultJSON = apiClient.GetBatchResult(deleteJob.Id, insertMergeBatch.Id);
                Console.WriteLine("Below is the complete response JSON from Veeva:");
                Console.WriteLine(strResultJSON);

                // Check for the status of each record and update status accordingly.
                var lstBulkAPIResults = apiClient.GetBulkAPIResult(strResultJSON);
                Console.WriteLine($"Id: {lstBulkAPIResults[0].Id}, Success: {lstBulkAPIResults[0].Success}, Failure: {lstBulkAPIResults[0].Error}");
                if (lstBulkAPIResults[0].Success)
                {
                    Console.WriteLine("Record: {lstBulkAPIResults[0].Id} deleted successfully");
                    return true;
                }
                else
                {
                    Console.WriteLine($"Error: { lstBulkAPIResults[0].Error}");
                    return false;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(strResultJSON);
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
                throw ex;
            }
            finally
            {
                //Explicitely clearing variables
                deleteJob = null;
                queryJob = null;
                deleteJob = null;
                apiClient = null;
            }
        }

        private static string SelectByQuery(string strSOQLQuery, string strVeevaObjectName)
        {
            string strResultXML = string.Empty;
            SFBulkAPIStarter.BulkApiClient apiClient;
            CreateJobRequest selectJobRequest;
            Job selectJob, queryJob;
            try
            {
                // Create BulkAPI client object.
                apiClient = new SFBulkAPIStarter.BulkApiClient(strVeevaUserId, strVeevaPasswordAndSecurityToken, strVeevaUrl);

                // Create Job request object
                selectJobRequest = BuildDefaultCreateJobRequest(JobOperation.Query, strVeevaObjectName);

                // Create Job
                selectJob = apiClient.CreateJob(selectJobRequest);
                
                // Create batch request
                CreateBatchRequest selectBatchRequest = BuildCreateBatchRequest(selectJob.Id, strSOQLQuery);

                // Create batch object
                Batch selectBatch = apiClient.CreateBatch(selectBatchRequest);

                // Close job so no more batches are added.
                apiClient.CloseJob(selectJob.Id);

                // Complete the job since we will not be able to fetch the results until the job is completed.
                queryJob = apiClient.GetCompletedJob(selectJob.Id);

                if(queryJob.NumberBatchesFailed == queryJob.NumberBatchesTotal)
                {
                    throw new Exception("Error in executing the SELECT query");
                }
                else
                {
                    // Fetch the batch response XML.
                    strResultXML = apiClient.GetBatchResult(selectJob.Id, selectBatch.Id);

                    // Get the Batch results
                    List<String> resultIds = apiClient.GetResultIds(strResultXML);

                    String strBatchQueryResults = apiClient.GetBatchResult(selectBatch.JobId, selectBatch.Id, resultIds[0]);
                    return strBatchQueryResults;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(strResultXML);
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
                throw ex;
            }
            finally
            {
                //Explicitely clearing variables
                selectJob = null;
                queryJob = null;
                selectJob = null;
                apiClient = null;
            }
        }
    }
}

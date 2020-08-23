using SFBulkAPIStarter;
using System;
using System.Collections.Generic;

/// <summary>
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
            // Dev
            strVeevaUserId = "conexus.admin@fidiapharma.com.cnxcfg";
            strVeevaPasswordAndSecurityToken = "5zO{3-ssC!" + "yl1fgUWk7YICwZsMfrfx9YU9X";
            //strVeevaUrl = "https://test.salesforce.com/services/Soap/c/40.0/0DF1D000000003K";
            strVeevaUrl = "https://test.salesforce.com/services/Soap/u/49.0";

            DeleteById("Account_Territory_Loader_vod__c", "a0w2f000000NlDzAAK");
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

        private static bool DeleteById(string strVeevaObjectName, IEnumerable<string> lstIdToDelete)
        {

            return false;
        }

        private static bool DeleteByObject(string strVeevaObjectName)
        {

            return false;
        }

        private static bool DeleteByObjectList(IEnumerable<string> lstVeevaObjectNames)
        {

            return false;
        }

        private static bool DeleteByQuery(string strSOQLQuery)
        {

            return false;
        }
    }
}

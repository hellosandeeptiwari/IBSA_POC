using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using ODSDataConnector.Core.Models;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using static System.Net.WebRequestMethods;
using System.IO;
using System.Reflection.Metadata;
using Microsoft.Data.SqlClient;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.Azure.Management.ResourceManager;
using Microsoft.Rest;
using Microsoft.Rest.Azure.Authentication;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System.Security.Cryptography;

namespace ODSDataConnector.Core.Services
{
    public class StorageService : IStorageService
    {
        private readonly ICustomerRepository customerRepository;

        

        public StorageService(ICustomerRepository customerRepository)
        {
            this.customerRepository = customerRepository;
        }

        public async Task<bool> ExcecuteSQLScripts(DataRequest request)
        {
            try
            {
                var customer = await this.customerRepository.GetCustomerByIdAsync(request.customerId);
                
                var dataSource = await this.customerRepository.GetDataSourceByIdAsync(request);
                

                string connectionString = "DefaultEndpointsProtocol=https;AccountName=odsblobcontainer;AccountKey=EJSJZS/kQFUamEp0w70nJ6yP4CQOwiLjC8abIUtRwdD/EBsxeM3u3nmdTgqA6xrelOX1JLh3Q71WUN7wifzfYA==;EndpointSuffix=core.windows.net";
                BlobServiceClient blobServiceClient = new BlobServiceClient(connectionString);

                string containerName = "odsdataconnector";
                BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient(containerName);

                List<string> tables = containerClient.GetBlobs(prefix: dataSource.StoragePath + "/Tables").Select(b => b.Name).ToList();
                List<string> storeprocedures = containerClient.GetBlobs(prefix: dataSource.StoragePath + "/Storedprocedures").Select(b => b.Name).ToList();

                List<string> scripts = new List<string>();

                foreach (var blob in tables)
                {
                    scripts.Add(await GetBlobContent(blob, containerClient));
                }

                foreach (var blob in storeprocedures)
                {
                    scripts.Add(await GetBlobContent(blob, containerClient));
                }

                var destSQLConnectionString = "Data Source=" + customer.Dbserver + ";Initial Catalog=" + customer.Dbname + ";User Id=" + customer.Username + ";Password=" + customer.Password;
                using (SqlConnection connection = new SqlConnection(destSQLConnectionString))
                {
                    connection.Open();

                    foreach (var script in scripts)
                    {
                        using (SqlCommand command = new SqlCommand(script, connection))
                        {
                            command.ExecuteNonQuery();
                        }
                    }

                }
                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private async Task<string> GetBlobContent(string blobName, BlobContainerClient containerClient)
        {
            string content = string.Empty;
            BlobClient blobClient = containerClient.GetBlobClient(blobName);
            BlobDownloadInfo download = await blobClient.DownloadAsync();
            using (var streamReader = new StreamReader(download.Content))
            {
                content = await streamReader.ReadToEndAsync();
            }

            return content;
        }
    }
}

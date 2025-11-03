using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.Management.DataFactory;
using Microsoft.Azure.Management.DataFactory.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.Rest;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;

namespace ODSDataConnector.Core.Services
{
    public class ADFService : IADFService
    {
        private readonly IConfiguration Configuration;

        private readonly string subscriptionId;
        private readonly string clientId;
        private readonly string clientSecret;
        private readonly string tenantId;
        private readonly string strAzureAuthenticationKey;
        private readonly string azureManagementUri;
        private readonly string azureADUri;
        private readonly string batchAccountName;
        private readonly string batchAccountUri;
        private readonly string batchPoolName;
        private readonly string batchAccessKey;
        public ADFService(IConfiguration configuration)
        {
            this.Configuration = configuration;
            this.subscriptionId = configuration["ADFKeys:subscriptionId"];
            this.clientId = configuration["ADFKeys:clientId"];
            this.clientSecret = configuration["ADFKeys:clientSecret"];
            this.tenantId = configuration["ADFKeys:tenantId"];
            this.strAzureAuthenticationKey = configuration["ADFKeys:strAzureAuthenticationKey"];
            this.batchAccountName = configuration["AzureBatchAccountKeys:accountName"];
            this.batchAccountUri = configuration["AzureBatchAccountKeys:batchUri"];
            this.batchPoolName = configuration["AzureBatchAccountKeys:poolName"];
            this.batchAccessKey = configuration["AzureBatchAccountKeys:accessKey"];
            this.azureManagementUri = configuration["ADFKeys:azureManagementUri"];
            this.azureADUri = configuration["ADFKeys:azureADUri"];
        }

        public DataFactoryManagementClient GetADFClient()
        {
            AuthenticationContext objAuthenticationContext = new AuthenticationContext(azureADUri + tenantId);
            ClientCredential objClientCredential = new ClientCredential(clientId, strAzureAuthenticationKey);
            AuthenticationResult objAuthenticationResult = objAuthenticationContext.AcquireTokenAsync(azureManagementUri, objClientCredential).Result;
            ServiceClientCredentials objTokenCredentials = new TokenCredentials(objAuthenticationResult.AccessToken);
            var dataFactoryManagementClient = new DataFactoryManagementClient(objTokenCredentials)
            {
                SubscriptionId = subscriptionId
            };

            return dataFactoryManagementClient;
        }

        public DataFactoryManagementClient CreateLinkedService(Entities.LinkedService ls, DataFactoryManagementClient adfClient)
        {
            try
            {
                var sQLLS = adfClient.LinkedServices.Get(ls.ResourceGroupName, ls.DataFactoryName, ls.LinkedServiceName);
            }
            catch (Exception ex)
            {
                switch (ls.Type)
                {
                    case "SQL":
                        var linkedService = new LinkedServiceResource(
                                     new AzureSqlDatabaseLinkedService
                                     {
                                         ConnectionString = "Data Source=" + ls.Dbserver + ";Initial Catalog=" + ls.Dbname + ";User Id=" + ls.Username + ";Password=" + ls.Password
                                     }
                                    );
                        adfClient.LinkedServices.CreateOrUpdate(ls.ResourceGroupName, ls.DataFactoryName, ls.LinkedServiceName, linkedService);
                        break;

                    case "FTP":
                        var fileSystemLinkedService = new LinkedServiceResource(
                                new FileServerLinkedService
                                {
                                    ConnectVia = new IntegrationRuntimeReference(ls.Runtime),
                                    Host = ls.Host,
                                    UserId = ls.Username,
                                    Password = new SecureString(ls.Password)
                                }
                            );

                        // Create or update the File system Linked Service
                        adfClient.LinkedServices.CreateOrUpdate(ls.ResourceGroupName, ls.DataFactoryName, ls.LinkedServiceName, fileSystemLinkedService);
                        break;

                    case "STORAGE":
                        var azureBlobStorageLinkedService = new LinkedServiceResource(
                               new AzureBlobStorageLinkedService
                               {
                                   ConnectionString = new SecureString($"DefaultEndpointsProtocol=https;AccountName={ls.Username};AccountKey={ls.Password};EndpointSuffix=core.windows.net")
                               }
                           );

                        // Create or update the File system Linked Service
                        adfClient.LinkedServices.CreateOrUpdate(ls.ResourceGroupName, ls.DataFactoryName, ls.LinkedServiceName, azureBlobStorageLinkedService);
                        break;
                    case "Batch":
                        var azureBatchLinkedService = new LinkedServiceResource(
                             new AzureBatchLinkedService
                             {

                                 ConnectVia = new IntegrationRuntimeReference(ls.Runtime),
                                 AccountName = batchAccountName,
                                 BatchUri = batchAccountUri,
                                 PoolName = batchPoolName,
                                 AccessKey = new SecureString(batchAccessKey),
                                 LinkedServiceName = new LinkedServiceReference 
                                 { 
                                     ReferenceName = "CNXStorageBlobLinkedService"
                                 }
                             }
                            );
                        adfClient.LinkedServices.CreateOrUpdate(ls.ResourceGroupName, ls.DataFactoryName, ls.LinkedServiceName, azureBatchLinkedService);
                        break;
                }
                // Create or update the SQL Linked Service

                Console.WriteLine("SQL Linked Service created successfully.");
            }

            return adfClient;
        }
    }
}

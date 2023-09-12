using DWHPackages.Core.Entities;
using DWHPackages.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace DWHPackages.Core.Services
{
    public class ConnectorService : IConnectorService
    {
        private readonly ICustomerRepository CustomerRepository;
        private IConfiguration Configuration;

        public ConnectorService(IConfiguration configuration, ICustomerRepository customerRepository)
        {
            this.CustomerRepository = customerRepository;
            this.Configuration = configuration;
        }

        public async Task<bool> CreateDataForDWH(Request request)
        {
            if (request != null && !string.IsNullOrEmpty(request.customerName))
            {
                var cust = await this.CustomerRepository.GetCustomerByNameAsync(request.customerName);
                if (cust != null && request.modules.Count > 0)
                {
                    foreach (var module in request.modules)
                    {
                        var lstDataSources = await this.CustomerRepository.GetDataSourceListByModuleAsync(module);
                        if (lstDataSources.Any())
                        {
                            foreach (var dataSource in lstDataSources)
                            {
                                CreateHttpRequest(dataSource, cust.Id);
                            }
                        }
                    }
                }
            }

            return true;
        }

        private async Task<bool> CreateHttpRequest(DataSourceDto dataSource, int custId)
        {
            try
            {
                var requestJSON = new ConnectorRequest
                {
                    customerId = custId,
                    dataSource = dataSource.Name,
                    module = dataSource.Module,
                    version = dataSource.Version,
                    entity = dataSource.Entity
                };

                var httpClient = new HttpClient()
                {
                    BaseAddress = new Uri(this.Configuration["ODSDataConnectorAPIUrl"])
                };

                var postData = new StringContent(JsonConvert.SerializeObject(requestJSON), Encoding.UTF8, "application/json");
                var addressResponse = httpClient.PostAsync($"{httpClient.BaseAddress}{dataSource.Apiname}", postData).GetAwaiter().GetResult();

                return true;
            }
            catch(Exception ex)
            {
                return false;
            }

        }
    }
}

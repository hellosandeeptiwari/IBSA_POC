using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ODSDataConnector.Core.Interfaces;
using ODSDataConnector.Core.Repository;
using ODSDataConnector.Core.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ODSDataConnector.API.Configuration
{
    public static class ConfigureCoreServices
    {

        public static IServiceCollection AddCoreServices(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddScoped<IStorageService, StorageService>();
            services.AddScoped<IDDDAdfService, DDDAdfService>();
            services.AddScoped<IPlantrakAdfService, PlantrakAdfService>();
            services.AddScoped <ICustomerRepository, CustomerRepository>();
            services.AddScoped<IADFService, ADFService>();

            return services;
        }
    }
}

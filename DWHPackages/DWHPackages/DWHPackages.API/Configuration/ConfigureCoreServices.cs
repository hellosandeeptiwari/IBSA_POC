using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using DWHPackages.Core.Interfaces;
using DWHPackages.Core.Repository;
using DWHPackages.Core.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DWHPackages.API.Configuration
{
    public static class ConfigureCoreServices
    {

        public static IServiceCollection AddCoreServices(this IServiceCollection services, IConfiguration configuration)
        {
            //services.AddScoped<IStorageService, StorageService>();
            //services.AddScoped<IDDDAdfService, DDDAdfService>();
            services.AddScoped<IConnectorService, ConnectorService>();
            services.AddScoped <ICustomerRepository, CustomerRepository>();
            return services;
        }
    }
}

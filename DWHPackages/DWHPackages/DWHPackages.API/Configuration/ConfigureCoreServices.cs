using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using DWHPackages.Core.Interfaces;
using DWHPackages.Core.Repository;
using DWHPackages.Core.Services;
using DWHPackages.Core.Logging;
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
            services.AddScoped<IConnectorService, ConnectorService>();
            services.AddScoped <ICustomerRepository, CustomerRepository>();
            services.AddScoped<IAppLogger, AppInsightsLogger>();
            return services;
        }
    }
}

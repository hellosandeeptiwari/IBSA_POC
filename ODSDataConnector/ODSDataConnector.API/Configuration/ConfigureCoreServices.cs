using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ODSDataConnector.Core.Interfaces;
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

            return services;
        }
    }
}

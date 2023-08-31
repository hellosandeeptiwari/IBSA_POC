using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.ApplicationInsights;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ODSDataConnector
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {

                    webBuilder.ConfigureLogging((hostingContext, configureLogging) =>
                    {
                        var configuration = hostingContext.Configuration.GetSection("ConnectionStrings:AppInsightsInstrumentationKey");
                        configureLogging.AddApplicationInsights(configuration.Value);

                        configureLogging.AddFilter<ApplicationInsightsLoggerProvider>(typeof(Program).FullName, LogLevel.Trace);
                        configureLogging.AddFilter<ApplicationInsightsLoggerProvider>(typeof(Startup).FullName, LogLevel.Trace);
                    });

                    webBuilder.UseStartup<Startup>();
                });
    }
}

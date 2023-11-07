using Microsoft.AspNetCore.Mvc;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using System.Threading.Tasks;
using System;

namespace ODSDataConnector.API.Controllers.Reporting
{
    [ApiController]
    [Route("[controller]")]
    public class ReportingController : ControllerBase
    {
        private readonly IStorageService StorageService;
        private readonly IAppLogger AppLogger;
        private readonly IVeevaPTReportingService VeevaPTReportingService;
        public ReportingController(IStorageService storageService, IAppLogger appLogger, IVeevaPTReportingService veevaPTReportingService)
        {
            this.StorageService = storageService;
            this.AppLogger = appLogger;
            this.VeevaPTReportingService = veevaPTReportingService;
        }

        [HttpPost("SetupReportingLayer")]
        public async Task<IActionResult> SetupReportingLayerAsync(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"SetupReportingLayerAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.VeevaPTReportingService.CreateReportingPipeline(request);
                this.AppLogger.LogInformation($"SetupReportingLayerAsync Method completed at {DateTime.UtcNow}");
                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}

using Microsoft.AspNetCore.Mvc;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using System;
using System.Threading.Tasks;

namespace ODSDataConnector.API.Controllers.SalesOpsTools
{
    [ApiController]
    [Route("[controller]")]
    public class SalesOpsToolController : ControllerBase
    {
        private readonly IStorageService StorageService;
        private readonly IAppLogger AppLogger;

        public SalesOpsToolController(IStorageService storageService, IAppLogger appLogger)
        {
            this.StorageService = storageService;
            this.AppLogger = appLogger;
        }

        [HttpPost("SetupSalesOpsTools")]
        public async Task<IActionResult> SetupSalesOpsToolsAsync(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"SetupSalesOpsToolsAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                this.AppLogger.LogInformation($"SetupSalesOpsToolsAsync Method completed at {DateTime.UtcNow}");
                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}

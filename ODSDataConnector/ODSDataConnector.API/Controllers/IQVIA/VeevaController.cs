using Microsoft.AspNetCore.Mvc;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using System.Threading.Tasks;
using System;

namespace ODSDataConnector.API.Controllers.IQVIA
{
    [ApiController]
    [Route("[controller]")]
    public class VeevaController : ControllerBase
    {
        private readonly IStorageService StorageService;
        private readonly IAppLogger AppLogger;
        private readonly IVeevaService VeevaService;

        public VeevaController(IAppLogger appLogger, IVeevaService veevaService, IStorageService storageService)
        {
            this.AppLogger = appLogger;
            this.VeevaService = veevaService;
            this.StorageService = storageService;
        }

        [HttpPost("SetupVeevaData")]
        public async Task<IActionResult> SetupVeevaDataAsync(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"SetupVeevaDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.VeevaService.CreateVeevaObjectsAndPipeline(request);
                this.AppLogger.LogInformation($"SetupVeevaDataAsync Method completed at {DateTime.UtcNow}");
                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}

using Microsoft.AspNetCore.Mvc;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using System.Threading.Tasks;
using System;

namespace ODSDataConnector.API.Controllers.MDM
{
    [ApiController]
    [Route("[controller]")]
    public class MDMController : ControllerBase
    {
        private readonly IStorageService StorageService;
        private readonly IAppLogger AppLogger;
        private readonly IMDMService MDMService;

        public MDMController(IStorageService storageService, IAppLogger appLogger, IMDMService mDMService)
        {
            this.StorageService = storageService;
            this.AppLogger = appLogger;
            this.MDMService = mDMService;
        }
        [HttpPost("SetupMDM")]
        public async Task<IActionResult> SetupMDMAsync(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"SetupMDMAsync Method Started at {DateTime.UtcNow}");  //test 
                //this.AppLogger.LogInformation($"SetupMDMAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.MDMService.CreateMDMPipeline(request);
                this.AppLogger.LogInformation($"SetupMDMAsync Method completed at {DateTime.UtcNow}");
                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}

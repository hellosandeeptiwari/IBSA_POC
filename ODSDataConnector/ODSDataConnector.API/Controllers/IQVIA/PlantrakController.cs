using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ODSDataConnector.Core.Interfaces;
using ODSDataConnector.Core.Entities;

namespace ODSDataConnector.Controllers.IQVIA
{
    [ApiController]
    [Route("[controller]")]
    public class PlantrakController : ControllerBase
    {
        private readonly IStorageService StorageService;
        private readonly IPlantrakAdfService PlantrakAdfService;
        private readonly IAppLogger AppLogger;
        public PlantrakController(IStorageService storageService, IPlantrakAdfService plantrakAdfService, IAppLogger appLogger)
        {
            this.StorageService = storageService;
            this.PlantrakAdfService = plantrakAdfService;
            this.AppLogger = appLogger;
        }

        [HttpPost("SetupPrescriberSalesData")]
        public async Task<IActionResult> SetupPrescriberSalesDataAsync(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"SetupPrescriberSalesDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreatePrescriberSalesPipeline(request);
                this.AppLogger.LogInformation($"SetupPrescriberSalesDataAsync Method completed at {DateTime.UtcNow}");
                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupControlData")]
        public async Task<IActionResult> SetupControlDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateControlDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupPBMPlansData")]
        public async Task<IActionResult> SetupPBMPlansDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreatePBMPlansDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupPayerPlansData")]
        public async Task<IActionResult> SetupPayerPlansDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreatePayerPlansDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupModelData")]
        public async Task<IActionResult> SetupModelDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateModelDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupMarketDefinitionData")]
        public async Task<IActionResult> SetupMarketDefinitionDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateMarketDefinitionDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupPDRPData")]
        public async Task<IActionResult> SetupPDRPDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreatePDRPDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupNoContactData")]
        public async Task<IActionResult> SetupNoContactDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateNoContactDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupIQVIACalenderData")]
        public async Task<IActionResult> SetupIQVIACalenderDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateIQVIACalenderDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupIQVIAProductMarketData")]
        public async Task<IActionResult> SetupIQVIAProductMarketDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateIQVIAProductMarketDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupIQVIASpecialtyData")]
        public async Task<IActionResult> SetupIQVIASpecialtyDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateIQVIASpecialtyDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        [HttpPost("SetupZipToTerrData")]
        public async Task<IActionResult> SetupZipToTerrDataAsync(DataRequest request)
        {
            try
            {
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateZipToTerrDataPipeline(request);

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

    }
}

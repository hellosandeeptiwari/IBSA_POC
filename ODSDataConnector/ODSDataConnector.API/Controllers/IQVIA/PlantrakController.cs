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

        //[HttpPost("SetupControlData")]
        //public async Task<IActionResult> SetupControlDataAsync(DataRequest request)
        //{
        //    try
        //    {
        //        this.AppLogger.LogInformation($"SetupControlDataAsync Method Started at {DateTime.UtcNow}");
        //        var res = await this.StorageService.ExcecuteSQLScripts(request);
        //        var result = await this.PlantrakAdfService.CreateControlDataPipeline(request);
        //        this.AppLogger.LogInformation($"SetupControlDataAsync Method completed at {DateTime.UtcNow}");

        //        return this.Ok();
        //    }
        //    catch (Exception ex)
        //    {
        //        throw new Exception(ex.Message);
        //    }
        //}

        [HttpPost("SetupPBMPlansData")]
        public async Task<IActionResult> SetupPBMPlansDataAsync(DataRequest request)
        {
            try
            {
                this.AppLogger.LogInformation($"SetupPBMPlansDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreatePBMPlansDataPipeline(request);
                this.AppLogger.LogInformation($"SetupPBMPlansDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupPayerPlansDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreatePayerPlansDataPipeline(request);
                this.AppLogger.LogInformation($"SetupPayerPlansDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupModelDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateModelDataPipeline(request);
                this.AppLogger.LogInformation($"SetupModelDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupMarketDefinitionDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateMarketDefinitionDataPipeline(request);
                this.AppLogger.LogInformation($"SetupMarketDefinitionDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupPDRPDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreatePDRPDataPipeline(request);
                this.AppLogger.LogInformation($"SetupPDRPDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupNoContactDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateNoContactDataPipeline(request);
                this.AppLogger.LogInformation($"SetupNoContactDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupIQVIACalenderDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateIQVIACalenderDataPipeline(request);
                this.AppLogger.LogInformation($"SetupIQVIACalenderDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupIQVIAProductMarketDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateIQVIAProductMarketDataPipeline(request);
                this.AppLogger.LogInformation($"SetupIQVIAProductMarketDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupIQVIASpecialtyDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateIQVIASpecialtyDataPipeline(request);
                this.AppLogger.LogInformation($"SetupIQVIASpecialtyDataAsync Method completed at {DateTime.UtcNow}");

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
                this.AppLogger.LogInformation($"SetupZipToTerrDataAsync Method Started at {DateTime.UtcNow}");
                var res = await this.StorageService.ExcecuteSQLScripts(request);
                var result = await this.PlantrakAdfService.CreateZipToTerrDataPipeline(request);
                this.AppLogger.LogInformation($"SetupZipToTerrDataAsync Method completed at {DateTime.UtcNow}");

                return this.Ok();
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

    }
}

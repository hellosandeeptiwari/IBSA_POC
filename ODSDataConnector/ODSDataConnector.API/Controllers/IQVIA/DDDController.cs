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
    public class DDDController : ControllerBase
    {
        private readonly IStorageService storageService;
        private readonly IDDDAdfService DDDAdfService;
        public DDDController(IStorageService StorageService, IDDDAdfService dDDAdfService)
        {
            this.storageService = StorageService;
            this.DDDAdfService = dDDAdfService;
        }


        [HttpPost("SetupDemographicData")]
        public async Task<IActionResult> SetupDemographicDataAsync(DataRequest request)
        {
            var res = this.storageService.ExcecuteSQLScripts(request);
            var result = this.DDDAdfService.CreateDemographicPipeline(request);
           
            return this.Ok();
        }

    }
}

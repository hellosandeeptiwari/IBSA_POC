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
        private readonly IStorageService StorageService;
        public DDDController(IStorageService storageService)
        {
            this.StorageService = storageService;
        }


        [HttpPost("SetupDemographicData")]
        public async Task<IActionResult> SetupDemographicDataAsync(DataRequest request)
        {
            var res = this.StorageService.ExcecuteSQLScripts(request);
            //1. Based on the data source execute SQL scripts
                     //- keep the scripts in storage, path in DB 
            //2. Connect to ADF, create pipeline, create linked service
            return this.Ok();
        }

    }
}

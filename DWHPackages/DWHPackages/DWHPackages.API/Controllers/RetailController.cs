using DWHPackages.Core.Entities;
using DWHPackages.Core.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DWHPackages.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class RetailController : ControllerBase
    {
        private readonly IConnectorService connectorService;
       
        public RetailController(IConnectorService ConnectorService)
        {
            this.connectorService = ConnectorService;
        }


        [HttpPost("SetupRetailDWH")]
        public async Task<IActionResult> SetupRetailDWHAsync(Request request)
        {
            //var res = await this.StorageService.ExcecuteSQLScripts(request);
            //var result = await this.PlantrakAdfService.CreatePrescriberSalesPipeline(request);
            var res = this.connectorService.CreateDataForDWH(request);
           
            return this.Ok();
        }
    }
}

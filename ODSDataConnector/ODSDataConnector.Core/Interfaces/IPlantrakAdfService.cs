using ODSDataConnector.Core.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Interfaces
{
    public interface IPlantrakAdfService
    {
        Task<bool> CreatePrescriberSalesPipeline(DataRequest request);

        Task<bool> CreateControlDataPipeline(DataRequest request);

        Task<bool> CreatePBMPlansDataPipeline(DataRequest request);

        Task<bool> CreatePayerPlansDataPipeline(DataRequest request);

        Task<bool> CreateModelDataPipeline(DataRequest request);

        Task<bool> CreateMarketDefinitionDataPipeline(DataRequest request);

        Task<bool> CreatePDRPDataPipeline(DataRequest request);

        Task<bool> CreateNoContactDataPipeline(DataRequest request);
    }
}

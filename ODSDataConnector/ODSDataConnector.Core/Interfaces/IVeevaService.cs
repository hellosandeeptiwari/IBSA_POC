using ODSDataConnector.Core.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Interfaces
{
    public interface IVeevaService
    {
        Task<bool> CreateVeevaObjectsAndPipeline(DataRequest request);
    }
}

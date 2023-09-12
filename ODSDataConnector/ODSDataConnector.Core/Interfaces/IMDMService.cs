using ODSDataConnector.Core.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Interfaces
{
    public interface IMDMService
    {
        Task<bool> CreateMDMPipeline(DataRequest request);
    }
}

using DWHPackages.Core.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DWHPackages.Core.Interfaces
{
    public interface IConnectorService
    {
        Task<bool> CreateDataForDWH(Request request);
    }
}

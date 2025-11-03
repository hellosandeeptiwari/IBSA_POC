using Microsoft.Azure.Management.DataFactory;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Interfaces
{
    public interface IADFService
    {
        DataFactoryManagementClient GetADFClient();
        DataFactoryManagementClient CreateLinkedService(Entities.LinkedService ls, DataFactoryManagementClient adfClient);
    }
}

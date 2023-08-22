using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Interfaces
{
    public interface ICustomerRepository
    {
        Task<Customer> GetCustomerByIdAsync(int CustomerId);

        Task<DataSource> GetDataSourceByIdAsync(DataRequest request);
    }
}

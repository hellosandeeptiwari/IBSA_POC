using DWHPackages.Core.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DWHPackages.Core.Interfaces
{
    public interface ICustomerRepository
    {
        Task<CustomerDto> GetCustomerByNameAsync(string CustomerName);

        Task<List<DataSourceDto>> GetDataSourceListByModuleAsync(string dataSource);

        //Task<DataSource> GetDataSourceByIdAsync(DataRequest request);
    }
}

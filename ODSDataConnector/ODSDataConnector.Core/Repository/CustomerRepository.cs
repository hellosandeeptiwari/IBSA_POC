using Azure.Core;
using Microsoft.EntityFrameworkCore;
using ODSDataConnector.Core.Entities;
using ODSDataConnector.Core.Interfaces;
using ODSDataConnector.Core.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Repository
{
    public class CustomerRepository : ICustomerRepository
    {
        private readonly AppDBContext context;

        public CustomerRepository(AppDBContext appDbContext)
        {
            this.context = appDbContext;
        }

        public async Task<Customer> GetCustomerByIdAsync(int CustomerId)
        {
            return await this.context.Customers.Where(x => x.Id == CustomerId).FirstOrDefaultAsync();
        }

        public async Task<DataSource> GetDataSourceByIdAsync(DataRequest request)
        {
            return await this.context.DataSources.Where(x => x.Name == request.dataSource && x.Module == request.module && x.Entity == request.entity && x.Version == request.version).FirstOrDefaultAsync();
        }

        public async Task<CustomerConfiguration> GetDataSourceConfigAsync(DataRequest request)
        {
            return await (from cc in this.context.CustomerConfigurations 
                                join ds in this.context.DataSources on cc.DatasourceId equals ds.Id
                                where cc.CustomerId == request.customerId && ds.Module == request.module && ds.Entity == request.entity && ds.Version == request.version
                                select cc).FirstOrDefaultAsync();
        }
    }
}

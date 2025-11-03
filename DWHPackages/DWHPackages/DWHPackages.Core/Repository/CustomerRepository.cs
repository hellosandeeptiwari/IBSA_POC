using Azure.Core;
using DWHPackages.Core.Entities;
using Microsoft.EntityFrameworkCore;
using DWHPackages.Core.Entities;
using DWHPackages.Core.Interfaces;
using DWHPackages.Core.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DWHPackages.Core.Repository
{
    public class CustomerRepository : ICustomerRepository
    {
        private readonly AppDBContext context;

        public CustomerRepository(AppDBContext appDbContext)
        {
            this.context = appDbContext;
        }

        public async Task<CustomerDto> GetCustomerByNameAsync(string CustomerName)
        {
            try
            {
                var customer = this.context.Customers.Where(x => x.Id == 1).FirstOrDefault();

                if (customer != null)
                {
                    return new CustomerDto
                    {
                        Id = customer.Id,
                        Name = customer.Name
                    };
                }
                else
                {
                    return new CustomerDto();
                }
            }
            catch (Exception ex)
            {
                return new CustomerDto();
            }
        }

        public async Task<List<DataSourceDto>> GetDataSourceListByModuleAsync(string module)
        {
            var lstDataSource = this.context.DataSources.Where(x => x.Module == module).ToList();

            var result = new List<DataSourceDto>();
            if (lstDataSource.Any())
            {
                foreach (var item in lstDataSource)
                {
                    result.Add(new DataSourceDto
                    {
                        Id = item.Id,
                        Name = item.Name,
                        Module = item.Module,
                        Version = item.Version,
                        Entity = item.Entity,
                        StoragePath = item.StoragePath,
                        Apiname = item.Apiname
                    });
                }

                return result;
            }
            else
            { return new List<DataSourceDto>(); }
        }
    }
}

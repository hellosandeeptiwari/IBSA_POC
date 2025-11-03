using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DWHPackages.Core.Entities
{
    public class DataSourceDto
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public string Module { get; set; }

        public string Version { get; set; }

        public string Entity { get; set; }

        public string? StoragePath { get; set; }

        public string? Apiname { get; set; }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Entities
{
    public class DataRequest
    {
        public int customerId { get; set; }
        public string dataSource { get; set; }
        public string module { get; set; }
        public string entity { get; set; }
        public string version { get; set; }
    }
}

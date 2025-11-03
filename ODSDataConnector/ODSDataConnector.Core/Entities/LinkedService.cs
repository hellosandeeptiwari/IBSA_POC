using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Entities
{
    public class LinkedService
    {
        public string Type { get; set; }
        public string Dbserver { get; set; }
        public string Dbname { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
        public string LinkedServiceName { get; set; }
        public string ResourceGroupName { get; set; }
        public string DataFactoryName { get; set; }
        public string Runtime { get; set; }
        public string Host { get; set; }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODSDataConnector.Core.Entities
{
    public class TabularColumnMapping
    {
        public string SourceColumnName { get; set; }
        public string SinkColumnName { get; set; }
    }
}

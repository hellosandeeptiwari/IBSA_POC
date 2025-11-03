using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DWHPackages.Core.Entities
{
    public class Request
    {
        public List<string> modules { get; set; }

        public string customerName { get; set; }
    }
}

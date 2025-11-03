using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SFBulkAPIStarter
{
    public class BulkAPIResult
    {
        public string Id { get; set; }
        public bool Success { get; set; }
        public bool Created { get; set; }
        public string Error { get; set; }  
    }
}

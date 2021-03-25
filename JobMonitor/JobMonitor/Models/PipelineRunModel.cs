using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace JobMonitor.DatabaseModels
{
    public class PipelineRunModel
    {
        public Guid RunId { get; set; }
        public int PipelineId { get; set; }
        public DateTime? RunStart { get; set; }
        public DateTime? RunEnd { get; set; }
        public string RunStatus { get; set; }
        public DateTime? LastUpdated { get; set; }
        public int? DurationInMilliSeconds { get; set; }
        public string InvokedById { get; set; }
        public string InvokedByType { get; set; }
        public string InvokedByName { get; set; }
        public string ErrorMessage { get; set; }
        public Guid RunGroupId { get; set; }

    }
}

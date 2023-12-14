using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace JobMonitor.DatabaseModels
{
    public class PipelineModel
    {
        public int CustomerId { get; set; }
        public int PipelineId { get; set; }
        public string ResourceGroupName { get; set; }
        public string DataFactoryName { get; set; }
        public string PipelineName { get; set; }
        public string TriggerName { get; set; }
        public string TriggerStatus { get; set; }
        public string ScheduledFrequency { get; set; }
        public string ScheduledTime { get; set; }
        public string ScheduledTimeZone { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string PipelineDescription { get; set; }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace JobMonitor.Models
{
    // 
    public class Schedule
    {
        public List<int> monthDays { get; set; }
        public List<string> weekDays { get; set; }
        public List<int> hours { get; set; }
        public List<int> minutes { get; set; }
    }

    public class Recurrence
    {
        public string frequency { get; set; }
        public int interval { get; set; }
        public DateTime startTime { get; set; }
        public DateTime endTime { get; set; }
        public string timeZone { get; set; }
        public Schedule schedule { get; set; }
    }

    public class TriggerModel
    {
        public Recurrence recurrence { get; set; }
    }
}

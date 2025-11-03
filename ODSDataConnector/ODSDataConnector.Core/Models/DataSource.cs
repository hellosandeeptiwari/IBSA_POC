using System;
using System.Collections.Generic;

namespace ODSDataConnector.Core.Models;

public partial class DataSource
{
    public int Id { get; set; }

    public string Name { get; set; }

    public string Module { get; set; }

    public string Version { get; set; }

    public string Entity { get; set; }

    public string StoragePath { get; set; }

    public string Apiname { get; set; }
}

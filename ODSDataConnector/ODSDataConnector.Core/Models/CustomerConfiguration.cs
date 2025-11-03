using System;
using System.Collections.Generic;

namespace ODSDataConnector.Core.Models;

public partial class CustomerConfiguration
{
    public int Id { get; set; }

    public int CustomerId { get; set; }

    public int DatasourceId { get; set; }

    public string SourceType { get; set; }

    public string Server { get; set; }

    public string Host { get; set; }

    public string Username { get; set; }

    public string Password { get; set; }

    public string Url { get; set; }

    public string DestTable { get; set; }

    public bool IsLoaded { get; set; }

    public string LinkedService { get; set; }

    public string SrcFileName { get; set; }

    public string SheetName { get; set; }
}

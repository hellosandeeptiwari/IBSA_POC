using System;
using System.Collections.Generic;

namespace ODSDataConnector.Core.Models;

public partial class Customer
{
    public int Id { get; set; }

    public string Name { get; set; }

    public string Dbserver { get; set; }

    public string Dbname { get; set; }

    public string Username { get; set; }

    public string Password { get; set; }

    public string LinkedService { get; set; }

    public string Adfname { get; set; }

    public string ResourceGroup { get; set; }

    public bool IsMdm { get; set; }
}

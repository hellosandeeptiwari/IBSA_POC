using System;
using System.Collections.Generic;

namespace DWHPackages.Core.Models;

public partial class Customer
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string Dbserver { get; set; } = null!;

    public string Dbname { get; set; } = null!;

    public string Username { get; set; } = null!;

    public string Password { get; set; } = null!;

    public string? LinkedService { get; set; }

    public string? Adfname { get; set; }
}

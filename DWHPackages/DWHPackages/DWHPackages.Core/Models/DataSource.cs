using System;
using System.Collections.Generic;

namespace DWHPackages.Core.Models;

public partial class DataSource
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string Module { get; set; } = null!;

    public string Version { get; set; } = null!;

    public string Entity { get; set; } = null!;

    public string? StoragePath { get; set; }

    public string? Apiname { get; set; }
}

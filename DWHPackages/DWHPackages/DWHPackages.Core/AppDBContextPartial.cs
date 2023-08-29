using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace DWHPackages.Core.Models;

public partial class AppDBContext : DbContext
{
    private readonly IConfiguration configuration;

    public AppDBContext(DbContextOptions<AppDBContext> options, IConfiguration configuration)
        : base(options)
    {
        //Database.SetCommandTimeout(TimeSpan.FromSeconds(Convert.ToInt32(configuration["SqlTimeoutInSeconds"])));
        //this.configuration = configuration;
    }    

    //protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    //    => optionsBuilder.UseSqlServer(this.configuration["ConnectionStrings:ODSAzureSQL"]);
}

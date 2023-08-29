using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace DWHPackages.Core.Models;

public partial class AppDBContext : DbContext
{
    public AppDBContext()
    {
    }

    public AppDBContext(DbContextOptions<AppDBContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Customer> Customers { get; set; }

    public virtual DbSet<CustomerConfiguration> CustomerConfigurations { get; set; }

    public virtual DbSet<DataSource> DataSources { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see http://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Data Source=odsdevserver.database.windows.net,1433;Initial Catalog=ODSAutomationDev;User Id=ODSDevAutomationSQLUser ;Password=UHrt235Fg!tf127FG@; MultipleActiveResultSets=true;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("Customer");

            entity.Property(e => e.Adfname)
                .HasMaxLength(30)
                .HasColumnName("ADFName");
            entity.Property(e => e.Dbname)
                .HasMaxLength(100)
                .HasColumnName("DBName");
            entity.Property(e => e.Dbserver)
                .HasMaxLength(100)
                .HasColumnName("DBServer");
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.LinkedService).HasMaxLength(100);
            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(e => e.Password).HasMaxLength(100);
            entity.Property(e => e.Username).HasMaxLength(100);
        });

        modelBuilder.Entity<CustomerConfiguration>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("CustomerConfiguration");

            entity.Property(e => e.DestTable).HasMaxLength(100);
            entity.Property(e => e.Host).HasMaxLength(100);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.LinkedService).HasMaxLength(100);
            entity.Property(e => e.Password).HasMaxLength(100);
            entity.Property(e => e.Server).HasMaxLength(100);
            entity.Property(e => e.SourceType).HasMaxLength(100);
            entity.Property(e => e.Url)
                .HasMaxLength(500)
                .HasColumnName("URL");
            entity.Property(e => e.Username).HasMaxLength(100);
        });

        modelBuilder.Entity<DataSource>(entity =>
        {
            entity
                .HasNoKey()
                .ToTable("DataSource");

            entity.Property(e => e.Apiname)
                .HasMaxLength(100)
                .HasColumnName("APIName");
            entity.Property(e => e.Entity).HasMaxLength(100);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.Module).HasMaxLength(100);
            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(e => e.StoragePath).HasMaxLength(100);
            entity.Property(e => e.Version).HasMaxLength(10);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}

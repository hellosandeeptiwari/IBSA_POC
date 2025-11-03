using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace ODSDataConnector.Core.Models;

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
                .IsRequired()
                .HasMaxLength(100)
                .HasColumnName("DBName");
            entity.Property(e => e.Dbserver)
                .IsRequired()
                .HasMaxLength(100)
                .HasColumnName("DBServer");
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.IsMdm).HasColumnName("IsMDM");
            entity.Property(e => e.LinkedService).HasMaxLength(100);
            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(100);
            entity.Property(e => e.Password)
                .IsRequired()
                .HasMaxLength(100);
            entity.Property(e => e.ResourceGroup).HasMaxLength(50);
            entity.Property(e => e.Username)
                .IsRequired()
                .HasMaxLength(100);
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
            entity.Property(e => e.SheetName).HasMaxLength(50);
            entity.Property(e => e.SourceType)
                .IsRequired()
                .HasMaxLength(100);
            entity.Property(e => e.SrcFileName).HasMaxLength(200);
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
            entity.Property(e => e.Entity)
                .IsRequired()
                .HasMaxLength(100);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.Module)
                .IsRequired()
                .HasMaxLength(100);
            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(100);
            entity.Property(e => e.StoragePath).HasMaxLength(100);
            entity.Property(e => e.Version)
                .IsRequired()
                .HasMaxLength(10);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}

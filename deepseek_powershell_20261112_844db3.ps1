# ============================================================
# Setup-HardwareERP.ps1
# Crea, compila y publica HardwareERP (WPF + SQLite + EF Core)
# ============================================================
param(
    [string]$Root = "$env:USERPROFILE\source\repos\HardwareERP",
    [switch]$SkipRun
)

$ErrorActionPreference = "Stop"
Write-Host "`n=== HardwareERP Setup ===" -ForegroundColor Cyan

# --- 1. Verificar / instalar .NET 8 SDK ---
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
$hasSdk8 = $false
if ($dotnet) {
    $sdks = & dotnet --list-sdks 2>$null
    $hasSdk8 = $sdks -match '^8\.'
}
if (-not $hasSdk8) {
    Write-Host "Falta el .NET 8 SDK. Intentando instalar con winget..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Microsoft.DotNet.SDK.8 -e --accept-source-agreements --accept-package-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } else {
        Write-Host "No tenés winget. Instalá manualmente el .NET 8 SDK desde:" -ForegroundColor Red
        Write-Host "https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Red
        exit 1
    }
}

# --- 2. Estructura de carpetas ---
Write-Host "Creando estructura en: $Root" -ForegroundColor Cyan
$dirs = @("", "Models", "Data", "ViewModels", "Views", "Themes")
foreach ($d in $dirs) {
    $full = if ($d) { Join-Path $Root $d } else { $Root }
    New-Item -ItemType Directory -Force -Path $full | Out-Null
}

function Write-File($relPath, $content) {
    $full = Join-Path $Root $relPath
    [System.IO.File]::WriteAllText($full, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  + $relPath" -ForegroundColor DarkGray
}

# --- 3. Archivos del proyecto ---

Write-File "HardwareERP.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <Nullable>enable</Nullable>
    <UseWPF>true</UseWPF>
    <AssemblyName>HardwareERP</AssemblyName>
    <RootNamespace>HardwareERP</RootNamespace>
    <ApplicationIcon />
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="8.0.10" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.10">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
  </ItemGroup>
</Project>
'@

Write-File "App.xaml" @'
<Application x:Class="HardwareERP.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Application.Resources>
        <ResourceDictionary>
            <ResourceDictionary.MergedDictionaries>
                <ResourceDictionary Source="Themes/DarkTheme.xaml"/>
            </ResourceDictionary.MergedDictionaries>
        </ResourceDictionary>
    </Application.Resources>
</Application>
'@

Write-File "App.xaml.cs" @'
using System.Windows;

namespace HardwareERP;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        Data.AppDbContext.Initialize();
        var win = new MainWindow();
        win.Show();
    }
}
'@

Write-File "Themes\DarkTheme.xaml" @'
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <SolidColorBrush x:Key="BgDarkBrush" Color="#0F1115"/>
    <SolidColorBrush x:Key="BgPanelBrush" Color="#161A22"/>
    <SolidColorBrush x:Key="BgCardBrush" Color="#1C2230"/>
    <SolidColorBrush x:Key="AccentBrush" Color="#4F8CFF"/>
    <SolidColorBrush x:Key="SuccessBrush" Color="#34D399"/>
    <SolidColorBrush x:Key="DangerBrush" Color="#EF4444"/>
    <SolidColorBrush x:Key="WarnBrush" Color="#F59E0B"/>
    <SolidColorBrush x:Key="TextPrimaryBrush" Color="#E6E9EF"/>
    <SolidColorBrush x:Key="TextSecondaryBrush" Color="#8A93A6"/>
    <SolidColorBrush x:Key="BorderBrush" Color="#2A3242"/>

    <Style TargetType="Window">
        <Setter Property="Background" Value="{StaticResource BgDarkBrush}"/>
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        <Setter Property="FontFamily" Value="Segoe UI"/>
    </Style>
    <Style TargetType="TextBlock">
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
    </Style>
    <Style TargetType="Label">
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
    </Style>
    <Style TargetType="TextBox">
        <Setter Property="Background" Value="{StaticResource BgCardBrush}"/>
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
        <Setter Property="Padding" Value="8,6"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="CaretBrush" Value="White"/>
        <Setter Property="Margin" Value="0,4,0,10"/>
    </Style>
    <Style TargetType="ComboBox">
        <Setter Property="Background" Value="{StaticResource BgCardBrush}"/>
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
        <Setter Property="Padding" Value="6,4"/>
        <Setter Property="Margin" Value="0,4,0,10"/>
    </Style>
    <Style TargetType="Button">
        <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
        <Setter Property="Foreground" Value="White"/>
        <Setter Property="Padding" Value="14,8"/>
        <Setter Property="BorderThickness" Value="0"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="Margin" Value="0,0,8,0"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Border Background="{TemplateBinding Background}" CornerRadius="6"
                            Padding="{TemplateBinding Padding}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
        <Style.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Opacity" Value="0.85"/>
            </Trigger>
        </Style.Triggers>
    </Style>
    <Style x:Key="GhostButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
        <Setter Property="Background" Value="{StaticResource BgCardBrush}"/>
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
    </Style>
    <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
        <Setter Property="Background" Value="{StaticResource DangerBrush}"/>
    </Style>
    <Style TargetType="DataGrid">
        <Setter Property="Background" Value="{StaticResource BgPanelBrush}"/>
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="GridLinesVisibility" Value="Horizontal"/>
        <Setter Property="HorizontalGridLinesBrush" Value="{StaticResource BorderBrush}"/>
        <Setter Property="AutoGenerateColumns" Value="False"/>
        <Setter Property="IsReadOnly" Value="True"/>
        <Setter Property="SelectionMode" Value="Single"/>
        <Setter Property="CanUserAddRows" Value="False"/>
        <Setter Property="RowHeight" Value="34"/>
        <Setter Property="HeadersVisibility" Value="Column"/>
    </Style>
    <Style TargetType="DataGridRow">
        <Setter Property="Background" Value="{StaticResource BgPanelBrush}"/>
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        <Style.Triggers>
            <Trigger Property="IsSelected" Value="True">
                <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            </Trigger>
        </Style.Triggers>
    </Style>
    <Style TargetType="DataGridColumnHeader">
        <Setter Property="Background" Value="{StaticResource BgCardBrush}"/>
        <Setter Property="Foreground" Value="{StaticResource TextSecondaryBrush}"/>
        <Setter Property="Padding" Value="10,8"/>
        <Setter Property="FontWeight" Value="SemiBold"/>
        <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
        <Setter Property="BorderThickness" Value="0,0,0,1"/>
    </Style>
    <Style TargetType="DataGridCell">
        <Setter Property="BorderThickness" Value="0"/>
        <Setter Property="Padding" Value="10,6"/>
        <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        <Setter Property="Background" Value="Transparent"/>
    </Style>
</ResourceDictionary>
'@

Write-File "Models\Entities.cs" @'
namespace HardwareERP.Models;

public enum ComponentCategory { CPU, GPU, RAM, Motherboard, PSU, Storage, Case, Cooling, Peripheral, FullPC, Combo, Other }
public enum ComponentStatus { Available, Reserved, Published, Sold, InRepair, PendingTest, Defective }
public enum ComponentCondition { New, LikeNew, Excellent, Good, Fair, Poor, Faulty }

public class Component
{
    public int Id { get; set; }
    public string Sku { get; set; } = "";
    public ComponentCategory Category { get; set; }
    public string Brand { get; set; } = "";
    public string Model { get; set; } = "";
    public string? Specifications { get; set; }
    public string? SerialNumber { get; set; }
    public DateTime IngestDate { get; set; } = DateTime.Now;
    public ComponentStatus Status { get; set; } = ComponentStatus.PendingTest;
    public ComponentCondition Condition { get; set; } = ComponentCondition.Good;
    public decimal PurchasePrice { get; set; }
    public decimal AdditionalCosts { get; set; }
    public decimal? SalePrice { get; set; }
    public decimal? SoldPrice { get; set; }
    public DateTime? SoldDate { get; set; }
    public int? PartnerId { get; set; }
    public Partner? Partner { get; set; }
    public string? StorageLocation { get; set; }
    public string? Observations { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime UpdatedAt { get; set; } = DateTime.Now;

    public ICollection<PurchaseItem> PurchaseItems { get; set; } = new List<PurchaseItem>();
    public ICollection<Sale> Sales { get; set; } = new List<Sale>();
    public ICollection<Diagnosis> Diagnoses { get; set; } = new List<Diagnosis>();

    public decimal TotalCost => PurchasePrice + AdditionalCosts;
}

public class Partner
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public decimal CapitalContributed { get; set; }
    public decimal OwnershipPercent { get; set; }
    public decimal WithdrawnAmount { get; set; }
    public bool IsActive { get; set; } = true;
}

public class Purchase
{
    public int Id { get; set; }
    public DateTime Date { get; set; } = DateTime.Now;
    public string? Seller { get; set; }
    public int? PartnerId { get; set; }
    public Partner? Partner { get; set; }
    public string? PaymentMethod { get; set; }
    public decimal ShippingCost { get; set; }
    public decimal OtherCosts { get; set; }
    public string? Notes { get; set; }

    public ICollection<PurchaseItem> Items { get; set; } = new List<PurchaseItem>();

    public decimal TotalCost => Items.Sum(i => i.UnitPrice) + ShippingCost + OtherCosts;
}

public class PurchaseItem
{
    public int Id { get; set; }
    public int PurchaseId { get; set; }
    public Purchase? Purchase { get; set; }
    public int ComponentId { get; set; }
    public Component? Component { get; set; }
    public decimal UnitPrice { get; set; }
}

public class Sale
{
    public int Id { get; set; }
    public DateTime Date { get; set; } = DateTime.Now;
    public int ComponentId { get; set; }
    public Component? Component { get; set; }
    public string? BuyerName { get; set; }
    public string? BuyerPhone { get; set; }
    public decimal SalePrice { get; set; }
    public string? Platform { get; set; }
    public string? PaymentMethod { get; set; }
    public decimal ShippingCost { get; set; }
    public decimal Commission { get; set; }
    public DateTime? WarrantyUntil { get; set; }
    public string? Notes { get; set; }
    public bool IsVoided { get; set; }
    public string? VoidReason { get; set; }
}

public class Diagnosis
{
    public int Id { get; set; }
    public int ComponentId { get; set; }
    public Component? Component { get; set; }
    public DateTime Date { get; set; } = DateTime.Now;
    public string? Technician { get; set; }
    public string? Tests { get; set; }
    public string? Results { get; set; }
    public string? Faults { get; set; }
    public string? RepairsDone { get; set; }
    public decimal RepairCost { get; set; }
    public bool Passed { get; set; }
    public string? Notes { get; set; }
}
'@

Write-File "Data\AppDbContext.cs" @'
using System.IO;
using HardwareERP.Models;
using Microsoft.EntityFrameworkCore;

namespace HardwareERP.Data;

public class AppDbContext : DbContext
{
    public DbSet<Component> Components => Set<Component>();
    public DbSet<Partner> Partners => Set<Partner>();
    public DbSet<Purchase> Purchases => Set<Purchase>();
    public DbSet<PurchaseItem> PurchaseItems => Set<PurchaseItem>();
    public DbSet<Sale> Sales => Set<Sale>();
    public DbSet<Diagnosis> Diagnoses => Set<Diagnosis>();

    public static string DataFolder
    {
        get
        {
            var dir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "HardwareERP");
            Directory.CreateDirectory(dir);
            return dir;
        }
    }

    public static string DbPath => Path.Combine(DataFolder, "hardware.db");

    protected override void OnConfiguring(DbContextOptionsBuilder o)
        => o.UseSqlite($"Data Source={DbPath}");

    protected override void OnModelCreating(ModelBuilder mb)
    {
        mb.Entity<Component>().HasIndex(c => c.Sku).IsUnique();

        mb.Entity<Partner>().HasData(
            new Partner { Id = 1, Name = "Socio 1", OwnershipPercent = 50, IsActive = true },
            new Partner { Id = 2, Name = "Socio 2", OwnershipPercent = 50, IsActive = true }
        );
    }

    public static void Initialize()
    {
        using (var db = new AppDbContext())
        {
            db.Database.EnsureCreated();
        }

        var backupFolder = Path.Combine(DataFolder, "backups");
        Directory.CreateDirectory(backupFolder);
        var backupFile = Path.Combine(backupFolder, $"hardware_{DateTime.Now:yyyyMMdd}.db");
        if (File.Exists(DbPath) && !File.Exists(backupFile))
        {
            try { File.Copy(DbPath, backupFile); } catch { }
        }
        foreach (var f in Directory.GetFiles(backupFolder, "hardware_*.db"))
        {
            try { if (File.GetCreationTime(f) < DateTime.Now.AddDays(-7)) File.Delete(f); }
            catch { }
        }
    }
}
'@

Write-File "ViewModels\ViewModelBase.cs" @'
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace HardwareERP.ViewModels;

public abstract class ViewModelBase : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    protected bool SetProperty<T>(ref T field, T value, [CallerMemberName] string? name = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(name);
        return true;
    }
}
'@

Write-File "ViewModels\RelayCommand.cs" @'
using System.Windows.Input;

namespace HardwareERP.ViewModels;

public class RelayCommand : ICommand
{
    private readonly Action<object?> _execute;
    private readonly Predicate<object?>? _canExecute;

    public RelayCommand(Action<object?> execute, Predicate<object?>? canExecute = null)
    {
        _execute = execute;
        _canExecute = canExecute;
    }
    public RelayCommand(Action execute, Func<bool>? canExecute = null)
        : this(_ => execute(), canExecute == null ? null : _ => canExecute()) { }

    public bool CanExecute(object? p) => _canExecute?.Invoke(p) ?? true;
    public void Execute(object? p) => _execute(p);
    public event EventHandler? CanExecuteChanged
    {
        add => CommandManager.RequerySuggested += value;
        remove => CommandManager.RequerySuggested -= value;
    }
}
'@

Write-File "ViewModels\MainViewModel.cs" @'
namespace HardwareERP.ViewModels;

public class MainViewModel : ViewModelBase
{
    private ViewModelBase? _currentViewModel;
    public ViewModelBase? CurrentViewModel { get => _currentViewModel; set => SetProperty(ref _currentViewModel, value); }

    public RelayCommand ShowDashboardCommand { get; }
    public RelayCommand ShowInventoryCommand { get; }
    public RelayCommand ShowPurchasesCommand { get; }
    public RelayCommand ShowSalesCommand { get; }

    public MainViewModel()
    {
        ShowDashboardCommand = new RelayCommand(_ => CurrentViewModel = new DashboardViewModel());
        ShowInventoryCommand = new RelayCommand(_ => CurrentViewModel = new InventoryViewModel());
        ShowPurchasesCommand = new RelayCommand(_ => CurrentViewModel = new PurchasesViewModel());
        ShowSalesCommand = new RelayCommand(_ => CurrentViewModel = new SalesViewModel());
        CurrentViewModel = new DashboardViewModel();
    }
}
'@

Write-File "ViewModels\DashboardViewModel.cs" @'
using HardwareERP.Data;
using HardwareERP.Models;
using Microsoft.EntityFrameworkCore;

namespace HardwareERP.ViewModels;

public class DashboardViewModel : ViewModelBase
{
    public decimal CapitalInvertido { get; private set; }
    public decimal ValorInventario { get; private set; }
    public decimal GananciaNeta { get; private set; }
    public decimal VentasMes { get; private set; }
    public decimal ComprasMes { get; private set; }
    public int Disponibles { get; private set; }
    public int Vendidos { get; private set; }
    public int PendientesTest { get; private set; }
    public int EnReparacion { get; private set; }
    public int Defectuosos { get; private set; }
    public string MesLabel { get; private set; } = "";

    public RelayCommand RefreshCommand { get; }

    public DashboardViewModel()
    {
        RefreshCommand = new RelayCommand(_ => Load());
        Load();
    }

    private void Load()
    {
        using var db = new AppDbContext();
        var startMonth = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
        MesLabel = DateTime.Now.ToString("MMMM yyyy");

        var all = db.Components.Where(c => c.IsActive).ToList();
        CapitalInvertido = all.Where(c => c.Status != ComponentStatus.Sold)
                              .Sum(c => c.PurchasePrice + c.AdditionalCosts);
        ValorInventario = all.Where(c => c.Status != ComponentStatus.Sold)
                             .Sum(c => c.SalePrice ?? 0);

        var sold = db.Components
                     .Where(c => c.Status == ComponentStatus.Sold && c.SoldPrice != null)
                     .ToList();
        GananciaNeta = sold.Sum(c => (c.SoldPrice ?? 0) - c.PurchasePrice - c.AdditionalCosts);

        VentasMes = db.Sales.Where(s => !s.IsVoided && s.Date >= startMonth)
                            .Sum(s => (decimal?)s.SalePrice) ?? 0;

        ComprasMes = db.Purchases.Where(p => p.Date >= startMonth)
                                 .Include(p => p.Items)
                                 .ToList()
                                 .Sum(p => p.TotalCost);

        Disponibles = all.Count(c => c.Status == ComponentStatus.Available);
        Vendidos = all.Count(c => c.Status == ComponentStatus.Sold);
        PendientesTest = all.Count(c => c.Status == ComponentStatus.PendingTest);
        EnReparacion = all.Count(c => c.Status == ComponentStatus.InRepair);
        Defectuosos = all.Count(c => c.Status == ComponentStatus.Defective);

        OnPropertyChanged(nameof(CapitalInvertido));
        OnPropertyChanged(nameof(ValorInventario));
        OnPropertyChanged(nameof(GananciaNeta));
        OnPropertyChanged(nameof(VentasMes));
        OnPropertyChanged(nameof(ComprasMes));
        OnPropertyChanged(nameof(Disponibles));
        OnPropertyChanged(nameof(Vendidos));
        OnPropertyChanged(nameof(PendientesTest));
        OnPropertyChanged(nameof(EnReparacion));
        OnPropertyChanged(nameof(Defectuosos));
        OnPropertyChanged(nameof(MesLabel));
    }
}
'@

Write-File "ViewModels\InventoryViewModel.cs" @'
using System.Collections.ObjectModel;
using System.Windows;
using HardwareERP.Data;
using HardwareERP.Models;
using HardwareERP.Views;
using Microsoft.EntityFrameworkCore;

namespace HardwareERP.ViewModels;

public class InventoryViewModel : ViewModelBase
{
    private ObservableCollection<Component> _components = new();
    public ObservableCollection<Component> Components { get => _components; set => SetProperty(ref _components, value); }

    private Component? _selected;
    public Component? Selected { get => _selected; set => SetProperty(ref _selected, value); }

    private string _searchText = "";
    public string SearchText { get => _searchText; set { if (SetProperty(ref _searchText, value)) Load(); } }

    private ComponentStatus? _statusFilter;
    public ComponentStatus? StatusFilter { get => _statusFilter; set { if (SetProperty(ref _statusFilter, value)) Load(); } }

    public Array Statuses => Enum.GetValues(typeof(ComponentStatus));

    public RelayCommand AddCommand { get; }
    public RelayCommand EditCommand { get; }
    public RelayCommand DeleteCommand { get; }
    public RelayCommand RefreshCommand { get; }

    public InventoryViewModel()
    {
        AddCommand = new RelayCommand(_ => OpenEditor(null));
        EditCommand = new RelayCommand(_ => { if (Selected != null) OpenEditor(Selected); });
        DeleteCommand = new RelayCommand(_ => { if (Selected != null) Delete(Selected); });
        RefreshCommand = new RelayCommand(_ => Load());
        Load();
    }

    public void Load()
    {
        using var db = new AppDbContext();
        var q = db.Components.Include(c => c.Partner).Where(c => c.IsActive).AsQueryable();
        if (!string.IsNullOrWhiteSpace(SearchText))
        {
            var s = SearchText.Trim().ToLower();
            q = q.Where(c => c.Model.ToLower().Contains(s) || c.Brand.ToLower().Contains(s)
                || c.Sku.ToLower().Contains(s) || (c.SerialNumber != null && c.SerialNumber.ToLower().Contains(s)));
        }
        if (StatusFilter.HasValue) q = q.Where(c => c.Status == StatusFilter.Value);
        Components = new ObservableCollection<Component>(q.OrderByDescending(c => c.CreatedAt).ToList());
    }

    private void OpenEditor(Component? c)
    {
        var win = new ComponentEditorWindow(c) { Owner = Application.Current.MainWindow };
        if (win.ShowDialog() == true) Load();
    }

    private void Delete(Component c)
    {
        var r = MessageBox.Show(
            $"Dar de baja '{c.Brand} {c.Model}'?\nLos registros historicos se conservan.",
            "Confirmar", MessageBoxButton.YesNo, MessageBoxImage.Warning);
        if (r != MessageBoxResult.Yes) return;
        using var db = new AppDbContext();
        var e = db.Components.Find(c.Id);
        if (e != null) { e.IsActive = false; e.UpdatedAt = DateTime.Now; db.SaveChanges(); }
        Load();
    }
}
'@

Write-File "ViewModels\PurchasesViewModel.cs" @'
using System.Collections.ObjectModel;
using System.Windows;
using HardwareERP.Data;
using HardwareERP.Views;
using Microsoft.EntityFrameworkCore;

namespace HardwareERP.ViewModels;

public class PurchaseRow
{
    public int Id { get; set; }
    public DateTime Date { get; set; }
    public string? Seller { get; set; }
    public string? PartnerName { get; set; }
    public int ItemCount { get; set; }
    public decimal TotalCost { get; set; }
}

public class PurchasesViewModel : ViewModelBase
{
    private ObservableCollection<PurchaseRow> _purchases = new();
    public ObservableCollection<PurchaseRow> Purchases { get => _purchases; set => SetProperty(ref _purchases, value); }

    public RelayCommand NewCommand { get; }
    public RelayCommand RefreshCommand { get; }

    public PurchasesViewModel()
    {
        NewCommand = new RelayCommand(_ => OpenEditor());
        RefreshCommand = new RelayCommand(_ => Load());
        Load();
    }

    public void Load()
    {
        using var db = new AppDbContext();
        var rows = db.Purchases
            .Include(p => p.Partner)
            .Include(p => p.Items)
            .OrderByDescending(p => p.Date)
            .ToList()
            .Select(p => new PurchaseRow
            {
                Id = p.Id,
                Date = p.Date,
                Seller = p.Seller,
                PartnerName = p.Partner?.Name,
                ItemCount = p.Items.Count,
                TotalCost = p.TotalCost
            })
            .ToList();
        Purchases = new ObservableCollection<PurchaseRow>(rows);
    }

    private void OpenEditor()
    {
        var win = new PurchaseEditorWindow { Owner = Application.Current.MainWindow };
        if (win.ShowDialog() == true) Load();
    }
}
'@

Write-File "ViewModels\SalesViewModel.cs" @'
using System.Collections.ObjectModel;
using System.Windows;
using HardwareERP.Data;
using HardwareERP.Views;
using Microsoft.EntityFrameworkCore;

namespace HardwareERP.ViewModels;

public class SaleRow
{
    public int Id { get; set; }
    public DateTime Date { get; set; }
    public string? Component { get; set; }
    public string? Buyer { get; set; }
    public decimal SalePrice { get; set; }
    public string? Platform { get; set; }
    public decimal NetProfit { get; set; }
    public bool IsVoided { get; set; }
}

public class SalesViewModel : ViewModelBase
{
    private ObservableCollection<SaleRow> _sales = new();
    public ObservableCollection<SaleRow> Sales { get => _sales; set => SetProperty(ref _sales, value); }

    public RelayCommand NewCommand { get; }
    public RelayCommand RefreshCommand { get; }

    public SalesViewModel()
    {
        NewCommand = new RelayCommand(_ => OpenEditor());
        RefreshCommand = new RelayCommand(_ => Load());
        Load();
    }

    public void Load()
    {
        using var db = new AppDbContext();
        var rows = db.Sales.Include(s => s.Component).OrderByDescending(s => s.Date).ToList()
            .Select(s => new SaleRow
            {
                Id = s.Id,
                Date = s.Date,
                Component = s.Component == null ? "" : $"{s.Component.Brand} {s.Component.Model}",
                Buyer = s.BuyerName,
                SalePrice = s.SalePrice,
                Platform = s.Platform,
                NetProfit = s.Component == null
                    ? 0
                    : s.SalePrice - s.Component.PurchasePrice - s.Component.AdditionalCosts - s.Commission - s.ShippingCost,
                IsVoided = s.IsVoided
            }).ToList();
        Sales = new ObservableCollection<SaleRow>(rows);
    }

    private void OpenEditor()
    {
        var win = new SaleEditorWindow { Owner = Application.Current.MainWindow };
        if (win.ShowDialog() == true) Load();
    }
}
'@

Write-File "MainWindow.xaml" @'
<Window x:Class="HardwareERP.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:vm="clr-namespace:HardwareERP.ViewModels"
        xmlns:views="clr-namespace:HardwareERP.Views"
        Title="HardwareERP" Height="820" Width="1400"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <DataTemplate DataType="{x:Type vm:DashboardViewModel}"><views:DashboardView/></DataTemplate>
        <DataTemplate DataType="{x:Type vm:InventoryViewModel}"><views:InventoryView/></DataTemplate>
        <DataTemplate DataType="{x:Type vm:PurchasesViewModel}"><views:PurchasesView/></DataTemplate>
        <DataTemplate DataType="{x:Type vm:SalesViewModel}"><views:SalesView/></DataTemplate>
    </Window.Resources>
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="230"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Border Grid.Column="0" Background="{StaticResource BgPanelBrush}"
                BorderBrush="{StaticResource BorderBrush}" BorderThickness="0,0,1,0">
            <StackPanel Margin="16">
                <TextBlock Text="HardwareERP" FontSize="22" FontWeight="Bold"
                           Foreground="{StaticResource AccentBrush}" Margin="0,12,0,4"/>
                <TextBlock Text="Gestion de componentes" FontSize="11"
                           Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,24"/>
                <Button Content="Dashboard" Command="{Binding ShowDashboardCommand}"
                        Style="{StaticResource GhostButton}" HorizontalContentAlignment="Left" Margin="0,0,0,6"/>
                <Button Content="Inventario" Command="{Binding ShowInventoryCommand}"
                        Style="{StaticResource GhostButton}" HorizontalContentAlignment="Left" Margin="0,0,0,6"/>
                <Button Content="Compras" Command="{Binding ShowPurchasesCommand}"
                        Style="{StaticResource GhostButton}" HorizontalContentAlignment="Left" Margin="0,0,0,6"/>
                <Button Content="Ventas" Command="{Binding ShowSalesCommand}"
                        Style="{StaticResource GhostButton}" HorizontalContentAlignment="Left" Margin="0,0,0,6"/>
            </StackPanel>
        </Border>
        <ContentControl Grid.Column="1" Content="{Binding CurrentViewModel}"/>
    </Grid>
</Window>
'@

Write-File "MainWindow.xaml.cs" @'
using System.Windows;
using HardwareERP.ViewModels;

namespace HardwareERP;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        DataContext = new MainViewModel();
    }
}
'@

Write-File "Views\DashboardView.xaml" @'
<UserControl x:Class="HardwareERP.Views.DashboardView"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <ScrollViewer>
        <StackPanel Margin="28">
            <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                <TextBlock Text="Dashboard" FontSize="28" FontWeight="Bold"/>
                <TextBlock Text="{Binding MesLabel}" FontSize="14" Margin="16,10,0,0"
                           Foreground="{StaticResource TextSecondaryBrush}"/>
                <Button Content="Actualizar" Command="{Binding RefreshCommand}" Margin="24,4,0,0"/>
            </StackPanel>

            <UniformGrid Columns="4" Margin="0,0,0,16">
                <Border Background="{StaticResource BgCardBrush}" Padding="18" CornerRadius="10" Margin="0,0,12,0">
                    <StackPanel>
                        <TextBlock Text="CAPITAL INVERTIDO" FontSize="11" Foreground="{StaticResource TextSecondaryBrush}"/>
                        <TextBlock Text="{Binding CapitalInvertido, StringFormat=C0}" FontSize="26" FontWeight="Bold" Margin="0,6,0,0"/>
                        <TextBlock Text="ARS" FontSize="11" Foreground="{StaticResource TextSecondaryBrush}"/>
                    </StackPanel>
                </Border>
                <Border Background="{StaticResource BgCardBrush}" Padding="18" CornerRadius="10" Margin="0,0,12,0">
                    <StackPanel>
                        <TextBlock Text="VALOR INVENTARIO" FontSize="11" Foreground="{StaticResource TextSecondaryBrush}"/>
                        <TextBlock Text="{Binding ValorInventario, StringFormat=C0}" FontSize="26" FontWeight="Bold" Margin="0,6,0,0"/>
                        <TextBlock Text="Precio de venta estimado" FontSize="11" Foreground="{StaticResource TextSecondaryBrush}"/>
                    </StackPanel>
                </Border>
                <Border Background="{StaticResource BgCardBrush}" Padding="18" CornerRadius="10" Margin="0,0,12,0">
                    <StackPanel>
                        <TextBlock Text="GANANCIA NETA" FontSize="11" Foreground="{StaticResource TextSecondaryBrush}"/>
                        <TextBlock Text="{Binding GananciaNeta, StringFormat=C0}" FontSize="26" FontWeight="Bold"
                                   Foreground="{StaticResource SuccessBrush}" Margin="0,6,0,0"/>
                        <TextBlock Text="Acumulada (vendidos)" FontSize="11" Foreground="{StaticResource TextSecondaryBrush}"/>
                    </StackPanel>
                </Border>
                <Border Background="{StaticResource BgCardBrush}" Padding="18" CornerRadius="10">
                    <StackPanel>
                        <TextBlock Text="VENTAS DEL MES" FontSize="11" Foreground="{StaticResource TextSecondaryBrush}"/>
                        <TextBlock Text="{Binding VentasMes, StringFormat=C0}" FontSize="26" FontWeight="Bold" Margin="0,6,0,0"/>
                        <TextBlock Text="{Binding ComprasMes, StringFormat='Compras: {0:C0}'}" FontSize="11"
                                   Foreground="{StaticResource TextSecondaryBrush}"/>
                    </StackPanel>
                </Border>
            </UniformGrid>

            <Border Background="{StaticResource BgCardBrush}" Padding="20" CornerRadius="10" Margin="0,8,0,0">
                <StackPanel>
                    <TextBlock Text="Estado del inventario" FontSize="16" FontWeight="SemiBold" Margin="0,0,0,12"/>
                    <UniformGrid Columns="5">
                        <StackPanel Margin="0,0,12,0">
                            <TextBlock Text="Disponibles" Foreground="{StaticResource TextSecondaryBrush}" FontSize="12"/>
                            <TextBlock Text="{Binding Disponibles}" FontSize="32" FontWeight="Bold"
                                       Foreground="{StaticResource SuccessBrush}"/>
                        </StackPanel>
                        <StackPanel Margin="0,0,12,0">
                            <TextBlock Text="Vendidos" Foreground="{StaticResource TextSecondaryBrush}" FontSize="12"/>
                            <TextBlock Text="{Binding Vendidos}" FontSize="32" FontWeight="Bold"/>
                        </StackPanel>
                        <StackPanel Margin="0,0,12,0">
                            <TextBlock Text="Pendiente prueba" Foreground="{StaticResource TextSecondaryBrush}" FontSize="12"/>
                            <TextBlock Text="{Binding PendientesTest}" FontSize="32" FontWeight="Bold"
                                       Foreground="{StaticResource WarnBrush}"/>
                        </StackPanel>
                        <StackPanel Margin="0,0,12,0">
                            <TextBlock Text="En reparacion" Foreground="{StaticResource TextSecondaryBrush}" FontSize="12"/>
                            <TextBlock Text="{Binding EnReparacion}" FontSize="32" FontWeight="Bold"
                                       Foreground="{StaticResource AccentBrush}"/>
                        </StackPanel>
                        <StackPanel>
                            <TextBlock Text="Defectuosos" Foreground="{StaticResource TextSecondaryBrush}" FontSize="12"/>
                            <TextBlock Text="{Binding Defectuosos}" FontSize="32" FontWeight="Bold"
                                       Foreground="{StaticResource DangerBrush}"/>
                        </StackPanel>
                    </UniformGrid>
                </StackPanel>
            </Border>
        </StackPanel>
    </ScrollViewer>
</UserControl>
'@

Write-File "Views\DashboardView.xaml.cs" @'
using System.Windows.Controls;
namespace HardwareERP.Views;
public partial class DashboardView : UserControl { public DashboardView() => InitializeComponent(); }
'@

Write-File "Views\InventoryView.xaml" @'
<UserControl x:Class="HardwareERP.Views.InventoryView"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid Margin="28">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,16">
            <TextBlock Text="Inventario" FontSize="28" FontWeight="Bold" VerticalAlignment="Center"/>
        </StackPanel>

        <Grid Grid.Row="1" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="200"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox Grid.Column="0" Text="{Binding SearchText, UpdateSourceTrigger=PropertyChanged}"
                     Margin="0,0,12,0" VerticalContentAlignment="Center"/>
            <ComboBox Grid.Column="1" ItemsSource="{Binding Statuses}"
                      SelectedItem="{Binding StatusFilter}" Margin="0,0,12,0"/>
            <StackPanel Grid.Column="2" Orientation="Horizontal">
                <Button Content="Nuevo" Command="{Binding AddCommand}"/>
                <Button Content="Editar" Command="{Binding EditCommand}" Style="{StaticResource GhostButton}"/>
                <Button Content="Baja" Command="{Binding DeleteCommand}" Style="{StaticResource DangerButton}"/>
                <Button Content="Refrescar" Command="{Binding RefreshCommand}" Style="{StaticResource GhostButton}"/>
            </StackPanel>
        </Grid>

        <DataGrid Grid.Row="2" ItemsSource="{Binding Components}" SelectedItem="{Binding Selected}">
            <DataGrid.Columns>
                <DataGridTextColumn Header="SKU" Binding="{Binding Sku}" Width="140"/>
                <DataGridTextColumn Header="Categoria" Binding="{Binding Category}" Width="100"/>
                <DataGridTextColumn Header="Marca" Binding="{Binding Brand}" Width="100"/>
                <DataGridTextColumn Header="Modelo" Binding="{Binding Model}" Width="*"/>
                <DataGridTextColumn Header="Estado" Binding="{Binding Status}" Width="130"/>
                <DataGridTextColumn Header="Condicion" Binding="{Binding Condition}" Width="100"/>
                <DataGridTextColumn Header="Costo" Binding="{Binding PurchasePrice, StringFormat=C0}" Width="110"/>
                <DataGridTextColumn Header="Precio venta" Binding="{Binding SalePrice, StringFormat=C0}" Width="110"/>
                <DataGridTextColumn Header="Ubicacion" Binding="{Binding StorageLocation}" Width="110"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</UserControl>
'@

Write-File "Views\InventoryView.xaml.cs" @'
using System.Windows.Controls;
namespace HardwareERP.Views;
public partial class InventoryView : UserControl { public InventoryView() => InitializeComponent(); }
'@

Write-File "Views\ComponentEditorWindow.xaml" @'
<Window x:Class="HardwareERP.Views.ComponentEditorWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Componente" Height="700" Width="620"
        WindowStartupLocation="CenterOwner">
    <ScrollViewer>
        <StackPanel Margin="24">
            <TextBlock Text="SKU"/>
            <TextBox Text="{Binding Sku}" IsReadOnly="True"/>

            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Margin="0,0,8,0">
                    <TextBlock Text="Categoria"/>
                    <ComboBox x:Name="CategoryCombo" SelectedItem="{Binding Category}"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="8,0,0,0">
                    <TextBlock Text="Condicion"/>
                    <ComboBox x:Name="ConditionCombo" SelectedItem="{Binding Condition}"/>
                </StackPanel>
            </Grid>

            <TextBlock Text="Marca *"/>
            <TextBox x:Name="BrandBox" Text="{Binding Brand, UpdateSourceTrigger=PropertyChanged}"/>

            <TextBlock Text="Modelo *"/>
            <TextBox x:Name="ModelBox" Text="{Binding Model, UpdateSourceTrigger=PropertyChanged}"/>

            <TextBlock Text="Especificaciones"/>
            <TextBox Text="{Binding Specifications}" AcceptsReturn="True" Height="60"/>

            <TextBlock Text="Numero de serie"/>
            <TextBox Text="{Binding SerialNumber}"/>

            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Margin="0,0,8,0">
                    <TextBlock Text="Estado"/>
                    <ComboBox x:Name="StatusCombo" SelectedItem="{Binding Status}"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="8,0,0,0">
                    <TextBlock Text="Socio propietario"/>
                    <ComboBox x:Name="PartnerCombo" SelectedValuePath="Id" DisplayMemberPath="Name"
                              SelectedValue="{Binding PartnerId}"/>
                </StackPanel>
            </Grid>

            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Margin="0,0,8,0">
                    <TextBlock Text="Precio de compra (ARS)"/>
                    <TextBox x:Name="PurchasePriceBox" Text="{Binding PurchasePrice, UpdateSourceTrigger=PropertyChanged}"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="8,0,8,0">
                    <TextBlock Text="Costos adicionales"/>
                    <TextBox x:Name="AdditionalCostsBox" Text="{Binding AdditionalCosts, UpdateSourceTrigger=PropertyChanged}"/>
                </StackPanel>
                <StackPanel Grid.Column="2" Margin="8,0,0,0">
                    <TextBlock Text="Precio de venta"/>
                    <TextBox x:Name="SalePriceBox" Text="{Binding SalePrice, UpdateSourceTrigger=PropertyChanged}"/>
                </StackPanel>
            </Grid>

            <TextBlock Text="Ubicacion de almacenamiento"/>
            <TextBox Text="{Binding StorageLocation}"/>

            <TextBlock Text="Observaciones"/>
            <TextBox Text="{Binding Observations}" AcceptsReturn="True" Height="60"/>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
                <Button Content="Cancelar" Click="Cancel_Click" Style="{StaticResource GhostButton}"/>
                <Button Content="Guardar" Click="Save_Click"/>
            </StackPanel>
        </StackPanel>
    </ScrollViewer>
</Window>
'@

Write-File "Views\ComponentEditorWindow.xaml.cs" @'
using System.Windows;
using HardwareERP.Data;
using HardwareERP.Models;
using Microsoft.EntityFrameworkCore;

namespace HardwareERP.Views;

public partial class ComponentEditorWindow : Window
{
    private readonly Component? _original;
    private readonly Component _draft;

    public ComponentEditorWindow(Component? original)
    {
        InitializeComponent();
        _original = original;

        _draft = original == null
            ? new Component { Sku = GenerateSku() }
            : new Component
            {
                Id = original.Id, Sku = original.Sku, Category = original.Category,
                Brand = original.Brand, Model = original.Model, Specifications = original.Specifications,
                SerialNumber = original.SerialNumber, IngestDate = original.IngestDate,
                Status = original.Status, Condition = original.Condition,
                PurchasePrice = original.PurchasePrice, AdditionalCosts = original.AdditionalCosts,
                SalePrice = original.SalePrice, PartnerId = original.PartnerId,
                StorageLocation = original.StorageLocation, Observations = original.Observations,
                IsActive = original.IsActive, CreatedAt = original.CreatedAt, UpdatedAt = original.UpdatedAt
            };

        DataContext = _draft;
        CategoryCombo.ItemsSource = Enum.GetValues(typeof(ComponentCategory));
        ConditionCombo.ItemsSource = Enum.GetValues(typeof(ComponentCondition));
        StatusCombo.ItemsSource = Enum.GetValues(typeof(ComponentStatus));

        using var db = new AppDbContext();
        PartnerCombo.ItemsSource = db.Partners.Where(p => p.IsActive).ToList();

        Title = original == null ? "Nuevo componente" : $"Editar: {original.Brand} {original.Model}";
    }

    private static string GenerateSku()
    {
        using var db = new AppDbContext();
        int count = db.Components.Count();
        return $"HW-{DateTime.Now:yyMMdd}-{count + 1:D4}";
    }

    private void Save_Click(object sender, RoutedEventArgs e)
    {
        // forzar commit del binding del campo enfocado
        var focused = System.Windows.Input.Keyboard.FocusedElement as System.Windows.Controls.TextBox;
        focused?.GetBindingExpression(System.Windows.Controls.TextBox.TextProperty)?.UpdateSource();

        if (string.IsNullOrWhiteSpace(_draft.Brand) || string.IsNullOrWhiteSpace(_draft.Model))
        {
            MessageBox.Show("Marca y modelo son obligatorios.", "Validacion",
                MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }

        using var db = new AppDbContext();
        _draft.UpdatedAt = DateTime.Now;

        if (_original == null)
        {
            db.Components.Add(_draft);
        }
        else
        {
            var existing = db.Components.Find(_draft.Id);
            if (existing == null) { MessageBox.Show("Registro no encontrado."); return; }
            db.Entry(existing).CurrentValues.SetValues(_draft);
            existing.UpdatedAt = DateTime.Now;
        }
        db.SaveChanges();
        DialogResult = true;
        Close();
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
'@

Write-File "Views\PurchasesView.xaml" @'
<UserControl x:Class="HardwareERP.Views.PurchasesView"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid Margin="28">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,16">
            <TextBlock Text="Compras" FontSize="28" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,20,0"/>
            <Button Content="Nueva compra" Command="{Binding NewCommand}" VerticalAlignment="Center"/>
            <Button Content="Refrescar" Command="{Binding RefreshCommand}" Style="{StaticResource GhostButton}" VerticalAlignment="Center"/>
        </StackPanel>
        <DataGrid Grid.Row="1" ItemsSource="{Binding Purchases}">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Fecha" Binding="{Binding Date, StringFormat=dd/MM/yyyy HH:mm}" Width="140"/>
                <DataGridTextColumn Header="Vendedor" Binding="{Binding Seller}" Width="*"/>
                <DataGridTextColumn Header="Socio" Binding="{Binding PartnerName}" Width="130"/>
                <DataGridTextColumn Header="Items" Binding="{Binding ItemCount}" Width="80"/>
                <DataGridTextColumn Header="Total" Binding="{Binding TotalCost, StringFormat=C0}" Width="140"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</UserControl>
'@

Write-File "Views\PurchasesView.xaml.cs" @'
using System.Windows.Controls;
namespace HardwareERP.Views;
public partial class PurchasesView : UserControl { public PurchasesView() => InitializeComponent(); }
'@

Write-File "Views\PurchaseEditorWindow.xaml" @'
<Window x:Class="HardwareERP.Views.PurchaseEditorWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Nueva compra" Height="720" Width="900"
        WindowStartupLocation="CenterOwner">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Margin="0,0,8,0">
                <TextBlock Text="Vendedor"/>
                <TextBox x:Name="SellerBox"/>
            </StackPanel>
            <StackPanel Grid.Column="1" Margin="8,0,8,0">
                <TextBlock Text="Socio que compra"/>
                <ComboBox x:Name="PartnerCombo" DisplayMemberPath="Name" SelectedValuePath="Id"/>
            </StackPanel>
            <StackPanel Grid.Column="2" Margin="8,0,8,0">
                <TextBlock Text="Metodo de pago"/>
                <TextBox x:Name="PaymentBox"/>
            </StackPanel>
            <StackPanel Grid.Column="3" Margin="8,0,0,0">
                <TextBlock Text="Envio/traslado"/>
                <TextBox x:Name="ShippingBox" Text="0"/>
            </StackPanel>
        </Grid>

        <TextBlock Grid.Row="1" Text="Componentes incluidos en el lote"
                   FontWeight="SemiBold" Margin="0,16,0,8"/>

        <DataGrid Grid.Row="2" x:Name="ItemsGrid" CanUserAddRows="True" IsReadOnly="False"
                  AutoGenerateColumns="False" RowHeight="32">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Marca" Binding="{Binding Brand, Mode=TwoWay}" Width="120"/>
                <DataGridTextColumn Header="Modelo" Binding="{Binding Model, Mode=TwoWay}" Width="*"/>
                <DataGridTextColumn Header="Num Serie" Binding="{Binding SerialNumber, Mode=TwoWay}" Width="140"/>
                <DataGridTextColumn Header="Precio" Binding="{Binding Price, Mode=TwoWay, StringFormat=N2}" Width="120"/>
            </DataGrid.Columns>
        </DataGrid>

        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
            <Button Content="Cancelar" Click="Cancel_Click" Style="{StaticResource GhostButton}"/>
            <Button Content="Guardar compra" Click="Save_Click"/>
        </StackPanel>
    </Grid>
</Window>
'@

Write-File "Views\PurchaseEditorWindow.xaml.cs" @'
using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using HardwareERP.Data;
using HardwareERP.Models;

namespace HardwareERP.Views;

public class ComponentDraft
{
    public ComponentCategory Category { get; set; } = ComponentCategory.CPU;
    public string Brand { get; set; } = "";
    public string Model { get; set; } = "";
    public string? SerialNumber { get; set; }
    public decimal Price { get; set; }
}

public partial class PurchaseEditorWindow : Window
{
    private readonly ObservableCollection<ComponentDraft> _items = new();

    public PurchaseEditorWindow()
    {
        InitializeComponent();

        ItemsGrid.Columns.Insert(0, new DataGridComboBoxColumn
        {
            Header = "Categoria",
            SelectedItemBinding = new Binding(nameof(ComponentDraft.Category)) { Mode = BindingMode.TwoWay },
            ItemsSource = Enum.GetValues(typeof(ComponentCategory)),
            Width = 120
        });

        ItemsGrid.ItemsSource = _items;

        using var db = new AppDbContext();
        PartnerCombo.ItemsSource = db.Partners.Where(p => p.IsActive).ToList();
    }

    private void Save_Click(object sender, RoutedEventArgs e)
    {
        ItemsGrid.CommitEdit(DataGridEditingUnit.Row, true);

        if (_items.Count == 0)
        {
            MessageBox.Show("Agrega al menos un componente al lote.", "Validacion");
            return;
        }
        foreach (var it in _items)
        {
            if (string.IsNullOrWhiteSpace(it.Brand) || string.IsNullOrWhiteSpace(it.Model))
            {
                MessageBox.Show("Cada componente debe tener marca y modelo.", "Validacion");
                return;
            }
        }

        using var db = new AppDbContext();
        int count = db.Components.Count();
        var purchase = new Purchase
        {
            Seller = SellerBox.Text,
            PartnerId = PartnerCombo.SelectedValue as int?,
            PaymentMethod = PaymentBox.Text,
            ShippingCost = decimal.TryParse(ShippingBox.Text, out var sh) ? sh : 0
        };

        int idx = 0;
        foreach (var it in _items)
        {
            idx++;
            var component = new Component
            {
                Sku = $"HW-{DateTime.Now:yyMMdd}-{count + idx:D4}",
                Category = it.Category,
                Brand = it.Brand.Trim(),
                Model = it.Model.Trim(),
                SerialNumber = it.SerialNumber,
                PurchasePrice = it.Price,
                Status = ComponentStatus.PendingTest,
                Condition = ComponentCondition.Good
            };
            purchase.Items.Add(new PurchaseItem { Component = component, UnitPrice = it.Price });
        }

        db.Purchases.Add(purchase);
        db.SaveChanges();

        DialogResult = true;
        Close();
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
'@

Write-File "Views\SalesView.xaml" @'
<UserControl x:Class="HardwareERP.Views.SalesView"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid Margin="28">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,16">
            <TextBlock Text="Ventas" FontSize="28" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,20,0"/>
            <Button Content="Nueva venta" Command="{Binding NewCommand}" VerticalAlignment="Center"/>
            <Button Content="Refrescar" Command="{Binding RefreshCommand}" Style="{StaticResource GhostButton}" VerticalAlignment="Center"/>
        </StackPanel>
        <DataGrid Grid.Row="1" ItemsSource="{Binding Sales}">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Fecha" Binding="{Binding Date, StringFormat=dd/MM/yyyy HH:mm}" Width="140"/>
                <DataGridTextColumn Header="Producto" Binding="{Binding Component}" Width="*"/>
                <DataGridTextColumn Header="Comprador" Binding="{Binding Buyer}" Width="150"/>
                <DataGridTextColumn Header="Plataforma" Binding="{Binding Platform}" Width="120"/>
                <DataGridTextColumn Header="Precio" Binding="{Binding SalePrice, StringFormat=C0}" Width="120"/>
                <DataGridTextColumn Header="Ganancia neta" Binding="{Binding NetProfit, StringFormat=C0}" Width="140"/>
                <DataGridTextColumn Header="Anulada" Binding="{Binding IsVoided}" Width="80"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</UserControl>
'@

Write-File "Views\SalesView.xaml.cs" @'
using System.Windows.Controls;
namespace HardwareERP.Views;
public partial class SalesView : UserControl { public SalesView() => InitializeComponent(); }
'@

Write-File "Views\SaleEditorWindow.xaml" @'
<Window x:Class="HardwareERP.Views.SaleEditorWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Nueva venta" Height="640" Width="560"
        WindowStartupLocation="CenterOwner">
    <ScrollViewer>
        <StackPanel Margin="24">
            <TextBlock Text="Componente a vender *"/>
            <ComboBox x:Name="ComponentCombo" DisplayMemberPath="DisplayLabel" SelectedValuePath="Id"
                      SelectionChanged="ComponentCombo_SelectionChanged"/>

            <TextBlock Text="Precio de venta (ARS) *"/>
            <TextBox x:Name="PriceBox"/>

            <TextBlock Text="Comprador"/>
            <TextBox x:Name="BuyerBox"/>

            <TextBlock Text="Telefono"/>
            <TextBox x:Name="PhoneBox"/>

            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Margin="0,0,8,0">
                    <TextBlock Text="Plataforma"/>
                    <ComboBox x:Name="PlatformCombo" IsEditable="True">
                        <ComboBoxItem Content="MercadoLibre"/>
                        <ComboBoxItem Content="Facebook Marketplace"/>
                        <ComboBoxItem Content="WhatsApp"/>
                        <ComboBoxItem Content="Presencial"/>
                        <ComboBoxItem Content="Otro"/>
                    </ComboBox>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="8,0,0,0">
                    <TextBlock Text="Metodo de pago"/>
                    <ComboBox x:Name="PaymentCombo" IsEditable="True">
                        <ComboBoxItem Content="Efectivo"/>
                        <ComboBoxItem Content="Transferencia"/>
                        <ComboBoxItem Content="MercadoPago"/>
                        <ComboBoxItem Content="Otro"/>
                    </ComboBox>
                </StackPanel>
            </Grid>

            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Margin="0,0,8,0">
                    <TextBlock Text="Envio (ARS)"/>
                    <TextBox x:Name="ShippingBox" Text="0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="8,0,0,0">
                    <TextBlock Text="Comision (ARS)"/>
                    <TextBox x:Name="CommissionBox" Text="0"/>
                </StackPanel>
            </Grid>

            <TextBlock Text="Notas"/>
            <TextBox x:Name="NotesBox" AcceptsReturn="True" Height="60"/>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
                <Button Content="Cancelar" Click="Cancel_Click" Style="{StaticResource GhostButton}"/>
                <Button Content="Registrar venta" Click="Save_Click"/>
            </StackPanel>
        </StackPanel>
    </ScrollViewer>
</Window>
'@

Write-File "Views\SaleEditorWindow.xaml.cs" @'
using System.Windows;
using System.Windows.Controls;
using HardwareERP.Data;
using HardwareERP.Models;

namespace HardwareERP.Views;

public class SaleComponentOption
{
    public int Id { get; set; }
    public string DisplayLabel { get; set; } = "";
    public ComponentStatus Status { get; set; }
}

public partial class SaleEditorWindow : Window
{
    public SaleEditorWindow()
    {
        InitializeComponent();
        using var db = new AppDbContext();
        var list = db.Components
            .Where(c => c.IsActive && c.Status != ComponentStatus.Sold && c.Status != ComponentStatus.Defective)
            .OrderBy(c => c.Category).ThenBy(c => c.Brand).ThenBy(c => c.Model)
            .ToList()
            .Select(c => new SaleComponentOption
            {
                Id = c.Id,
                Status = c.Status,
                DisplayLabel = $"[{c.Status}] {c.Sku} - {c.Category} {c.Brand} {c.Model}"
            })
            .ToList();
        ComponentCombo.ItemsSource = list;
    }

    private void ComponentCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ComponentCombo.SelectedValue is not int id) return;
        using var db = new AppDbContext();
        var c = db.Components.Find(id);
        if (c?.SalePrice != null && string.IsNullOrWhiteSpace(PriceBox.Text))
            PriceBox.Text = c.SalePrice.Value.ToString("0.##");
    }

    private void Save_Click(object sender, RoutedEventArgs e)
    {
        if (ComponentCombo.SelectedValue is not int id)
        {
            MessageBox.Show("Selecciona un componente.", "Validacion");
            return;
        }
        if (!decimal.TryParse(PriceBox.Text, out var price) || price <= 0)
        {
            MessageBox.Show("Precio de venta invalido.", "Validacion");
            return;
        }

        using var db = new AppDbContext();
        var component = db.Components.Find(id);
        if (component == null) { MessageBox.Show("Componente no encontrado."); return; }

        var sale = new Sale
        {
            Date = DateTime.Now,
            ComponentId = id,
            SalePrice = price,
            BuyerName = BuyerBox.Text,
            BuyerPhone = PhoneBox.Text,
            Platform = (PlatformCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? PlatformCombo.Text,
            PaymentMethod = (PaymentCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? PaymentCombo.Text,
            ShippingCost = decimal.TryParse(ShippingBox.Text, out var sh) ? sh : 0,
            Commission = decimal.TryParse(CommissionBox.Text, out var cm) ? cm : 0,
            Notes = NotesBox.Text
        };

        component.Status = ComponentStatus.Sold;
        component.SoldPrice = price;
        component.SoldDate = sale.Date;
        component.UpdatedAt = DateTime.Now;

        db.Sales.Add(sale);
        db.SaveChanges();

        DialogResult = true;
        Close();
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
'@

# --- 4. Restore + build + publish ---
Write-Host "`nRestaurando paquetes NuGet..." -ForegroundColor Cyan
Push-Location $Root
try {
    & dotnet restore
    if ($LASTEXITCODE -ne 0) { throw "dotnet restore fallo" }

    Write-Host "`nCompilando (Release)..." -ForegroundColor Cyan
    & dotnet build -c Release --no-restore
    if ($LASTEXITCODE -ne 0) { throw "dotnet build fallo" }

    Write-Host "`nPublicando ejecutable autocontenido..." -ForegroundColor Cyan
    & dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true --no-build
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish fallo" }
}
finally {
    Pop-Location
}

$exe = Get-ChildItem -Path (Join-Path $Root "bin\Release\net8.0-windows\win-x64\publish") -Filter "HardwareERP.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    # fallback a la ruta estandar de publish
    $exe = Get-ChildItem -Path (Join-Path $Root "bin\Release\net8.0-windows") -Filter "HardwareERP.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}

Write-Host "`n=== LISTO ===" -ForegroundColor Green
if ($exe) {
    Write-Host "Ejecutable: $($exe.FullName)" -ForegroundColor Green
    Write-Host "Base de datos: $env:LOCALAPPDATA\HardwareERP\hardware.db" -ForegroundColor DarkGray
    Write-Host "Respaldos:     $env:LOCALAPPDATA\HardwareERP\backups\" -ForegroundColor DarkGray
    if (-not $SkipRun) {
        Write-Host "`nAbriendo la aplicacion..." -ForegroundColor Cyan
        Start-Process -FilePath $exe.FullName
    }
} else {
    Write-Host "No se encontro el .exe. Revisa los errores de compilacion arriba." -ForegroundColor Red
}
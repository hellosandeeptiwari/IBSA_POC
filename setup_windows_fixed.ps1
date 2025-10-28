# PowerShell script for setting up IBSA PoC environment on Windows
# Run this script in PowerShell as Administrator if needed

Write-Host "🚀 Setting up IBSA PoC Environment on Windows" -ForegroundColor Green
Write-Host ("=" * 50)

# Function to run commands safely
function Invoke-SafeCommand {
    param($Command, $Description)
    Write-Host "`n🔄 $Description..." -ForegroundColor Yellow
    try {
        Invoke-Expression $Command
        Write-Host "✓ $Description - Success!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ $Description - Failed: $_" -ForegroundColor Red
        return $false
    }
}

# Check if virtual environment exists, create if not
if (!(Test-Path "ibsa_env")) {
    Write-Host "`n📁 Creating virtual environment..." -ForegroundColor Blue
    python -m venv ibsa_env
}

# Activate virtual environment
Write-Host "`n🔌 Activating virtual environment..." -ForegroundColor Blue
& ".\ibsa_env\Scripts\Activate.ps1"

# Check if activation was successful
if ($env:VIRTUAL_ENV) {
    Write-Host "✓ Virtual environment activated: $env:VIRTUAL_ENV" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to activate virtual environment" -ForegroundColor Red
    exit 1
}

# Upgrade pip
Invoke-SafeCommand "pip install --upgrade pip" "Upgrading pip"

# Install core packages first
Write-Host "`n📦 Installing core numerical packages..." -ForegroundColor Blue
$corePackages = @("numpy>=1.24.0,<1.27.0", "pandas>=2.0.0,<2.3.0")
foreach ($package in $corePackages) {
    $packageName = $package.Split(">=")[0]
    $success = Invoke-SafeCommand "pip install --only-binary=all `"$package`"" "Installing $packageName (wheels only)"
    if (-not $success) {
        Write-Host "⚠️ Retrying $packageName without wheel restriction..." -ForegroundColor Yellow
        Invoke-SafeCommand "pip install `"$packageName`"" "Installing $packageName (fallback)"
    }
}

# Install visualization packages
Write-Host "`n📦 Installing visualization packages..." -ForegroundColor Blue
$vizPackages = @("matplotlib>=3.7.0,<3.9.0", "seaborn>=0.12.0,<0.14.0")
foreach ($package in $vizPackages) {
    $packageName = $package.Split(">=")[0]
    $success = Invoke-SafeCommand "pip install --only-binary=all `"$package`"" "Installing $packageName (wheels only)"
    if (-not $success) {
        Write-Host "⚠️ Retrying $packageName without wheel restriction..." -ForegroundColor Yellow
        Invoke-SafeCommand "pip install `"$packageName`"" "Installing $packageName (fallback)"
    }
}

# Install machine learning (may take time)
Write-Host "`n📦 Installing machine learning packages (may take a few minutes)..." -ForegroundColor Blue
$success = Invoke-SafeCommand "pip install --only-binary=all `"scikit-learn>=1.3.0,<1.6.0`"" "Installing scikit-learn (wheels only)"
if (-not $success) {
    Write-Host "⚠️ Retrying scikit-learn with older version..." -ForegroundColor Yellow
    Invoke-SafeCommand "pip install scikit-learn==1.3.2" "Installing scikit-learn (fallback)"
}

# Install big data processing
Write-Host "`n📦 Installing big data processing..." -ForegroundColor Blue
Invoke-SafeCommand "pip install `"pyspark>=3.4.0,<3.6.0`"" "Installing PySpark"

# Install utilities
Write-Host "`n📦 Installing utilities..." -ForegroundColor Blue
$utilPackages = @("psutil>=5.9.0,<7.0.0", "SQLAlchemy>=2.0.0,<2.1.0", "requests>=2.31.0,<3.0.0")
foreach ($package in $utilPackages) {
    $packageName = $package.Split(">=")[0]
    Invoke-SafeCommand "pip install `"$package`"" "Installing $packageName"
}

# Handle problematic packages separately
Write-Host "`n🔧 Installing file format libraries (pyarrow, fastparquet)..." -ForegroundColor Blue
$arrowSuccess = Invoke-SafeCommand "pip install --only-binary=all `"pyarrow>=15.0.0,<17.0.0`"" "Installing pyarrow"
$parquetSuccess = Invoke-SafeCommand "pip install --only-binary=all `"fastparquet>=2023.10.0,<2025.1.0`"" "Installing fastparquet"

if (-not $arrowSuccess -or -not $parquetSuccess) {
    Write-Host "⚠️ Some file format libraries failed. Consider using conda:" -ForegroundColor Yellow
    Write-Host "   conda install pyarrow fastparquet" -ForegroundColor Cyan
}

# Create verification script
$verifyScript = @'
import sys
packages = {
    "numpy": "NumPy",
    "pandas": "Pandas", 
    "matplotlib": "Matplotlib",
    "seaborn": "Seaborn",
    "sklearn": "Scikit-learn",
    "pyspark": "PySpark"
}

print("🔍 Verifying package installation...")
print("-" * 40)

failed = []
for pkg, name in packages.items():
    try:
        __import__(pkg)
        print(f"✓ {name}")
    except ImportError as e:
        print(f"✗ {name} - {e}")
        failed.append(name)

print("-" * 40)
if failed:
    print(f"⚠️ Failed packages: {', '.join(failed)}")
    print("Check PYTHON_SETUP_GUIDE.md for troubleshooting")
else:
    print("🎉 All packages imported successfully!")
    print("\nYour environment is ready for:")
    print("• Data analysis and processing")  
    print("• Machine learning workflows")
    print("• Visualization and reporting")
'@

$verifyScript | Out-File -FilePath "verify_installation.py" -Encoding UTF8

# Run verification
Write-Host "`n🔍 Verifying installation..." -ForegroundColor Blue
python verify_installation.py

# Setup completion message
Write-Host ("`n" + ("=" * 50))
Write-Host "🎉 Python environment setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. For UI: cd ibsa-precall-ui; npm install; npm run dev" -ForegroundColor White
Write-Host "2. For data analysis: python your_script.py" -ForegroundColor White
Write-Host "3. Check PYTHON_SETUP_GUIDE.md for troubleshooting" -ForegroundColor White

Write-Host "`nEnvironment activated. To deactivate later: deactivate" -ForegroundColor Yellow
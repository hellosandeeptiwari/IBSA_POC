#!/usr/bin/env python3
"""
Automated setup script for IBSA PoC Python environment
This script handles the installation issues we encountered
"""

import subprocess
import sys
import os

def run_command(cmd, description):
    """Run a command and handle errors gracefully"""
    print(f"\n🔄 {description}...")
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
        print(f"✓ {description} - Success!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"✗ {description} - Failed!")
        print(f"Error: {e.stderr}")
        return False

def main():
    print("🚀 Setting up IBSA PoC Python Environment")
    print("=" * 50)
    
    # Upgrade pip first
    run_command("pip install --upgrade pip", "Upgrading pip")
    
    # Install core packages with pre-compiled wheels
    core_packages = [
        "numpy>=1.24.0,<1.27.0",
        "pandas>=2.0.0,<2.3.0", 
        "matplotlib>=3.7.0,<3.9.0",
        "seaborn>=0.12.0,<0.14.0"
    ]
    
    for package in core_packages:
        success = run_command(f"pip install --only-binary=all \"{package}\"", f"Installing {package.split('>=')[0]}")
        if not success:
            # Fallback without version constraints
            pkg_name = package.split('>=')[0]
            run_command(f"pip install {pkg_name}", f"Installing {pkg_name} (fallback)")
    
    # Try scikit-learn with specific handling
    print("\n🔄 Installing scikit-learn (may take a few minutes)...")
    sklearn_success = run_command("pip install --only-binary=all \"scikit-learn>=1.3.0,<1.6.0\"", "Installing scikit-learn with wheels")
    
    if not sklearn_success:
        print("⚠️ Trying alternative scikit-learn installation...")
        run_command("pip install scikit-learn==1.3.2", "Installing older scikit-learn version")
    
    # Try pyarrow and fastparquet
    print("\n🔄 Installing file format libraries...")
    arrow_success = run_command("pip install --only-binary=all \"pyarrow>=15.0.0,<17.0.0\"", "Installing pyarrow")
    parquet_success = run_command("pip install --only-binary=all \"fastparquet>=2023.10.0,<2025.1.0\"", "Installing fastparquet")
    
    if not arrow_success:
        print("⚠️ PyArrow failed, you may need to install it manually with conda")
    if not parquet_success:
        print("⚠️ FastParquet failed, you may need to install it manually with conda")
    
    # Install remaining packages
    remaining_packages = [
        "pyspark>=3.4.0,<3.6.0",
        "psutil>=5.9.0,<7.0.0",
        "SQLAlchemy>=2.0.0,<2.1.0",
        "openpyxl>=3.1.0,<4.0.0",
        "requests>=2.31.0,<3.0.0",
        "python-dotenv>=1.0.0,<2.0.0"
    ]
    
    for package in remaining_packages:
        pkg_name = package.split('>=')[0]
        run_command(f"pip install \"{package}\"", f"Installing {pkg_name}")
    
    # Verify installation
    print("\n🔍 Verifying installation...")
    verification_code = '''
import sys
packages = ["numpy", "pandas", "matplotlib", "seaborn", "pyspark"]
failed = []

for pkg in packages:
    try:
        __import__(pkg)
        print(f"✓ {pkg}")
    except ImportError:
        print(f"✗ {pkg}")
        failed.append(pkg)

if failed:
    print(f"\\n⚠️ Failed to import: {', '.join(failed)}")
    sys.exit(1)
else:
    print("\\n🎉 All core packages imported successfully!")
'''
    
    with open("verify_setup.py", "w") as f:
        f.write(verification_code)
    
    run_command("python verify_setup.py", "Verifying package imports")
    
    print("\n" + "=" * 50)
    print("🎉 Setup complete!")
    print("\nNext steps:")
    print("1. For UI development: cd ibsa-precall-ui && npm install && npm run dev")
    print("2. For data analysis: python your_analysis_script.py")
    print("\nIf you encounter issues, check PYTHON_SETUP_GUIDE.md")

if __name__ == "__main__":
    main()
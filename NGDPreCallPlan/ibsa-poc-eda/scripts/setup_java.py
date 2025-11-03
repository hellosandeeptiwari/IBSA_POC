#!/usr/bin/env python3
"""
Java Setup for Spark
====================
Download and setup Java for Spark if not available
"""

import os
import sys
import requests
import zipfile
from pathlib import Path
import subprocess

def check_java():
    """Check if Java is available"""
    try:
        result = subprocess.run(['java', '-version'], capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False

def setup_portable_java():
    """Setup portable OpenJDK for Spark"""
    print("🔧 Setting up portable Java for Spark...")
    
    project_root = Path("..").resolve()
    java_dir = project_root / "java"
    
    if java_dir.exists():
        print("✅ Java directory already exists")
        java_exe = java_dir / "bin" / "java.exe"
        if java_exe.exists():
            print(f"✅ Java found at: {java_exe}")
            return str(java_exe)
    
    print("⬇️  Downloading OpenJDK 11...")
    
    # Download OpenJDK 11 (Windows x64)
    java_url = "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.20%2B8/OpenJDK11U-jdk_x64_windows_hotspot_11.0.20_8.zip"
    java_zip = project_root / "openjdk.zip"
    
    try:
        response = requests.get(java_url, stream=True)
        response.raise_for_status()
        
        with open(java_zip, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        print("📦 Extracting OpenJDK...")
        
        with zipfile.ZipFile(java_zip, 'r') as zip_ref:
            zip_ref.extractall(project_root)
        
        # Find the extracted JDK directory
        extracted_dirs = [d for d in project_root.glob("jdk*") if d.is_dir()]
        if extracted_dirs:
            extracted_dirs[0].rename(java_dir)
            
        java_zip.unlink()  # Remove zip file
        
        java_exe = java_dir / "bin" / "java.exe"
        if java_exe.exists():
            print(f"✅ Java setup complete: {java_exe}")
            return str(java_exe)
        else:
            print("❌ Java executable not found after extraction")
            return None
            
    except Exception as e:
        print(f"❌ Failed to setup Java: {e}")
        return None

def configure_spark_java():
    """Configure Spark to use our Java"""
    
    if check_java():
        print("✅ System Java is available")
        return True
    
    print("⚠️  System Java not found, setting up portable Java...")
    
    java_exe = setup_portable_java()
    if not java_exe:
        return False
    
    # Set environment variables for Spark
    java_home = str(Path(java_exe).parent.parent)
    
    os.environ['JAVA_HOME'] = java_home
    os.environ['PATH'] = f"{Path(java_exe).parent};{os.environ.get('PATH', '')}"
    
    print(f"✅ JAVA_HOME set to: {java_home}")
    print(f"✅ Java executable: {java_exe}")
    
    return True

if __name__ == "__main__":
    success = configure_spark_java()
    if success:
        print("🎉 Java is ready for Spark!")
        exit(0)
    else:
        print("❌ Failed to setup Java for Spark")
        exit(1)
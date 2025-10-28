# Python Environment Setup Guide

## Quick Setup (Recommended)

### 1. Create Virtual Environment
```bash
python -m venv ibsa_env
```

### 2. Activate Virtual Environment

**Windows (PowerShell):**
```bash
.\ibsa_env\Scripts\Activate.ps1
```

**Windows (Command Prompt):**
```bash
ibsa_env\Scripts\activate.bat
```

**Linux/Mac:**
```bash
source ibsa_env/bin/activate
```

### 3. Install Dependencies with Pre-compiled Wheels

**Option A: Fast Installation (Recommended)**
```bash
pip install --upgrade pip
pip install --only-binary=all numpy pandas matplotlib seaborn scikit-learn
pip install --only-binary=all pyarrow fastparquet
pip install -r requirements.txt
```

**Option B: If Option A fails, install core packages individually:**
```bash
pip install --upgrade pip
pip install numpy>=1.24.0,<1.27.0
pip install pandas>=2.0.0,<2.3.0  
pip install matplotlib>=3.7.0,<3.9.0
pip install seaborn>=0.12.0,<0.14.0
pip install scikit-learn>=1.3.0,<1.6.0
pip install pyspark>=3.4.0,<3.6.0
pip install psutil>=5.9.0,<7.0.0
pip install SQLAlchemy>=2.0.0,<2.1.0
```

## Troubleshooting

### If scikit-learn compilation fails:
```bash
# Use conda instead of pip for scikit-learn
conda install scikit-learn
# OR use older version
pip install scikit-learn==1.3.2
```

### If pyarrow/fastparquet compilation fails:
```bash
# Install conda version
conda install pyarrow fastparquet
# OR use alternative
pip install polars  # Alternative to pyarrow
```

### If matplotlib is slow:
```bash
# Use conda for faster matplotlib installation
conda install matplotlib
```

## Environment Verification

Run this to verify your setup:
```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
try:
    import sklearn
    print("✓ All packages imported successfully!")
except ImportError as e:
    print(f"✗ Import error: {e}")
```

## Next.js UI Setup

1. Navigate to UI directory:
```bash
cd ibsa-precall-ui
```

2. Install Node.js dependencies:
```bash
npm install
```

3. Start development server:
```bash
npm run dev
```

The UI will be available at: http://localhost:3000

## Common Issues & Solutions

1. **Python 3.14 Compatibility**: Some packages may not have wheels for Python 3.14. Use Python 3.11 or 3.12 if issues persist.

2. **Windows Build Tools**: If you get "Microsoft Visual C++ 14.0 is required" error:
   - Install Visual Studio Build Tools
   - OR use pre-compiled wheels with `--only-binary=all`

3. **Memory Issues**: If installation fails due to memory, install packages one by one instead of all at once.

4. **Network Timeouts**: If downloads timeout:
```bash
pip install --timeout=1000 package_name
```
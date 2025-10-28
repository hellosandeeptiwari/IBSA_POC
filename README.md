# IBSA PoC V2 - Improved Setup

This project includes both Python data analysis components and a Next.js UI application.

## Quick Start

### Option 1: Automated Setup (Recommended)

**Windows PowerShell:**
```powershell
# Run as Administrator if needed
.\setup_windows.ps1
```

**Python script (Cross-platform):**
```bash
python setup_environment.py
```

### Option 2: Manual Setup

1. **Create and activate virtual environment:**
```bash
python -m venv ibsa_env

# Windows
.\ibsa_env\Scripts\Activate.ps1

# Linux/Mac  
source ibsa_env/bin/activate
```

2. **Install Python dependencies:**
```bash
pip install --upgrade pip
pip install --only-binary=all numpy pandas matplotlib seaborn scikit-learn
pip install -r requirements.txt
```

3. **For UI development:**
```bash
cd ibsa-precall-ui
npm install
npm run dev
```

## Project Structure

```
IBSA PoC V2/
├── ibsa-precall-ui/          # Next.js UI application
├── ibsa-poc-eda/            # Data analysis notebooks
├── executive-presentations/  # Presentation generators
├── *.py                     # Analysis scripts
├── requirements.txt         # Python dependencies (UPDATED)
├── PYTHON_SETUP_GUIDE.md   # Detailed setup instructions
└── setup_*.{py,ps1}        # Automated setup scripts
```

## What's Fixed

✅ **Installation Issues Resolved:**
- Fixed scikit-learn compilation failures
- Resolved pyarrow/fastparquet build issues  
- Optimized matplotlib installation speed
- Added proper version constraints
- Included pre-compiled wheel preferences

✅ **Environment Management:**
- Automated virtual environment setup
- Cross-platform compatibility scripts
- Error handling and fallback options
- Installation verification

## Troubleshooting

If you encounter issues:

1. **Check the detailed guide:** `PYTHON_SETUP_GUIDE.md`
2. **Use Python 3.11 or 3.12** if you have Python 3.14 compatibility issues
3. **Install Visual Studio Build Tools** on Windows if needed
4. **Use conda** as fallback for problematic packages

## Running the Applications

### Python Scripts
```bash
# Make sure virtual environment is activated
python analyze_prescriber_patterns.py
python create_enterprise_mvp_deck.py
```

### UI Application
```bash
cd ibsa-precall-ui
npm run dev
# Visit http://localhost:3000
```

## Key Improvements

- **Reliable Installation**: Uses pre-compiled wheels where possible
- **Better Error Handling**: Graceful fallbacks for compilation issues
- **Version Management**: Compatible version ranges instead of exact pins
- **Platform Support**: Works on Windows, Linux, and macOS
- **Documentation**: Clear setup instructions and troubleshooting

## Support

For setup issues, check:
1. `PYTHON_SETUP_GUIDE.md` - Comprehensive troubleshooting
2. `requirements.txt` - Updated with compatible versions
3. Automated setup scripts for your platform
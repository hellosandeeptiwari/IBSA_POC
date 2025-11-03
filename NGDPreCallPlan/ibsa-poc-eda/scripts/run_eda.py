#!/usr/bin/env python3
"""
IBSA Pharmaceutical EDA Runner  
============================
Simple wrapper to run the main IBSA EDA analysis
"""

import sys
from pathlib import Path

# Import the main analysis class
sys.path.append(str(Path(__file__).parent))
from ibsa_eda_main import IBSAEDAAnalysis

def main():
    """Run IBSA EDA analysis"""
    print("🚀 Starting IBSA Pharmaceutical EDA...")
    
    analyzer = IBSAEDAAnalysis()
    success = analyzer.run_complete_analysis()
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
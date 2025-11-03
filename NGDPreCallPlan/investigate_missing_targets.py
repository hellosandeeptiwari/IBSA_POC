#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Investigate why 6 targets have no variance
"""

import pandas as pd
import numpy as np
from pathlib import Path

# Load targets
TARGETS_DIR = Path(r'c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\targets')
target_files = sorted(TARGETS_DIR.glob('IBSA_Targets_Enterprise_*.csv'))
latest_targets = target_files[-1]

print(f"Loading: {latest_targets.name}\n")
df = pd.read_csv(latest_targets)

print("="*80)
print("TARGET VARIANCE ANALYSIS")
print("="*80)

# Targets with issues
problem_targets = [
    'Tirosint_prescription_lift',
    'Flector_prescription_lift', 
    'Licart_prescription_lift',
    'Tirosint_territory_share_shift',
    'Flector_territory_share_shift',
    'Licart_territory_share_shift'
]

for target in problem_targets:
    print(f"\n📊 {target}")
    print(f"   Unique values: {df[target].nunique()}")
    print(f"   Value counts:")
    print(df[target].value_counts().head(10))
    print(f"   Min: {df[target].min()}, Max: {df[target].max()}")
    print(f"   Data type: {df[target].dtype}")
    
    # Check for NaN
    nan_count = df[target].isna().sum()
    if nan_count > 0:
        print(f"   ⚠️  NaN values: {nan_count:,} ({nan_count/len(df)*100:.2f}%)")

print("\n" + "="*80)
print("COMPARISON WITH WORKING TARGETS")
print("="*80)

working_targets = [
    'Tirosint_call_success',
    'Flector_call_success',
    'Licart_call_success'
]

for target in working_targets:
    print(f"\n✅ {target}")
    print(f"   Unique values: {df[target].nunique()}")
    print(f"   Value counts:")
    print(df[target].value_counts())

print("\n" + "="*80)
print("RECOMMENDATION")
print("="*80)
print("""
If all values are 0:
  → The target logic in Phase 5 may be too strict
  → Or the data period doesn't capture enough activity
  → Need to review Phase 5 target engineering script

Solutions:
  1. Check Phase 5 calculation logic
  2. Expand time window for target calculation
  3. Lower thresholds for "success" definition
  4. Use continuous metrics instead of binary
""")

"""Check if Phase 4B and Phase 5 are ready for model training"""
import pandas as pd
import json
from pathlib import Path

print("="*100)
print("PHASE 6 MODEL TRAINING - PRE-FLIGHT CHECK")
print("="*100)

# Check Phase 3 EDA
print("\n1. PHASE 3 EDA - Feature Selection Report")
print("-" * 80)
eda_file = Path('ibsa-poc-eda/outputs/eda-enterprise/feature_selection_report.json')
if eda_file.exists():
    with open(eda_file) as f:
        eda_data = json.load(f)
    print(f"✅ Feature selection report found")
    print(f"   • Total features analyzed: {eda_data['summary']['total_features_analyzed']}")
    print(f"   • Features to keep: {eda_data['summary']['features_to_keep']}")
    print(f"   • Features to remove: {eda_data['summary']['features_to_remove']}")
    print(f"   • High priority features: {eda_data['summary']['high_priority_features']}")
    print(f"   • Reduction: {eda_data['summary']['reduction_percentage']:.1f}%")
else:
    print(f"⚠️  Feature selection report NOT found at {eda_file}")

# Check Phase 4B Features
print("\n2. PHASE 4B FEATURES - Enterprise Features with EDA")
print("-" * 80)
features_dir = Path('ibsa-poc-eda/outputs/features')
enterprise_files = sorted(features_dir.glob('IBSA_EnterpriseFeatures_EDA_*.csv'))

if enterprise_files:
    latest = enterprise_files[-1]
    print(f"✅ Latest enterprise features: {latest.name}")
    
    # Load first few rows to check structure
    df = pd.read_csv(latest, nrows=10, index_col=0)
    print(f"   • Shape: {df.shape[0]} rows (sample), {df.shape[1]} columns")
    print(f"   • Index: {df.index.name}")
    
    # Check required product columns
    required = ['tirosint_trx', 'flector_trx', 'licart_trx', 'competitor_trx', 'ibsa_share']
    print(f"\n   Required product columns:")
    all_present = True
    for col in required:
        if col in df.columns:
            print(f"      ✓ {col}")
        else:
            print(f"      ✗ {col} - MISSING!")
            all_present = False
    
    if all_present:
        print(f"\n   ✅ ALL REQUIRED COLUMNS PRESENT - Phase 4B READY!")
    else:
        print(f"\n   ❌ MISSING REQUIRED COLUMNS - Phase 4B NOT READY!")
        print(f"   Available columns: {df.columns.tolist()[:20]}")
else:
    print(f"❌ No enterprise features found in {features_dir}")

# Check Phase 5 Targets
print("\n3. PHASE 5 TARGETS - Enterprise Targets")
print("-" * 80)
targets_dir = Path('ibsa-poc-eda/outputs/targets')
target_files = sorted(targets_dir.glob('IBSA_Targets_Enterprise_*.csv'))

if target_files:
    latest = target_files[-1]
    print(f"✅ Latest enterprise targets: {latest.name}")
    
    # Load to check structure
    df = pd.read_csv(latest, nrows=10)
    print(f"   • Shape: {df.shape[0]} rows (sample), {df.shape[1]} columns")
    
    # Check for 12 expected targets (3 products × 4 outcomes)
    products = ['Tirosint', 'Flector', 'Licart']
    outcomes = ['call_success', 'prescription_lift', 'ngd_category', 'territory_share_shift']
    
    expected_targets = [f'{p}_{o}' for p in products for o in outcomes]
    
    print(f"\n   Expected targets (12 total):")
    all_present = True
    for target in expected_targets:
        if target in df.columns:
            print(f"      ✓ {target}")
        else:
            print(f"      ✗ {target} - MISSING!")
            all_present = False
    
    if all_present:
        print(f"\n   ✅ ALL 12 TARGETS PRESENT - Phase 5 READY!")
    else:
        print(f"\n   ⚠️  SOME TARGETS MISSING")
        print(f"   Available target columns: {[c for c in df.columns if any(p.lower() in c.lower() for p in products)]}")
else:
    print(f"❌ No enterprise targets found in {targets_dir}")

# Summary
print("\n" + "="*100)
print("SUMMARY - READY TO RUN PHASE 6?")
print("="*100)

ready_count = 0
if eda_file.exists():
    print("✅ Phase 3 EDA: Feature selection available")
    ready_count += 1
else:
    print("⚠️  Phase 3 EDA: Feature selection missing (will use all features)")

if enterprise_files:
    print("✅ Phase 4B: Enterprise features available")
    ready_count += 1
else:
    print("❌ Phase 4B: Enterprise features MISSING")

if target_files:
    print("✅ Phase 5: Enterprise targets available")
    ready_count += 1
else:
    print("❌ Phase 5: Enterprise targets MISSING")

print("\n" + "="*100)
if ready_count >= 2:  # Need at least Phase 4B + Phase 5
    print("🎯 READY TO RUN PHASE 6 MODEL TRAINING!")
    print("Execute: python phase6_model_training.py")
else:
    print("❌ NOT READY - Complete Phase 4B and Phase 5 first")
print("="*100)

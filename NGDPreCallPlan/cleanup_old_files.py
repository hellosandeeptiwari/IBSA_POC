"""
Cleanup Script: Remove old/unused CSV and JSON files
Identifies files that are outdated or not referenced by active code
"""

import os
from pathlib import Path
from datetime import datetime
import shutil

BASE_DIR = Path(__file__).parent

# Files currently referenced in active code
ACTIVE_FILES = {
    # Source data (raw input - KEEP)
    'Reporting_BI_PrescriberOverview.csv',
    'Reporting_BI_PrescriberProfile.csv',
    'Reporting_BI_PrescriberPaymentPlanSummary.csv',
    'Reporting_BI_Trx_SampleSummary.csv',
    'Reporting_BI_Nrx_SampleSummary.csv',
    'Reporting_BI_TerritoryPerformanceSummary.csv',
    'Reporting_BI_TerritoryPerformanceOverview.csv',
    'Reporting_Live_HCP_Universe.csv',
    'Reporting_BI_CallActivity.csv',
    'Reporting_BI_NGD.csv',
    'Reporting_BI_Sample_LL_DTP.csv',
    'Reporting_Bi_Territory_CallSummary.csv',
    'Reporting_BI_CallAttainment_Summary_TerritoryLevel.csv',
    'Reporting_BI_CallAttainment_Summary_Tier.csv',
    
    # Latest Phase 4C output (KEEP - actively used)
    'IBSA_Features_CLEANED_20251030_035304.csv',
    
    # Latest Phase 5 output (KEEP - actively used)
    'IBSA_Targets_Enterprise_20251030_052001.csv',
    
    # Latest Phase 3 EDA outputs (KEEP - referenced by Phase 4)
    'feature_selection_report.json',
    'feature_selection_decisions.csv',
    'eda_recommendations.json',
    'competitive_intelligence_analysis.json',
    
    # Latest Phase 6 outputs (KEEP - trained models metadata)
    'model_performance_report_20251030_070424.json',
    'training_audit_log_20251030_070424.json',
    
    # Latest Phase 7 output (KEEP - UI predictions)
    'hcp_ml_predictions_top100.csv',
    
    # UI data (KEEP - 368MB dataset)
    'IBSA_ModelReady_Sample.csv',
}

# Patterns for files to KEEP (latest versions)
KEEP_PATTERNS = [
    'IBSA_Features_CLEANED_20251030_*.csv',  # Latest Phase 4C
    'IBSA_Targets_Enterprise_20251030_*.csv',  # Latest Phase 5
    'model_performance_report_20251030_*.json',  # Latest Phase 6
    'training_audit_log_20251030_*.json',  # Latest Phase 6
    'targets_audit_log_20251030_*.json',  # Latest Phase 5
    'targets_quality_report_20251030_*.json',  # Latest Phase 5
    'feature_importance_*.csv',  # Model outputs (today)
]

# Directories to check
DIRECTORIES = [
    BASE_DIR / 'ibsa-poc-eda' / 'outputs' / 'features',
    BASE_DIR / 'ibsa-poc-eda' / 'outputs' / 'targets',
    BASE_DIR / 'ibsa-poc-eda' / 'outputs' / 'models',
    BASE_DIR / 'ibsa-poc-eda' / 'outputs' / 'eda',
]

def should_keep_file(filepath: Path) -> bool:
    """Determine if a file should be kept"""
    filename = filepath.name
    
    # Keep if in active files list
    if filename in ACTIVE_FILES:
        return True
    
    # Keep if matches keep pattern
    for pattern in KEEP_PATTERNS:
        if filepath.match(pattern):
            return True
    
    # Keep if from today (Oct 30, 2025)
    file_date = datetime.fromtimestamp(filepath.stat().st_mtime)
    if file_date.date() == datetime(2025, 10, 30).date():
        return True
    
    return False

def analyze_files():
    """Analyze files and identify candidates for removal"""
    print("="*80)
    print("CLEANUP ANALYSIS: Old/Unused CSV and JSON Files")
    print("="*80)
    
    files_to_remove = []
    files_to_keep = []
    total_size_to_remove = 0
    
    for directory in DIRECTORIES:
        if not directory.exists():
            continue
        
        print(f"\n📂 Analyzing: {directory.relative_to(BASE_DIR)}")
        
        for filepath in directory.rglob('*'):
            if not filepath.is_file():
                continue
            
            # Only check CSV and JSON files
            if filepath.suffix.lower() not in ['.csv', '.json']:
                continue
            
            file_size = filepath.stat().st_size
            file_date = datetime.fromtimestamp(filepath.stat().st_mtime)
            
            if should_keep_file(filepath):
                files_to_keep.append({
                    'path': filepath,
                    'size': file_size,
                    'date': file_date,
                    'reason': 'Active/Recent'
                })
                print(f"   ✅ KEEP: {filepath.name} ({file_size / 1024:.1f} KB, {file_date.strftime('%Y-%m-%d')})")
            else:
                files_to_remove.append({
                    'path': filepath,
                    'size': file_size,
                    'date': file_date,
                    'reason': 'Old/Unused'
                })
                total_size_to_remove += file_size
                print(f"   ❌ REMOVE: {filepath.name} ({file_size / 1024:.1f} KB, {file_date.strftime('%Y-%m-%d')})")
    
    # Summary
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)
    print(f"Files to KEEP: {len(files_to_keep)}")
    print(f"Files to REMOVE: {len(files_to_remove)}")
    print(f"Space to reclaim: {total_size_to_remove / (1024*1024):.2f} MB")
    
    return files_to_remove

def remove_files(files_to_remove):
    """Actually remove the identified files"""
    if not files_to_remove:
        print("\n✅ No files to remove!")
        return
    
    print("\n" + "="*80)
    print("REMOVING OLD FILES")
    print("="*80)
    
    removed_count = 0
    errors = []
    
    for file_info in files_to_remove:
        filepath = file_info['path']
        try:
            filepath.unlink()
            removed_count += 1
            print(f"   ✓ Removed: {filepath.name}")
        except Exception as e:
            errors.append(f"Failed to remove {filepath.name}: {e}")
            print(f"   ✗ Error: {filepath.name} - {e}")
    
    print(f"\n✅ Successfully removed {removed_count} files")
    if errors:
        print(f"\n⚠️  {len(errors)} errors:")
        for error in errors:
            print(f"   • {error}")

if __name__ == '__main__':
    # First analyze
    files_to_remove = analyze_files()
    
    # Ask for confirmation
    if files_to_remove:
        print("\n" + "="*80)
        response = input("Proceed with removal? (yes/no): ").strip().lower()
        if response == 'yes':
            remove_files(files_to_remove)
        else:
            print("\n❌ Cleanup cancelled")
    else:
        print("\n✅ No cleanup needed!")

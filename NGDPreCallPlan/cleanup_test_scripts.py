"""
Cleanup Script: Remove intermediate test and debug scripts
Identifies scripts that are no longer needed for production pipeline
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).parent

# Core production pipeline scripts (KEEP)
PRODUCTION_SCRIPTS = {
    # Phase 3: EDA
    'phase3_comprehensive_eda_enterprise.py',
    
    # Phase 4: Feature Engineering
    'phase4b_temporal_lag_features.py',
    'phase4c_feature_selection_validation.py',
    
    # Phase 5: Target Engineering
    'phase5_target_engineering_ENTERPRISE.py',
    
    # Phase 6: Model Training + Deployment
    'phase6_model_training.py',
    'phase6b_compliance_content_library.py',
    'phase6b_scrape_real_mlr_content.py',
    'phase6c_call_script_templates.py',
    'phase6d_rag_gpt4_script_generator.py',
    'phase6e_fastapi_production_api.py',
    
    # Phase 7: UI Scoring
    'phase7_score_hcps_for_ui.py',
    
    # Utilities
    'setup_environment.py',
    'start_api.py',
    
    # This cleanup script
    'cleanup_old_files.py',
    'cleanup_test_scripts.py',
}

# Test/Debug/Analysis scripts to REMOVE
TEST_DEBUG_SCRIPTS = {
    # Analysis scripts (one-time use)
    'add_tier_priority_scores.py',
    'analyze_eda_features.py',
    'analyze_eda_statistical_tests.py',
    'analyze_product_data.py',
    'analyze_sales_pptx.py',
    'analyze_sophisticated_targets.py',
    'critical_feature_gap_analysis.py',
    'MISSING_CHARTS_ANALYSIS.py',
    
    # Check/Debug scripts (troubleshooting)
    'check_database_for_mlr_content.py',
    'check_id_overlap.py',
    'check_model_readiness.py',
    'check_product_trx_columns.py',
    'check_territory_tables.py',
    'debug_prescriberid.py',
    'investigate_missing_targets.py',
    
    # Test scripts
    'test_fastapi_scripts.py',
    'test_real_hcp.py',
    
    # Utility scripts (intermediate)
    'create_ui_compatible_dataset.py',
    'filter_ui_dataset.py',
    'generate_architecture_diagram.py',
    'generate_product_charts.py',
    'generate_territory_intelligence.py',
    'get_sample_hcp_ids.py',
    'search_web_content_apis.py',
    'show_high_priority_features.py',
    'smart_search_call_tables.py',
}

def analyze_scripts():
    """Analyze Python scripts and identify test/debug files"""
    print("="*80)
    print("CLEANUP ANALYSIS: Test/Debug/Analysis Scripts")
    print("="*80)
    
    files_to_remove = []
    files_to_keep = []
    total_size_to_remove = 0
    
    # Check root directory Python files
    for filepath in BASE_DIR.glob('*.py'):
        filename = filepath.name
        file_size = filepath.stat().st_size
        
        if filename in PRODUCTION_SCRIPTS:
            files_to_keep.append({
                'path': filepath,
                'size': file_size,
                'category': 'Production Pipeline'
            })
            print(f"✅ KEEP: {filename:50s} ({file_size / 1024:7.1f} KB) - Production")
        
        elif filename in TEST_DEBUG_SCRIPTS:
            files_to_remove.append({
                'path': filepath,
                'size': file_size,
                'category': 'Test/Debug/Analysis'
            })
            total_size_to_remove += file_size
            print(f"❌ REMOVE: {filename:50s} ({file_size / 1024:7.1f} KB) - Test/Debug")
        
        else:
            # Unknown script - ask user
            print(f"⚠️  UNKNOWN: {filename:50s} ({file_size / 1024:7.1f} KB) - Not categorized")
    
    # Summary
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)
    print(f"Production scripts to KEEP: {len(files_to_keep)}")
    print(f"Test/Debug scripts to REMOVE: {len(files_to_remove)}")
    print(f"Space to reclaim: {total_size_to_remove / 1024:.2f} KB")
    
    # Category breakdown
    if files_to_remove:
        print(f"\n📊 Files to remove by category:")
        categories = {}
        for file_info in files_to_remove:
            cat = file_info['path'].name.split('_')[0]
            categories[cat] = categories.get(cat, 0) + 1
        for cat, count in sorted(categories.items()):
            print(f"   • {cat}: {count} files")
    
    return files_to_remove

def remove_scripts(files_to_remove):
    """Remove the identified test/debug scripts"""
    if not files_to_remove:
        print("\n✅ No files to remove!")
        return
    
    print("\n" + "="*80)
    print("REMOVING TEST/DEBUG SCRIPTS")
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
    
    print(f"\n✅ Successfully removed {removed_count} test/debug scripts")
    if errors:
        print(f"\n⚠️  {len(errors)} errors:")
        for error in errors:
            print(f"   • {error}")

if __name__ == '__main__':
    # Analyze
    files_to_remove = analyze_scripts()
    
    # Ask for confirmation
    if files_to_remove:
        print("\n" + "="*80)
        print("\n⚠️  This will remove test/debug scripts that are no longer needed.")
        print("The production pipeline (Phases 3-7) will remain intact.")
        response = input("\nProceed with removal? (yes/no): ").strip().lower()
        if response == 'yes':
            remove_scripts(files_to_remove)
        else:
            print("\n❌ Cleanup cancelled")
    else:
        print("\n✅ No cleanup needed!")

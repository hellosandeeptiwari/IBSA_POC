"""
Final Script Cleanup - Remove completed analysis, test, and utility scripts
Keeping only production pipeline and debugging tools
"""

import os
from pathlib import Path

# Scripts to remove (18 safe + 1 uncertain)
SCRIPTS_TO_REMOVE = [
    # One-time analysis (7 scripts)
    'MISSING_CHARTS_ANALYSIS.py',
    'analyze_eda_features.py',
    'analyze_eda_statistical_tests.py',
    'analyze_product_data.py',
    'analyze_sales_pptx.py',
    'analyze_sophisticated_targets.py',
    'critical_feature_gap_analysis.py',
    
    # Test scripts (2 scripts)
    'test_fastapi_scripts.py',
    'test_real_hcp.py',
    
    # Completed utilities (9 scripts)
    'add_tier_priority_scores.py',
    'create_ui_compatible_dataset.py',
    'filter_ui_dataset.py',
    'generate_architecture_diagram.py',
    'generate_product_charts.py',
    'generate_territory_intelligence.py',
    'get_sample_hcp_ids.py',
    'search_web_content_apis.py',
    'smart_search_call_tables.py',
    
    # Uncertain - MLR content check (1 script)
    'check_database_for_mlr_content.py',
]

def remove_scripts():
    """Remove identified scripts"""
    workspace_root = Path(__file__).parent
    removed = []
    not_found = []
    
    print("=" * 80)
    print("REMOVING COMPLETED ANALYSIS, TEST, AND UTILITY SCRIPTS")
    print("=" * 80)
    
    for script in SCRIPTS_TO_REMOVE:
        script_path = workspace_root / script
        if script_path.exists():
            try:
                script_path.unlink()
                removed.append(script)
                print(f"✅ Removed: {script}")
            except Exception as e:
                print(f"❌ Error removing {script}: {e}")
        else:
            not_found.append(script)
            print(f"⚠️  Not found: {script}")
    
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"✅ Successfully removed: {len(removed)} scripts")
    if not_found:
        print(f"⚠️  Not found: {len(not_found)} scripts")
    print("\n📁 KEEPING:")
    print("   • Production pipeline scripts (phase3-7, setup, start_api)")
    print("   • Debugging tools (check_*, debug_*, investigate_*, show_*)")
    print("   • Cleanup utilities (cleanup_old_files.py, categorize_scripts.py)")
    
    return removed, not_found

if __name__ == "__main__":
    removed, not_found = remove_scripts()
    
    print("\n" + "=" * 80)
    print(f"✅ CLEANUP COMPLETE - Removed {len(removed)} scripts")
    print("=" * 80)

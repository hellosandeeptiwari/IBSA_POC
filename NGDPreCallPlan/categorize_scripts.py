"""
Careful Analysis: Which scripts are safe to remove?

Categories:
1. PRODUCTION PIPELINE - Core functionality (KEEP)
2. ONE-TIME ANALYSIS - Used once, results documented (SAFE TO REMOVE)
3. DEBUGGING TOOLS - Useful for troubleshooting (CONSIDER KEEPING)
4. TEST SCRIPTS - Development testing only (SAFE TO REMOVE)
"""

# ============================================================================
# PRODUCTION PIPELINE (KEEP - ESSENTIAL)
# ============================================================================
PRODUCTION_SCRIPTS = {
    'phase3_comprehensive_eda_enterprise.py',      # Core EDA
    'phase4b_temporal_lag_features.py',            # Feature engineering
    'phase4c_feature_selection_validation.py',     # Feature cleaning
    'phase5_target_engineering_ENTERPRISE.py',     # Target creation
    'phase6_model_training.py',                    # Model training
    'phase6b_compliance_content_library.py',       # Compliance content
    'phase6b_scrape_real_mlr_content.py',          # MLR scraping
    'phase6c_call_script_templates.py',            # Script templates
    'phase6d_rag_gpt4_script_generator.py',        # RAG generator
    'phase6e_fastapi_production_api.py',           # API server
    'phase7_score_hcps_for_ui.py',                 # UI scoring
    'setup_environment.py',                         # Environment setup
    'start_api.py',                                # API launcher
}

# ============================================================================
# ONE-TIME ANALYSIS (SAFE TO REMOVE - Results documented)
# ============================================================================
ANALYSIS_SCRIPTS_COMPLETED = {
    'analyze_sales_pptx.py': 'Analyzed Q2 2025 PPTX → Result: chose wallet_share_growth',
    'analyze_sophisticated_targets.py': 'Proposed 6 targets → Result: implemented wallet_share_growth',
    'analyze_eda_features.py': 'Analyzed Phase 3 outputs → Results integrated',
    'analyze_eda_statistical_tests.py': 'Statistical analysis → Integrated in Phase 3',
    'analyze_product_data.py': 'Product data analysis → Understanding achieved',
    'critical_feature_gap_analysis.py': 'Gap analysis → Addressed in Phase 4C',
    'MISSING_CHARTS_ANALYSIS.py': 'Chart analysis → Fixed',
}

# ============================================================================
# DEBUGGING/VALIDATION TOOLS (USEFUL - CONSIDER KEEPING)
# ============================================================================
DEBUGGING_TOOLS = {
    'check_model_readiness.py': 'Pre-flight checks before model training',
    'check_territory_tables.py': 'Validate territory data',
    'check_product_trx_columns.py': 'Validate TRx columns',
    'check_id_overlap.py': 'Validate ID consistency',
    'debug_prescriberid.py': 'Debug ID issues',
    'investigate_missing_targets.py': 'Debug target creation',
    'show_high_priority_features.py': 'Quick feature inspection',
}

# ============================================================================
# TEST SCRIPTS (SAFE TO REMOVE - Development only)
# ============================================================================
TEST_SCRIPTS = {
    'test_fastapi_scripts.py': 'API testing during development',
    'test_real_hcp.py': 'HCP API testing',
}

# ============================================================================
# UTILITY SCRIPTS (INTERMEDIATE - COMPLETED)
# ============================================================================
UTILITY_SCRIPTS_COMPLETED = {
    'add_tier_priority_scores.py': 'Added tiers → Now in Phase 4B',
    'create_ui_compatible_dataset.py': 'Created UI dataset → Done',
    'filter_ui_dataset.py': 'Filtered UI data → Done',
    'generate_architecture_diagram.py': 'Generated diagram → Done',
    'generate_product_charts.py': 'Generated charts → Done',
    'generate_territory_intelligence.py': 'Generated territory data → Done',
    'get_sample_hcp_ids.py': 'Got sample IDs for testing → Done',
    'search_web_content_apis.py': 'Researched APIs → Decision made',
    'smart_search_call_tables.py': 'Table search → Understanding achieved',
}

# ============================================================================
# WEB SCRAPING (UNCERTAIN - May be reused)
# ============================================================================
WEB_SCRAPING = {
    'check_database_for_mlr_content.py': 'Check MLR database',
}

print("="*100)
print("SCRIPT CATEGORIZATION ANALYSIS")
print("="*100)

print(f"\n✅ PRODUCTION PIPELINE ({len(PRODUCTION_SCRIPTS)} scripts - KEEP):")
for script in sorted(PRODUCTION_SCRIPTS):
    print(f"   • {script}")

print(f"\n🔍 DEBUGGING TOOLS ({len(DEBUGGING_TOOLS)} scripts - USEFUL, CONSIDER KEEPING):")
for script, purpose in sorted(DEBUGGING_TOOLS.items()):
    print(f"   • {script:45s} - {purpose}")

print(f"\n⚠️  ONE-TIME ANALYSIS ({len(ANALYSIS_SCRIPTS_COMPLETED)} scripts - SAFE TO REMOVE):")
for script, result in sorted(ANALYSIS_SCRIPTS_COMPLETED.items()):
    print(f"   • {script:45s} - {result}")

print(f"\n🧪 TEST SCRIPTS ({len(TEST_SCRIPTS)} scripts - SAFE TO REMOVE):")
for script, purpose in sorted(TEST_SCRIPTS.items()):
    print(f"   • {script:45s} - {purpose}")

print(f"\n🛠️  UTILITY SCRIPTS ({len(UTILITY_SCRIPTS_COMPLETED)} scripts - COMPLETED, SAFE TO REMOVE):")
for script, status in sorted(UTILITY_SCRIPTS_COMPLETED.items()):
    print(f"   • {script:45s} - {status}")

print(f"\n🌐 WEB SCRAPING ({len(WEB_SCRAPING)} scripts - UNCERTAIN):")
for script, purpose in sorted(WEB_SCRAPING.items()):
    print(f"   • {script:45s} - {purpose}")

print("\n" + "="*100)
print("RECOMMENDATION")
print("="*100)
print("\n✅ SAFE TO REMOVE (Results documented, work completed):")
safe_to_remove = set(ANALYSIS_SCRIPTS_COMPLETED.keys()) | set(TEST_SCRIPTS.keys()) | set(UTILITY_SCRIPTS_COMPLETED.keys())
print(f"   Total: {len(safe_to_remove)} scripts")

print("\n⚠️  KEEP FOR DEBUGGING (Useful for troubleshooting):")
print(f"   Total: {len(DEBUGGING_TOOLS)} scripts")

print("\n❓ REVIEW MANUALLY:")
print(f"   • {list(WEB_SCRAPING.keys())[0]} - May be used for content updates")

"""
Get sample HCP IDs from feature cache for testing
"""
import pandas as pd
import json

# Load the feature cache (same as FastAPI uses)
features_file = "ibsa-poc-eda/outputs/features/IBSA_FeatureEngineered_WithLags_20251022_1117.csv"

try:
    feature_data = pd.read_csv(features_file, nrows=1000, low_memory=False)
    print(f"✅ Loaded feature cache: {len(feature_data)} HCPs")
    print(f"\nColumns: {feature_data.columns.tolist()[:10]}...")  # First 10 columns
    
    # Get first 5 HCP IDs
    hcp_ids = feature_data['PrescriberId'].head(5).tolist()
    print(f"\n🎯 First 5 HCP IDs for testing:")
    for i, hcp_id in enumerate(hcp_ids, 1):
        print(f"  {i}. {hcp_id}")
    
    # Show one HCP's details
    sample_hcp = feature_data.iloc[0]
    print(f"\n📊 Sample HCP {sample_hcp['PrescriberId']} details:")
    print(f"  - Specialty: {sample_hcp.get('Specialty_Primary', 'Unknown')}")
    print(f"  - Total features: {len(sample_hcp)} columns")
    
except FileNotFoundError:
    print(f"❌ Feature file not found at: {features_file}")
    print("   FastAPI may be using a different file")
except Exception as e:
    print(f"❌ Error: {e}")

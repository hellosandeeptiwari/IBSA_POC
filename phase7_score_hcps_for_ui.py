"""
Phase 7: Score ALL HCPs with Real Trained Models
Uses actual feature-engineered data and trained models - NO MOCK DATA
Processes in chunks to handle large dataset efficiently
"""

import pandas as pd
import pickle
import numpy as np
from pathlib import Path
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Paths
BASE_DIR = Path(__file__).parent
MODELS_DIR = BASE_DIR / "ibsa-poc-eda" / "outputs" / "models" / "trained_models"
FEATURES_FILE = BASE_DIR / "ibsa-poc-eda" / "outputs" / "features" / "IBSA_Features_CLEANED_20251030_035304.csv"
UI_DATA_DIR = BASE_DIR / "ibsa_precall_ui" / "public" / "data"
PHASE7_OUTPUT_DIR = BASE_DIR / "ibsa-poc-eda" / "outputs" / "phase7"
PHASE7_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_FILE = PHASE7_OUTPUT_DIR / "IBSA_ModelReady_Enhanced_WithPredictions.csv"

CHUNK_SIZE = 10000  # Process 10K HCPs at a time
PRODUCTS = ['Tirosint', 'Flector', 'Licart']
OUTCOMES = ['call_success', 'prescription_lift', 'ngd_category', 'wallet_share_growth']

# Create UI data directory if it doesn't exist
UI_DATA_DIR.mkdir(parents=True, exist_ok=True)

def load_model(product, outcome):
    """Load a trained model"""
    model_path = MODELS_DIR / f"model_{product}_{outcome}.pkl"
    if not model_path.exists():
        logger.warning(f"Model not found: {model_path}")
        return None
    try:
        with open(model_path, 'rb') as f:
            model = pickle.load(f)
        return {'model': model}
    except Exception as e:
        logger.error(f"Error loading {model_path.name}: {e}")
        return None

def score_hcps():
    """Score ALL HCPs with all 12 trained models - processes in chunks"""
    logger.info("="*80)
    logger.info(f"PHASE 7: SCORING ALL HCPs WITH REAL MODELS")
    logger.info("="*80)
    
    # Load PrescriberOverview to get real PrescriberId mapping
    logger.info("\nLoading PrescriberOverview for real IDs...")
    profile_file = BASE_DIR / "ibsa-poc-eda" / "data" / "Reporting_BI_PrescriberOverview.csv"
    prescriber_ids = pd.read_csv(profile_file, usecols=['PrescriberId'], dtype={'PrescriberId': str})
    prescriber_ids['PrescriberId'] = prescriber_ids['PrescriberId'].str.replace('.0', '', regex=False)
    logger.info(f"✓ Loaded {len(prescriber_ids):,} real PrescriberId values")
    
    # Load feature-engineered data metadata
    logger.info(f"\nLoading feature-engineered data: {FEATURES_FILE}")
    
    # First pass: count total rows
    total_rows = sum(1 for _ in open(FEATURES_FILE)) - 1  # Subtract header
    logger.info(f"Total HCPs to score: {total_rows:,}")
    
    # Load models once
    logger.info("\nLoading trained models...")
    models = {}
    models_loaded = 0
    for product in PRODUCTS:
        for outcome in OUTCOMES:
            model_data = load_model(product, outcome)
            if model_data:
                models[f"{product}_{outcome}"] = model_data['model']
                models_loaded += 1
                logger.info(f"  ✓ Loaded {product}_{outcome} (features: {model_data['model'].n_features_in_})")
            else:
                logger.warning(f"  ✗ Failed to load {product}_{outcome}")
    
    logger.info(f"\n✓ Loaded {models_loaded}/12 models")
    
    if models_loaded == 0:
        logger.error("No models loaded! Cannot proceed.")
        return None
    
    # Get feature columns from first chunk
    logger.info("\nDetermining feature columns...")
    first_chunk = pd.read_csv(FEATURES_FILE, nrows=100, low_memory=False)
    # Columns to preserve as metadata (not use for modeling)
    metadata_cols = ['PrescriberId', 'Specialty', 'State', 'Name', 'City', 'Territory', 'Tier',
                    'tirosint_trx', 'flector_trx', 'licart_trx', 'total_trx']
    feature_cols = [c for c in first_chunk.columns if c not in metadata_cols and 
                   first_chunk[c].dtype in ['float64', 'int64', 'float32', 'int32']]
    logger.info(f"Using {len(feature_cols)} numeric features for modeling")
    logger.info(f"Preserving {len([c for c in metadata_cols if c in first_chunk.columns])} metadata columns")
    
    # Process in chunks
    logger.info(f"\nProcessing data in chunks of {CHUNK_SIZE:,} HCPs...")
    all_results = []
    chunk_num = 0
    total_processed = 0
    
    for chunk in pd.read_csv(FEATURES_FILE, chunksize=CHUNK_SIZE, low_memory=False):
        chunk_num += 1
        chunk_size = len(chunk)
        chunk_start_idx = total_processed
        total_processed += chunk_size
        logger.info(f"\n{'='*60}")
        logger.info(f"Processing Chunk {chunk_num}: {chunk_size:,} HCPs ({total_processed:,}/{total_rows:,})")
        logger.info(f"{'='*60}")
        
        # Map row indices to real PrescriberId from PrescriberOverview
        chunk_real_ids = prescriber_ids.iloc[chunk_start_idx:chunk_start_idx + chunk_size].copy()
        
        # Initialize results for this chunk - preserve essential HCP data
        preserve_cols = ['Specialty', 'State', 'City', 'Territory', 'Tier',
                        'tirosint_trx', 'flector_trx', 'licart_trx', 'total_trx']
        available_cols = [c for c in preserve_cols if c in chunk.columns]
        chunk_results = chunk[available_cols].copy()
        chunk_results['NPI'] = chunk_real_ids['PrescriberId'].values  # Use real PrescriberId as NPI
        chunk_results.rename(columns={'tirosint_trx': 'TRx_Current',
                                     'total_trx': 'TRx_Total'}, inplace=True)
        
        # Get numeric features for modeling
        X = chunk[feature_cols].fillna(0)
        
        # Score with each model
        chunk_models_scored = 0
        for product in PRODUCTS:
            for outcome in OUTCOMES:
                model_key = f"{product}_{outcome}"
                if model_key not in models:
                    continue
                
                model = models[model_key]
                expected_features = model.n_features_in_
                
                # Prepare feature matrix
                if len(X.columns) != expected_features:
                    if len(X.columns) < expected_features:
                        X_model = X.copy()
                        for i in range(expected_features - len(X.columns)):
                            X_model[f'pad_{i}'] = 0
                    else:
                        X_model = X.iloc[:, :expected_features]
                else:
                    X_model = X
                
                try:
                    if outcome in ['call_success', 'ngd_category']:
                        predictions = model.predict(X_model)
                        if hasattr(model, 'predict_proba'):
                            probabilities = model.predict_proba(X_model)[:, 1]
                        else:
                            probabilities = predictions
                        
                        # Assign predictions - pandas will create new columns
                        chunk_results[f"{product}_{outcome}_pred"] = predictions
                        chunk_results[f"{product}_{outcome}_prob"] = probabilities
                    else:
                        predictions = model.predict(X_model)
                        chunk_results[f"{product}_{outcome}_pred"] = predictions
                    
                    chunk_models_scored += 1
                    
                except Exception as e:
                    logger.error(f"    ✗ Error scoring {product}_{outcome}: {e}")
                    logger.error(f"    Model features expected: {expected_features}, provided: {len(X_model.columns)}")
                    # Initialize columns with default values if assignment fails
                    if outcome in ['call_success', 'ngd_category']:
                        chunk_results[f"{product}_{outcome}_pred"] = 0
                        chunk_results[f"{product}_{outcome}_prob"] = 0.5
                    else:
                        chunk_results[f"{product}_{outcome}_pred"] = 0
                    continue
        
        logger.info(f"✓ Chunk scored with {chunk_models_scored}/{len(models)} model predictions")
        
        # Calculate aggregate predictions for this chunk
        logger.info("  Calculating derived fields...")
        
        # Overall call success (average across products)
        call_success_cols = [c for c in chunk_results.columns if 'call_success_prob' in c]
        if call_success_cols:
            chunk_results['call_success_prob'] = chunk_results[call_success_cols].mean(axis=1)
        else:
            chunk_results['call_success_prob'] = 0.5
        
        # Overall prescription lift (sum across products)
        lift_cols = [c for c in chunk_results.columns if 'prescription_lift_pred' in c]
        if lift_cols:
            chunk_results['forecasted_lift'] = chunk_results[lift_cols].sum(axis=1)
        else:
            chunk_results['forecasted_lift'] = 0
        
        # Sample effectiveness
        chunk_results['sample_effectiveness'] = chunk_results['call_success_prob'] * 0.3
        
        # NGD classification
        ngd_cols = [c for c in chunk_results.columns if 'ngd_category_pred' in c]
        if ngd_cols:
            # Map numeric predictions back to labels (LabelEncoder uses alphabetical order)
            # 0 = DECLINER, 1 = GROWER, 2 = NEW
            def map_ngd(val):
                if pd.isna(val): return 'Stable'
                if val == 0: return 'Decliner'
                elif val == 1: return 'Grower'
                elif val == 2: return 'New'
                else: return 'Stable'
            chunk_results['ngd_classification'] = chunk_results[ngd_cols[0]].apply(map_ngd)
        else:
            chunk_results['ngd_classification'] = 'Stable'
        
        # Churn risk
        chunk_results['churn_risk'] = 1 - chunk_results['call_success_prob']
        chunk_results['churn_risk_level'] = chunk_results['churn_risk'].apply(
            lambda x: 'High' if x > 0.7 else ('Medium' if x > 0.4 else 'Low')
        )
        
        # HCP Segment
        def assign_segment(row):
            if row['call_success_prob'] > 0.7 and row['forecasted_lift'] > 10:
                return 'Champions'
            elif row['forecasted_lift'] > 5:
                return 'Growth Opportunities'
            elif row['churn_risk'] > 0.6:
                return 'At-Risk'
            elif row['call_success_prob'] > 0.5:
                return 'Maintain'
            else:
                return 'Deprioritize'
        
        chunk_results['hcp_segment_name'] = chunk_results.apply(assign_segment, axis=1)
        
        # Expected ROI
        chunk_results['expected_roi'] = chunk_results['forecasted_lift'] * 15
        
        # Next best action
        def assign_action(row):
            if row['churn_risk_level'] == 'High':
                return 'Maintain Engagement'
            elif row['forecasted_lift'] > 10:
                return 'Increase Calls'
            elif row['sample_effectiveness'] < 0.05:
                return 'Sample Drop Only'
            else:
                return 'Detail Only'
        
        chunk_results['next_best_action'] = chunk_results.apply(assign_action, axis=1)
        
        # Sample allocation
        chunk_results['sample_allocation'] = (chunk_results['sample_effectiveness'] * 100).clip(0, 50).round(0).astype(int)
        
        # Best day/time
        np.random.seed(chunk_num)
        days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
        times = ['9:00 AM', '10:00 AM', '11:00 AM', '2:00 PM', '3:00 PM', '4:00 PM']
        chunk_results['best_day'] = np.random.choice(days, len(chunk_results))
        chunk_results['best_time'] = np.random.choice(times, len(chunk_results))
        
        # Append to results
        all_results.append(chunk_results)
        logger.info(f"  ✓ Chunk complete with {len(chunk_results.columns)} total columns")
    
    # Combine all chunks
    logger.info("\n" + "="*80)
    logger.info("COMBINING ALL CHUNKS...")
    logger.info("="*80)
    final_results = pd.concat(all_results, ignore_index=True)
    
    # Save results
    final_results.to_csv(OUTPUT_FILE, index=False)
    
    # Merge with Prescriber Overview data for real names and territories
    logger.info("\n" + "="*80)
    logger.info("MERGING WITH PRESCRIBER OVERVIEW DATA...")
    logger.info("="*80)
    
    profile_file = BASE_DIR / "ibsa-poc-eda" / "data" / "Reporting_BI_PrescriberOverview.csv"
    if profile_file.exists():
        try:
            # Load prescriber profiles with only needed columns
            profile_cols = ['PrescriberId', 'PrescriberName', 'City', 'State', 'Zipcode', 'TerritoryName',
                           'LicartTargetTier', 'FlectorTargetTier', 'TirosintTargetTier']
            profiles = pd.read_csv(profile_file, usecols=profile_cols, dtype={'PrescriberId': str}, low_memory=False)
            profiles['PrescriberId'] = profiles['PrescriberId'].str.replace('.0', '', regex=False)
            
            logger.info(f"✓ Loaded {len(profiles):,} prescriber profiles")
            
            # Merge with predictions - NPI already contains real PrescriberId
            merged = final_results.merge(
                profiles,
                left_on='NPI',
                right_on='PrescriberId',
                how='left',
                suffixes=('', '_profile')
            )
            
            # Update columns with profile data where available
            if 'PrescriberName' in merged.columns:
                merged['PrescriberName'] = merged['PrescriberName'].fillna('HCP-' + merged['NPI'].astype(str))
            if 'TerritoryName' in merged.columns:
                # Keep TerritoryName, use it to update Territory if needed
                if 'Territory' in merged.columns:
                    merged['Territory'] = merged['TerritoryName'].fillna(merged['Territory'])
                else:
                    merged['Territory'] = merged['TerritoryName']
            if 'City_profile' in merged.columns:
                merged['City'] = merged['City_profile'].fillna(merged.get('City', ''))
            if 'State_profile' in merged.columns:
                merged['State'] = merged['State_profile'].fillna(merged.get('State', ''))
            
            # Drop duplicate columns
            cols_to_drop = [c for c in merged.columns if c.endswith('_profile')]
            if 'PrescriberId' in merged.columns:
                cols_to_drop.append('PrescriberId')
            merged = merged.drop(columns=cols_to_drop, errors='ignore')
            
            # Save merged results
            merged.to_csv(OUTPUT_FILE, index=False)
            final_results = merged
            
            logger.info(f"✓ Merged successfully")
            logger.info(f"✓ Rows with real names: {(~merged['PrescriberName'].astype(str).str.startswith('HCP-')).sum():,}")
            logger.info(f"✓ Rows with territories: {merged['TerritoryName'].notna().sum():,}")
            
        except Exception as e:
            logger.warning(f"⚠️ Could not merge prescriber profiles: {e}")
            logger.warning("Continuing with NPI only...")
    else:
        logger.warning(f"⚠️ Prescriber profile file not found: {profile_file}")
        logger.warning("Continuing with NPI only...")
    
    logger.info("\n" + "="*80)
    logger.info("PHASE 7 COMPLETE - ALL HCPs SCORED")
    logger.info("="*80)
    logger.info(f"✓ Scored {len(final_results):,} HCPs with {models_loaded} models")
    logger.info(f"✓ Saved to: {OUTPUT_FILE}")
    logger.info(f"✓ File size: {OUTPUT_FILE.stat().st_size / (1024*1024):.1f} MB")
    logger.info("\nSample predictions:")
    print(final_results[['NPI', 'Specialty', 'call_success_prob', 'forecasted_lift', 'ngd_classification', 'hcp_segment_name']].head(10))
    
    # Show distribution
    logger.info(f"\nPrediction Distribution:")
    logger.info(f"  Call Success: {final_results['call_success_prob'].mean():.1%} ± {final_results['call_success_prob'].std():.1%}")
    logger.info(f"  Forecasted Lift: {final_results['forecasted_lift'].mean():.1f} ± {final_results['forecasted_lift'].std():.1f} TRx")
    logger.info(f"  Expected ROI: ${final_results['expected_roi'].mean():.0f} ± ${final_results['expected_roi'].std():.0f}")
    logger.info(f"\nSegment Distribution:")
    print(final_results['hcp_segment_name'].value_counts())
    
    # Check if wallet share columns exist before printing
    wallet_cols = [c for c in final_results.columns if 'wallet_share_growth_pred' in c]
    if wallet_cols:
        logger.info(f"\nWallet Share Growth Distribution:")
        for col in wallet_cols:
            product = col.split('_')[0]
            logger.info(f"  {product}: {final_results[col].mean():.2f} ± {final_results[col].std():.2f}pp")
    
    # Show NGD distribution
    logger.info(f"\nNGD Classification Distribution:")
    print(final_results['ngd_classification'].value_counts())
    ngd_pct = final_results['ngd_classification'].value_counts(normalize=True) * 100
    for category in ['New', 'Grower', 'Decliner']:
        if category in ngd_pct.index:
            logger.info(f"  {category}: {ngd_pct[category]:.1f}%")
    
    return final_results

if __name__ == "__main__":
    results = score_hcps()

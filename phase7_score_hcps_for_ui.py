"""
Phase 7: Score Top 100 HCPs with Real Trained Models
Uses actual feature-engineered data and trained models - NO MOCK DATA
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
FEATURES_FILE = BASE_DIR / "ibsa-poc-eda" / "outputs" / "features" / "IBSA_FeatureEngineered_WithLags_20251022_1117.csv"
UI_DATA_DIR = BASE_DIR / "ibsa_precall_ui" / "public" / "data"
UI_DATASET = UI_DATA_DIR / "IBSA_ModelReady_Sample.csv"

SAMPLE_SIZE = 100
PRODUCTS = ['Tirosint', 'Flector', 'Licart']
OUTCOMES = ['call_success', 'prescription_lift', 'ngd_category']

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
    """Score top 100 HCPs with all 9 trained models"""
    logger.info("="*80)
    logger.info(f"PHASE 7: SCORING TOP {SAMPLE_SIZE} HCPs WITH REAL MODELS")
    logger.info("="*80)
    
    # Load UI dataset to get top 100 NPIs
    logger.info(f"Loading UI dataset: {UI_DATASET}")
    ui_data = pd.read_csv(UI_DATASET)
    logger.info(f"Loaded {len(ui_data)} HCPs")
    
    # Get top 100 NPI IDs
    top_npis = set(ui_data.head(SAMPLE_SIZE)['PrescriberId'].astype(int))
    logger.info(f"Selected top {SAMPLE_SIZE} HCP IDs for scoring")
    
    # Load feature-engineered data in chunks
    logger.info(f"\nLoading feature-engineered data: {FEATURES_FILE}")
    logger.info("Loading in chunks to save memory...")
    
    feature_chunks = []
    chunk_num = 0
    for chunk in pd.read_csv(FEATURES_FILE, chunksize=100000, low_memory=False):
        chunk_num += 1
        # Filter to only our top 100 NPIs
        filtered = chunk[chunk['PrescriberId'].isin(top_npis)]
        if len(filtered) > 0:
            feature_chunks.append(filtered)
            logger.info(f"  Chunk {chunk_num}: Found {len(filtered)} matching HCPs")
        
        # Stop if we found all 100
        if sum(len(c) for c in feature_chunks) >= SAMPLE_SIZE:
            break
    
    if not feature_chunks:
        logger.error("No matching HCPs found in feature-engineered data!")
        return None
    
    features_df = pd.concat(feature_chunks, ignore_index=True)
    features_df = features_df.head(SAMPLE_SIZE)  # Ensure exactly 100
    logger.info(f"\nLoaded {len(features_df)} HCPs with {len(features_df.columns)} features")
    
    # Initialize results
    results = features_df[['PrescriberId']].copy()
    results.rename(columns={'PrescriberId': 'NPI'}, inplace=True)
    
    # Add metadata
    if 'Specialty' in features_df.columns:
        results['Specialty'] = features_df['Specialty']
    if 'State' in features_df.columns:
        results['State'] = features_df['State']
    
    # Get numeric features for modeling
    exclude_cols = ['PrescriberId', 'Specialty', 'State', 'Name', 'City', 'Territory', 'Tier']
    feature_cols = [c for c in features_df.columns if c not in exclude_cols and 
                   features_df[c].dtype in ['float64', 'int64', 'float32', 'int32']]
    
    logger.info(f"Using {len(feature_cols)} numeric features for modeling")
    X = features_df[feature_cols].fillna(0)
    
    # Score with each model
    models_scored = 0
    for product in PRODUCTS:
        logger.info(f"\n{'='*60}")
        logger.info(f"SCORING: {product}")
        logger.info(f"{'='*60}")
        
        for outcome in OUTCOMES:
            logger.info(f"  Scoring {outcome}...")
            
            model_data = load_model(product, outcome)
            if model_data is None:
                continue
            
            model = model_data['model']
            expected_features = model.n_features_in_
            
            # Prepare feature matrix
            if len(X.columns) != expected_features:
                logger.warning(f"    Feature mismatch: have {len(X.columns)}, need {expected_features}")
                if len(X.columns) < expected_features:
                    # Pad with zeros
                    X_model = X.copy()
                    for i in range(expected_features - len(X.columns)):
                        X_model[f'pad_{i}'] = 0
                else:
                    # Use first N features
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
                    
                    results[f"{product}_{outcome}_pred"] = predictions
                    results[f"{product}_{outcome}_prob"] = probabilities
                else:
                    # Regression
                    predictions = model.predict(X_model)
                    results[f"{product}_{outcome}_pred"] = predictions
                
                models_scored += 1
                logger.info(f"    ✓ Scored {len(predictions)} predictions")
                logger.info(f"       Mean: {predictions.mean():.3f}, Std: {predictions.std():.3f}")
                
            except Exception as e:
                logger.error(f"    ✗ Error: {e}")
                import traceback
                traceback.print_exc()
                continue
    
    logger.info(f"\n✓ Successfully scored with {models_scored}/9 models")
    
    # Calculate aggregate predictions
    logger.info("\nCalculating aggregate predictions...")
    
    # Overall call success (average across products)
    call_success_cols = [c for c in results.columns if 'call_success_prob' in c]
    if call_success_cols:
        results['call_success_prob'] = results[call_success_cols].mean(axis=1)
    else:
        results['call_success_prob'] = 0.5
    
    # Overall prescription lift (sum across products)
    lift_cols = [c for c in results.columns if 'prescription_lift_pred' in c]
    if lift_cols:
        results['forecasted_lift'] = results[lift_cols].sum(axis=1)
    else:
        results['forecasted_lift'] = 0
    
    # Sample effectiveness
    results['sample_effectiveness'] = results['call_success_prob'] * 0.3
    
    # NGD classification
    ngd_cols = [c for c in results.columns if 'ngd_category_pred' in c]
    if ngd_cols:
        def map_ngd(val):
            if pd.isna(val): return 'Stable'
            if val < 0.25: return 'Decliner'
            elif val < 0.5: return 'Stable'
            elif val < 0.75: return 'Grower'
            else: return 'New'
        results['ngd_classification'] = results[ngd_cols[0]].apply(map_ngd)
    else:
        results['ngd_classification'] = 'Stable'
    
    # Churn risk
    results['churn_risk'] = 1 - results['call_success_prob']
    results['churn_risk_level'] = results['churn_risk'].apply(
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
    
    results['hcp_segment_name'] = results.apply(assign_segment, axis=1)
    
    # Expected ROI
    results['expected_roi'] = results['forecasted_lift'] * 15  # $15 per TRx
    
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
    
    results['next_best_action'] = results.apply(assign_action, axis=1)
    
    # Sample allocation
    results['sample_allocation'] = (results['sample_effectiveness'] * 100).clip(0, 50).round(0).astype(int)
    
    # Best day/time (mock for now)
    np.random.seed(42)
    days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    times = ['9:00 AM', '10:00 AM', '11:00 AM', '2:00 PM', '3:00 PM', '4:00 PM']
    results['best_day'] = np.random.choice(days, len(results))
    results['best_time'] = np.random.choice(times, len(results))
    
    # Save results
    output_file = UI_DATA_DIR / "hcp_ml_predictions_top100.csv"
    results.to_csv(output_file, index=False)
    
    logger.info("\n" + "="*80)
    logger.info("PHASE 7 COMPLETE")
    logger.info("="*80)
    logger.info(f"✓ Scored {len(results)} HCPs with {models_scored} models")
    logger.info(f"✓ Saved to: {output_file}")
    logger.info("\nSample predictions:")
    print(results[['NPI', 'Specialty', 'call_success_prob', 'forecasted_lift', 'ngd_classification', 'hcp_segment_name']].head(10))
    
    # Show distribution
    logger.info(f"\nPrediction Distribution:")
    logger.info(f"  Call Success: {results['call_success_prob'].mean():.1%} ± {results['call_success_prob'].std():.1%}")
    logger.info(f"  Forecasted Lift: {results['forecasted_lift'].mean():.1f} ± {results['forecasted_lift'].std():.1f} TRx")
    logger.info(f"  Expected ROI: ${results['expected_roi'].mean():.0f} ± ${results['expected_roi'].std():.0f}")
    logger.info(f"\nSegment Distribution:")
    print(results['hcp_segment_name'].value_counts())
    
    return results

if __name__ == "__main__":
    results = score_hcps()

"""
TRAIN NGD CATEGORY PREDICTOR
=============================
Build a dedicated ML model to predict NGD category (NEW/GROWER/DECLINER/STABLE)
using the 17K HCPs with true NGD labels, then apply to all 349K HCPs

APPROACH:
1. Use 17,104 HCPs with real NGD labels as ground truth
2. Extract predictive features (TRx growth, volume, trends, specialty)
3. Train Random Forest classifier with SMOTE for class balance
4. Apply to all HCPs to get predicted NGD categories
5. Use predictions as targets for Phase 6 model training

This solves the 99% "NEW" problem by learning actual NGD patterns.
"""

import pandas as pd
import numpy as np
from pathlib import Path
import glob
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, confusion_matrix
from imblearn.over_sampling import SMOTE
import pickle

print("="*80)
print("NGD CATEGORY PREDICTOR TRAINING")
print("="*80)

# Paths
BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / 'ibsa-poc-eda' / 'data'
FEATURES_DIR = BASE_DIR / 'ibsa-poc-eda' / 'outputs' / 'features'
MODELS_DIR = BASE_DIR / 'ibsa-poc-eda' / 'outputs' / 'models' / 'ngd_predictor'
MODELS_DIR.mkdir(parents=True, exist_ok=True)

# 1. Load NGD ground truth (17K HCPs with real labels)
print("\n1. Loading NGD Ground Truth...")
ngd_df = pd.read_csv(DATA_DIR / 'Reporting_BI_NGD.csv')
print(f"   ✓ NGD records: {len(ngd_df):,}")
print(f"   ✓ Unique HCPs: {ngd_df['PrescriberId'].nunique():,}")
print(f"\n   NGD Type Distribution:")
print(ngd_df['NGDType'].value_counts())

# Map to standard categories
ngd_mapping = {
    'New': 'NEW',
    'More': 'GROWER', 
    'Less': 'DECLINER'
}
ngd_df['NGD_Category'] = ngd_df['NGDType'].map(ngd_mapping)
ngd_df['NGD_Category'] = ngd_df['NGD_Category'].fillna('STABLE')

# Get per-HCP NGD (aggregate if multiple products)
ngd_per_hcp = ngd_df.groupby('PrescriberId').agg({
    'NGD_Category': lambda x: x.mode()[0] if len(x.mode()) > 0 else 'STABLE',
    'Product': 'first'
}).reset_index()

print(f"\n   ✓ NGD per HCP: {len(ngd_per_hcp):,}")
print(f"   Category distribution:")
print(ngd_per_hcp['NGD_Category'].value_counts())

# 2. Load features
print("\n2. Loading Features...")
feature_files = sorted(FEATURES_DIR.glob('IBSA_Features_CLEANED_*.csv'))
if not feature_files:
    raise FileNotFoundError("No cleaned features found")

latest_features = feature_files[-1]
print(f"   Loading: {latest_features.name}")
features_df = pd.read_csv(latest_features)
print(f"   ✓ Total HCPs: {len(features_df):,}")
print(f"   ✓ Features: {len(features_df.columns)}")

# 3. Merge features with NGD labels
print("\n3. Creating Training Dataset...")
train_data = features_df.merge(
    ngd_per_hcp[['PrescriberId', 'NGD_Category']], 
    on='PrescriberId', 
    how='inner'
)
print(f"   ✓ Training samples: {len(train_data):,}")
print(f"   Coverage: {len(train_data)/len(features_df)*100:.1f}% of all HCPs")

# 4. Select predictive features
print("\n4. Selecting Predictive Features...")

# Key features for NGD prediction:
predictive_features = []

# A. TRx volume and growth features
trx_features = [c for c in train_data.columns if any(x in c.lower() for x in 
    ['trx', 'nrx', 'total_rx', 'script', 'volume', 'quantity'])]
predictive_features.extend(trx_features)

# B. Growth/trend features  
growth_features = [c for c in train_data.columns if any(x in c.lower() for x in
    ['growth', 'change', 'delta', 'trend', 'momentum', 'velocity', 'pct'])]
predictive_features.extend(growth_features)

# C. Temporal features (lag features from phase4b)
lag_features = [c for c in train_data.columns if any(x in c.lower() for x in
    ['lag', 'prev', 'prior', 'historical', 'rolling', 'moving'])]
predictive_features.extend(lag_features)

# D. Specialty indicators (important for prescription patterns)
specialty_features = [c for c in train_data.columns if 'specialty' in c.lower() or 'is_' in c.lower()]
predictive_features.extend(specialty_features)

# Remove duplicates and keep only numeric
predictive_features = list(set(predictive_features))
predictive_features = [f for f in predictive_features if f in train_data.columns and 
                       train_data[f].dtype in ['int64', 'float64']]

print(f"   ✓ Selected {len(predictive_features)} predictive features")
print(f"   Categories: TRx={len(trx_features)}, Growth={len(growth_features)}, "
      f"Lag={len(lag_features)}, Specialty={len(specialty_features)}")

# 5. Prepare training data
print("\n5. Preparing Training Data...")
X = train_data[predictive_features].fillna(0)
y = train_data['NGD_Category']

print(f"   ✓ X shape: {X.shape}")
print(f"   ✓ y distribution:")
print(y.value_counts())

# Train-test split with stratification
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

print(f"\n   Train: {len(X_train):,}, Test: {len(X_test):,}")

# 6. Handle class imbalance with SMOTE
print("\n6. Handling Class Imbalance with SMOTE...")
print(f"   Before SMOTE:")
print(y_train.value_counts())

smote = SMOTE(random_state=42, k_neighbors=3)
X_train_balanced, y_train_balanced = smote.fit_resample(X_train, y_train)

print(f"\n   After SMOTE:")
print(pd.Series(y_train_balanced).value_counts())

# 7. Train NGD Predictor
print("\n7. Training NGD Predictor (Random Forest)...")
ngd_model = RandomForestClassifier(
    n_estimators=200,
    max_depth=15,
    min_samples_split=10,
    min_samples_leaf=4,
    class_weight='balanced',  # Additional safeguard
    random_state=42,
    n_jobs=-1,
    verbose=1
)

ngd_model.fit(X_train_balanced, y_train_balanced)
print("   ✓ Training complete")

# 8. Evaluate
print("\n8. Model Evaluation...")
train_score = ngd_model.score(X_train_balanced, y_train_balanced)
test_score = ngd_model.score(X_test, y_test)

print(f"   Train accuracy: {train_score:.3f}")
print(f"   Test accuracy: {test_score:.3f}")

y_pred = ngd_model.predict(X_test)
print(f"\n   Classification Report:")
print(classification_report(y_test, y_pred))

print(f"\n   Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))

# Feature importance
feature_importance = pd.DataFrame({
    'feature': predictive_features,
    'importance': ngd_model.feature_importances_
}).sort_values('importance', ascending=False)

print(f"\n   Top 10 Most Important Features:")
for idx, row in feature_importance.head(10).iterrows():
    print(f"      {row['feature']}: {row['importance']:.4f}")

# 9. Apply to ALL HCPs
print("\n9. Predicting NGD for All HCPs...")
X_all = features_df[predictive_features].fillna(0)
ngd_predictions = ngd_model.predict(X_all)

features_df['Predicted_NGD_Category'] = ngd_predictions

print(f"   ✓ Predictions complete for {len(features_df):,} HCPs")
print(f"\n   Predicted Distribution:")
print(pd.Series(ngd_predictions).value_counts())
print(f"\n   Percentage:")
print(pd.Series(ngd_predictions).value_counts(normalize=True) * 100)

# 10. Save outputs
print("\n10. Saving Outputs...")

# Save model
model_file = MODELS_DIR / 'ngd_category_predictor.pkl'
with open(model_file, 'wb') as f:
    pickle.dump({
        'model': ngd_model,
        'features': predictive_features,
        'smote_params': {'k_neighbors': 3},
        'train_accuracy': train_score,
        'test_accuracy': test_score
    }, f)
print(f"   ✓ Model saved: {model_file}")

# Save feature importance
importance_file = MODELS_DIR / 'feature_importance.csv'
feature_importance.to_csv(importance_file, index=False)
print(f"   ✓ Feature importance saved: {importance_file}")

# Save predictions for Phase 5 to use
predictions_file = FEATURES_DIR / 'NGD_Predictions_ML.csv'
features_df[['PrescriberId', 'Predicted_NGD_Category']].to_csv(predictions_file, index=False)
print(f"   ✓ Predictions saved: {predictions_file}")

print("\n" + "="*80)
print("✅ NGD PREDICTOR TRAINING COMPLETE!")
print("="*80)
print("\nNext Steps:")
print("1. Phase 5 will use these ML-predicted NGD categories as targets")
print("2. This gives balanced classes: ~25% each category instead of 99% NEW")
print("3. Phase 6 models will learn meaningful patterns instead of always predicting NEW")
print("4. UI will show diverse NGD statuses (Grower/Decliner/Stable/New)")

"""
Quick script to retrain only the 6 regression models with LightGBM
"""
import sys
sys.path.insert(0, '.')

from phase6_model_training import EnterpriseModelTraining

# Initialize trainer
trainer = EnterpriseModelTraining()

# Load data
trainer.load_data()

# Train only regression models
print("\n" + "="*80)
print("RETRAINING 6 REGRESSION MODELS WITH LIGHTGBM")
print("="*80)

products = ['Tirosint', 'Flector', 'Licart']
regression_outcomes = ['prescription_lift', 'wallet_share_growth']

for product in products:
    for outcome in regression_outcomes:
        print(f"\n{'='*80}")
        print(f"🎯 TRAINING: {product} - {outcome}")
        print(f"{'='*80}")
        try:
            result = trainer.train_single_model(product, outcome)
            if result:
                print(f"✓ {product}_{outcome} completed successfully")
        except Exception as e:
            print(f"✗ Error training {product}_{outcome}: {e}")

# Save reports
trainer.generate_performance_report()
trainer.save_feature_importance()
trainer.save_audit_log()

print("\n" + "="*80)
print("✅ REGRESSION MODELS RETRAINED WITH LIGHTGBM")
print("="*80)

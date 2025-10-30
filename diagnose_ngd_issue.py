"""
Diagnose NGD Category class imbalance issue
"""
import pandas as pd
import glob

print("="*80)
print("DIAGNOSING NGD CATEGORY CLASS IMBALANCE")
print("="*80)

# 1. Check target distribution
print("\n1. Checking Target Distribution...")
target_files = glob.glob('ibsa-poc-eda/outputs/targets/IBSA_Targets_Enterprise_*.csv')
latest_target = sorted(target_files)[-1]
print(f"Latest target file: {latest_target.split('\\\\')[-1]}")

targets = pd.read_csv(latest_target)
ngd_target_cols = [c for c in targets.columns if 'ngd_category' in c]

for col in ngd_target_cols:
    print(f"\n{col}:")
    print(f"  Value counts:")
    print(targets[col].value_counts())
    print(f"\n  Percentage distribution:")
    print(targets[col].value_counts(normalize=True) * 100)
    print(f"  Class imbalance ratio: {targets[col].value_counts().max() / targets[col].value_counts().min():.2f}:1")

# 2. Check predictions
print("\n\n2. Checking Model Predictions...")
predictions = pd.read_csv('ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced_WithPredictions.csv', nrows=5000)

for product in ['Tirosint', 'Flector', 'Licart']:
    pred_col = f'{product}_ngd_category_pred'
    if pred_col in predictions.columns:
        print(f"\n{pred_col}:")
        print(f"  Value counts:")
        print(predictions[pred_col].value_counts())
        print(f"\n  Percentage distribution:")
        print(predictions[pred_col].value_counts(normalize=True) * 100)

# 3. Check model performance reports
print("\n\n3. Checking Model Training Reports...")
model_reports = glob.glob('ibsa-poc-eda/outputs/models/model_performance_report_*.json')
if model_reports:
    import json
    latest_report = sorted(model_reports)[-1]
    print(f"Latest report: {latest_report.split('\\\\')[-1]}")
    
    with open(latest_report, 'r') as f:
        report = json.load(f)
    
    for model_name in report.get('model_scores', {}).keys():
        if 'ngd_category' in model_name:
            print(f"\n{model_name}:")
            scores = report['model_scores'][model_name]
            print(f"  Training accuracy: {scores.get('accuracy_train', 0):.3f}")
            print(f"  Test accuracy: {scores.get('accuracy_test', 0):.3f}")
            if 'confusion_matrix_test' in scores:
                print(f"  Confusion matrix: {scores['confusion_matrix_test']}")

print("\n" + "="*80)
print("DIAGNOSIS COMPLETE")
print("="*80)

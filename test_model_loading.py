import pickle
from pathlib import Path

models_dir = Path('ibsa-poc-eda/outputs/models/trained_models')
products = ['Tirosint', 'Flector', 'Licart']
outcomes = ['call_success', 'prescription_lift', 'ngd_category', 'wallet_share_growth']

print('Checking which models can be loaded:\n')
for p in products:
    for o in outcomes:
        model_path = models_dir / f'model_{p}_{o}.pkl'
        if model_path.exists():
            try:
                with open(model_path, 'rb') as f:
                    model = pickle.load(f)
                print(f'✓ {p}_{o}: {type(model).__name__}, features={model.n_features_in_}')
            except Exception as e:
                print(f'✗ {p}_{o}: Error loading - {e}')
        else:
            print(f'✗ {p}_{o}: File not found')

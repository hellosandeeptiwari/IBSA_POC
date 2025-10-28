#!/usr/bin/env python3
"""
=============================================================================
🚀 IBSA COMPLETE EDA & MODELING PIPELINE
=============================================================================
End-to-end pipeline from data loading to model deployment

Aligned with:
- Quarterly Business Summary 7.2025 v3
- ODIA Precall Plan Veeva Integration
- Executive presentation requirements

Pipeline Steps:
1. Data Loading & Validation
2. Exploratory Data Analysis
3. Feature Engineering
4. Predictive Modeling
5. Call Plan Generation
6. Veeva CRM Export
"""

import os
import sys
import pandas as pd
import numpy as np
from datetime import datetime
import logging

# Add project to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Import IBSA modules
from precall_planning_engine import DataLoader, HCPTargetingEngine, CallPlanningEngine, config
from features.feature_engineering_advanced import FeatureEngineer, TargetVariableCreator
from models.predictive_models import IBSAPredictionPipeline

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'ibsa_pipeline_{datetime.now().strftime("%Y%m%d_%H%M")}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# =============================================================================
# 📊 PIPELINE CONFIGURATION
# =============================================================================

class PipelineConfig:
    """Pipeline execution configuration"""
    
    # Execution flags
    RUN_EDA = True
    RUN_FEATURE_ENGINEERING = True
    RUN_MODELING = True
    RUN_CALL_PLANNING = True
    SAVE_OUTPUTS = True
    
    # Output paths
    OUTPUT_DIR = r"c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs"
    MODEL_DIR = r"c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\models"
    REPORTS_DIR = r"c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\reports"
    
    # Create directories
    for directory in [OUTPUT_DIR, MODEL_DIR, REPORTS_DIR]:
        os.makedirs(directory, exist_ok=True)

pipeline_config = PipelineConfig()

# =============================================================================
# 📈 EDA ANALYSIS MODULE
# =============================================================================

class IBSAExploratoryAnalysis:
    """Comprehensive EDA aligned with business deck"""
    
    def __init__(self, datasets: dict):
        self.datasets = datasets
        self.analysis_results = {}
    
    def run_complete_eda(self):
        """
        Execute comprehensive EDA
        """
        logger.info("=" * 80)
        logger.info("📊 STARTING COMPREHENSIVE EXPLORATORY DATA ANALYSIS")
        logger.info("=" * 80)
        
        # 1. HCP Universe Analysis
        if 'prescriber_profile' in self.datasets:
            self.analyze_hcp_universe()
        
        # 2. Territory Performance Analysis
        if 'territory_performance' in self.datasets:
            self.analyze_territory_performance()
        
        # 3. Call Activity Analysis
        if 'call_activity' in self.datasets:
            self.analyze_call_activity()
        
        # 4. Product Mix Analysis
        if 'trx_summary' in self.datasets and 'nrx_summary' in self.datasets:
            self.analyze_product_mix()
        
        # 5. Payment Method Analysis
        if 'payment_plan' in self.datasets:
            self.analyze_payment_methods()
        
        logger.info("\n✓ EDA Complete!")
        return self.analysis_results
    
    def analyze_hcp_universe(self):
        """Analyze HCP universe distribution"""
        logger.info("\n🏥 HCP UNIVERSE ANALYSIS")
        logger.info("-" * 80)
        
        df = self.datasets['prescriber_profile']
        
        results = {
            'total_hcps': len(df),
            'specialty_distribution': {},
            'geographic_distribution': {},
            'prescribing_stats': {}
        }
        
        # Specialty distribution
        if 'Specialty' in df.columns:
            spec_dist = df['Specialty'].value_counts().head(10)
            results['specialty_distribution'] = spec_dist.to_dict()
            logger.info(f"\n📋 Top 10 Specialties:")
            for spec, count in spec_dist.items():
                logger.info(f"  {spec:<40} {count:>8,} ({count/len(df)*100:>5.1f}%)")
        
        # Geographic distribution
        if 'State' in df.columns:
            state_dist = df['State'].value_counts().head(10)
            results['geographic_distribution'] = state_dist.to_dict()
            logger.info(f"\n🗺️ Top 10 States:")
            for state, count in state_dist.items():
                logger.info(f"  {state:<40} {count:>8,}")
        
        # Prescribing volume
        trx_cols = [col for col in df.columns if 'TRx' in col or 'trx' in col.lower()]
        if trx_cols:
            df['Total_TRx'] = df[trx_cols].fillna(0).sum(axis=1)
            results['prescribing_stats'] = {
                'mean_trx': df['Total_TRx'].mean(),
                'median_trx': df['Total_TRx'].median(),
                'total_trx': df['Total_TRx'].sum()
            }
            logger.info(f"\n💊 Prescribing Statistics:")
            logger.info(f"  Total TRx Volume:  {results['prescribing_stats']['total_trx']:>12,.0f}")
            logger.info(f"  Mean TRx per HCP:  {results['prescribing_stats']['mean_trx']:>12,.1f}")
            logger.info(f"  Median TRx per HCP: {results['prescribing_stats']['median_trx']:>12,.1f}")
        
        self.analysis_results['hcp_universe'] = results
    
    def analyze_territory_performance(self):
        """Analyze territory-level performance"""
        logger.info("\n🎯 TERRITORY PERFORMANCE ANALYSIS")
        logger.info("-" * 80)
        
        df = self.datasets['territory_performance']
        
        # Top territories by performance
        if 'Territory' in df.columns and 'TRx' in ''.join(df.columns):
            trx_cols = [col for col in df.columns if 'TRx' in col]
            if trx_cols:
                df['Total_TRx'] = df[trx_cols].fillna(0).sum(axis=1)
                top_territories = df.groupby('Territory')['Total_TRx'].sum().sort_values(ascending=False).head(10)
                
                logger.info(f"\n🏆 Top 10 Territories by TRx Volume:")
                for territory, trx in top_territories.items():
                    logger.info(f"  {territory:<40} {trx:>12,.0f}")
                
                self.analysis_results['territory_performance'] = {
                    'top_territories': top_territories.to_dict()
                }
    
    def analyze_call_activity(self):
        """Analyze call patterns and effectiveness"""
        logger.info("\n📞 CALL ACTIVITY ANALYSIS")
        logger.info("-" * 80)
        
        df = self.datasets['call_activity']
        
        results = {
            'total_calls': len(df),
            'call_patterns': {}
        }
        
        logger.info(f"  Total Calls: {results['total_calls']:,}")
        
        # Call type distribution
        if 'Call_Type' in df.columns or 'call_type' in df.columns:
            call_type_col = 'Call_Type' if 'Call_Type' in df.columns else 'call_type'
            call_types = df[call_type_col].value_counts()
            results['call_patterns']['by_type'] = call_types.to_dict()
            
            logger.info(f"\n  Call Types:")
            for call_type, count in call_types.items():
                logger.info(f"    {call_type:<30} {count:>8,}")
        
        # Calls per HCP
        if 'HCP_NPI' in df.columns or 'Account_Id' in df.columns:
            hcp_col = 'HCP_NPI' if 'HCP_NPI' in df.columns else 'Account_Id'
            calls_per_hcp = df.groupby(hcp_col).size()
            results['call_patterns']['avg_calls_per_hcp'] = calls_per_hcp.mean()
            
            logger.info(f"\n  Average Calls per HCP: {results['call_patterns']['avg_calls_per_hcp']:.1f}")
        
        self.analysis_results['call_activity'] = results
    
    def analyze_product_mix(self):
        """Analyze product portfolio performance"""
        logger.info("\n💊 PRODUCT MIX ANALYSIS")
        logger.info("-" * 80)
        
        trx_df = self.datasets['trx_summary']
        nrx_df = self.datasets['nrx_summary']
        
        # IBSA product performance
        ibsa_products = ['TIROSINT', 'FLECTOR', 'LICART']
        
        logger.info("\n  IBSA Product Performance:")
        
        for product in ibsa_products:
            trx_cols = [col for col in trx_df.columns if product in col.upper()]
            if trx_cols:
                total_trx = trx_df[trx_cols].fillna(0).sum().sum()
                logger.info(f"    {product:<20} {total_trx:>12,.0f} TRx")
        
        self.analysis_results['product_mix'] = {
            'products_analyzed': ibsa_products
        }
    
    def analyze_payment_methods(self):
        """Analyze payment method preferences"""
        logger.info("\n💳 PAYMENT METHOD ANALYSIS")
        logger.info("-" * 80)
        
        df = self.datasets['payment_plan']
        
        # Payment type distribution
        payment_cols = [col for col in df.columns if 'payment' in col.lower() or 'plan' in col.lower()]
        
        if payment_cols:
            logger.info(f"  Payment-related columns found: {len(payment_cols)}")
            self.analysis_results['payment_methods'] = {
                'columns_analyzed': payment_cols
            }

# =============================================================================
# 🎯 MAIN PIPELINE ORCHESTRATION
# =============================================================================

def main():
    """
    Main pipeline execution
    """
    print("\n" + "=" * 80)
    print("🚀 IBSA COMPLETE EDA & MODELING PIPELINE")
    print("=" * 80)
    print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80 + "\n")
    
    start_time = datetime.now()
    
    # -------------------------------------------------------------------------
    # STEP 1: DATA LOADING
    # -------------------------------------------------------------------------
    logger.info("STEP 1: Loading data...")
    loader = DataLoader()
    datasets = loader.load_all_tables()
    
    if not datasets:
        logger.error("❌ No datasets loaded. Exiting...")
        return
    
    # -------------------------------------------------------------------------
    # STEP 2: EXPLORATORY DATA ANALYSIS
    # -------------------------------------------------------------------------
    if pipeline_config.RUN_EDA:
        logger.info("\nSTEP 2: Running EDA...")
        eda = IBSAExploratoryAnalysis(datasets)
        eda_results = eda.run_complete_eda()
    
    # -------------------------------------------------------------------------
    # STEP 3: FEATURE ENGINEERING
    # -------------------------------------------------------------------------
    if pipeline_config.RUN_FEATURE_ENGINEERING:
        logger.info("\nSTEP 3: Feature Engineering...")
        
        if 'prescriber_profile' in datasets:
            engineer = FeatureEngineer()
            
            feature_df = engineer.engineer_all_features(
                prescriber_df=datasets['prescriber_profile'],
                call_activity_df=datasets.get('call_activity'),
                trx_df=datasets.get('trx_summary'),
                nrx_df=datasets.get('nrx_summary')
            )
            
            # Create target variables
            feature_df = TargetVariableCreator.create_call_success_target(feature_df)
            feature_df = TargetVariableCreator.create_prescription_lift_target(feature_df)
            
            # Get model-ready dataset
            model_df, feature_list = engineer.get_model_ready_dataset(feature_df)
            
            # Save feature engineered data
            if pipeline_config.SAVE_OUTPUTS:
                output_path = os.path.join(
                    pipeline_config.OUTPUT_DIR,
                    f"IBSA_FeatureEngineered_{datetime.now().strftime('%Y%m%d_%H%M')}.csv"
                )
                model_df.to_csv(output_path, index=False)
                logger.info(f"✓ Feature data saved: {output_path}")
    
    # -------------------------------------------------------------------------
    # STEP 4: PREDICTIVE MODELING
    # -------------------------------------------------------------------------
    if pipeline_config.RUN_MODELING and 'model_df' in locals():
        logger.info("\nSTEP 4: Training Predictive Models...")
        
        # Initialize pipeline
        prediction_pipeline = IBSAPredictionPipeline()
        
        # Train all models
        prediction_pipeline.train_all_models(model_df, feature_list)
        
        # Generate predictions
        predictions_df = prediction_pipeline.predict_all(model_df, feature_list)
        
        # Save predictions
        if pipeline_config.SAVE_OUTPUTS:
            pred_path = os.path.join(
                pipeline_config.OUTPUT_DIR,
                f"IBSA_Predictions_{datetime.now().strftime('%Y%m%d_%H%M')}.csv"
            )
            predictions_df.to_csv(pred_path, index=False)
            logger.info(f"✓ Predictions saved: {pred_path}")
        
        # Save models
        prediction_pipeline.save_pipeline(pipeline_config.MODEL_DIR)
    
    # -------------------------------------------------------------------------
    # STEP 5: CALL PLAN GENERATION
    # -------------------------------------------------------------------------
    if pipeline_config.RUN_CALL_PLANNING and 'predictions_df' in locals():
        logger.info("\nSTEP 5: Generating Call Plans...")
        
        # HCP Targeting
        targeting = HCPTargetingEngine(predictions_df)
        segmented_hcps = targeting.segment_hcps()
        segmented_hcps = targeting.identify_whitespace_opportunities(segmented_hcps)
        
        # Call Planning
        planner = CallPlanningEngine(
            datasets.get('call_activity', pd.DataFrame()),
            segmented_hcps
        )
        
        call_plan = planner.calculate_optimal_call_frequency()
        final_call_plan = planner.generate_call_plan()
        
        # Save call plan
        if pipeline_config.SAVE_OUTPUTS:
            call_plan_path = os.path.join(
                pipeline_config.OUTPUT_DIR,
                f"IBSA_CallPlan_VeevaReady_{datetime.now().strftime('%Y%m%d_%H%M')}.csv"
            )
            final_call_plan.to_csv(call_plan_path, index=False)
            logger.info(f"✓ Call plan saved: {call_plan_path}")
    
    # -------------------------------------------------------------------------
    # PIPELINE SUMMARY
    # -------------------------------------------------------------------------
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    print("\n" + "=" * 80)
    print("✅ PIPELINE EXECUTION COMPLETE!")
    print("=" * 80)
    print(f"End Time: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Duration: {duration:.1f} seconds ({duration/60:.1f} minutes)")
    print(f"\n📁 Outputs saved to: {pipeline_config.OUTPUT_DIR}")
    print(f"🤖 Models saved to: {pipeline_config.MODEL_DIR}")
    print("=" * 80 + "\n")
    
    logger.info("Pipeline execution complete successfully!")

# =============================================================================
# 🚀 ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ Pipeline interrupted by user")
        logger.warning("Pipeline interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Pipeline error: {e}")
        logger.error(f"Pipeline error: {e}", exc_info=True)
        raise

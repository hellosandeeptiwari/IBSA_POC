#!/usr/bin/env python3
"""
=============================================================================
🎯 IBSA PRE-CALL PLANNING & TARGETING ENGINE
=============================================================================
Main orchestration module for IBSA's comprehensive pre-call planning system
Based on: Quarterly Business Summary & ODIA Precall Plan Veeva Integration

Key Components:
1. HCP Targeting & Segmentation
2. Territory Performance Analysis
3. Call Planning Optimization
4. Product Mix Analysis
5. Competitive Intelligence
6. Sample Allocation Strategy
7. Payment Method Analysis
8. Predictive Modeling for Call Success
"""

import os
import sys
from datetime import datetime
import pandas as pd
import numpy as np
from typing import Dict, List, Tuple, Optional
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# =============================================================================
# 📊 CONFIGURATION
# =============================================================================

class IBSAConfig:
    """Central configuration for IBSA analysis"""
    
    # Data paths
    DATA_DIR = r"c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\data"
    OUTPUT_DIR = r"c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs"
    MODEL_DIR = r"c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\models"
    
    # Key products
    PRODUCTS = {
        'TIROSINT': ['TIROSINT', 'TIROSINT-SOL'],
        'FLECTOR': ['FLECTOR PATCH'],
        'LICART': ['LICART PATCH']
    }
    
    # Target specialties (based on business deck)
    TARGET_SPECIALTIES = [
        'Endocrinology',
        'Family Practice', 
        'Internal Medicine',
        'Pain Management',
        'Physical Medicine and Rehabilitation',
        'Rheumatology'
    ]
    
    # Business metrics thresholds
    THRESHOLDS = {
        'high_value_prescriber_trx': 50,
        'medium_value_prescriber_trx': 20,
        'call_frequency_high': 8,
        'call_frequency_medium': 4,
        'sample_effectiveness_threshold': 0.15
    }
    
    # Veeva CRM fields mapping
    VEEVA_FIELDS = {
        'account_id': 'Account_vod__c',
        'call_date': 'Call_Date_vod__c',
        'call_type': 'Call_Type_vod__c',
        'product_discussed': 'Product_vod__c',
        'samples_dropped': 'Samples_Dropped_vod__c',
        'next_call_planned': 'Next_Call_Date_vod__c'
    }

config = IBSAConfig()

# =============================================================================
# 📥 DATA LOADER
# =============================================================================

class DataLoader:
    """Load and prepare IBSA data from SQL exports"""
    
    def __init__(self, data_dir: str = None):
        self.data_dir = data_dir or config.DATA_DIR
        self.datasets = {}
        
    def load_all_tables(self) -> Dict[str, pd.DataFrame]:
        """Load all required tables"""
        logger.info("Loading IBSA datasets...")
        
        tables_to_load = {
            'prescriber_profile': 'Reporting_BI_PrescriberProfile.csv',
            'prescriber_overview': 'Reporting_BI_PrescriberOverview.csv',
            'call_activity': 'Reporting_BI_CallActivity.csv',
            'trx_summary': 'Reporting_BI_Trx_SampleSummary.csv',
            'nrx_summary': 'Reporting_BI_Nrx_SampleSummary.csv',
            'territory_performance': 'Reporting_BI_TerritoryPerformanceSummary.csv',
            'ngd_data': 'Reporting_BI_NGD.csv',
            'payment_plan': 'Reporting_BI_PrescriberPaymentPlanSummary.csv',
            'call_attainment_tier': 'Reporting_BI_CallAttainment_Summary_Tier.csv',
            'call_attainment_territory': 'Reporting_BI_CallAttainment_Summary_TerritoryLevel.csv'
        }
        
        for key, filename in tables_to_load.items():
            filepath = os.path.join(self.data_dir, filename)
            if os.path.exists(filepath):
                try:
                    logger.info(f"Loading {key}...")
                    df = pd.read_csv(filepath, low_memory=False)
                    self.datasets[key] = df
                    logger.info(f"  ✓ Loaded {len(df):,} records")
                except Exception as e:
                    logger.error(f"  ✗ Error loading {key}: {e}")
            else:
                logger.warning(f"  ⚠ File not found: {filename}")
        
        logger.info(f"\nLoaded {len(self.datasets)} datasets successfully")
        return self.datasets
    
    def get_dataset(self, name: str) -> Optional[pd.DataFrame]:
        """Get specific dataset"""
        return self.datasets.get(name)

# =============================================================================
# 🎯 HCP TARGETING & SEGMENTATION
# =============================================================================

class HCPTargetingEngine:
    """
    HCP Targeting and Segmentation Engine
    Based on: Business deck slides on HCP universe and targeting strategy
    """
    
    def __init__(self, prescriber_df: pd.DataFrame, trx_df: pd.DataFrame = None):
        self.prescriber_df = prescriber_df
        self.trx_df = trx_df
        
    def segment_hcps(self) -> pd.DataFrame:
        """
        Segment HCPs into tiers based on business rules
        Tiers: Platinum, Gold, Silver, Bronze, Non-Target
        """
        logger.info("Segmenting HCPs into value tiers...")
        
        df = self.prescriber_df.copy()
        
        # Calculate total IBSA TRx (if available)
        trx_cols = [col for col in df.columns if 'TRx' in col or 'trx' in col.lower()]
        if trx_cols:
            df['Total_IBSA_TRx'] = df[trx_cols].fillna(0).sum(axis=1)
        else:
            df['Total_IBSA_TRx'] = 0
        
        # Tier assignment
        df['HCP_Tier'] = 'Non-Target'
        df.loc[df['Total_IBSA_TRx'] >= config.THRESHOLDS['high_value_prescriber_trx'], 'HCP_Tier'] = 'Platinum'
        df.loc[(df['Total_IBSA_TRx'] >= config.THRESHOLDS['medium_value_prescriber_trx']) & 
               (df['Total_IBSA_TRx'] < config.THRESHOLDS['high_value_prescriber_trx']), 'HCP_Tier'] = 'Gold'
        df.loc[(df['Total_IBSA_TRx'] > 0) & 
               (df['Total_IBSA_TRx'] < config.THRESHOLDS['medium_value_prescriber_trx']), 'HCP_Tier'] = 'Silver'
        
        # Target specialty flag
        if 'Specialty' in df.columns or 'specialty' in df.columns:
            spec_col = 'Specialty' if 'Specialty' in df.columns else 'specialty'
            df['Is_Target_Specialty'] = df[spec_col].isin(config.TARGET_SPECIALTIES)
        
        logger.info(f"Segmentation complete:")
        logger.info(f"  Platinum: {(df['HCP_Tier'] == 'Platinum').sum():,}")
        logger.info(f"  Gold: {(df['HCP_Tier'] == 'Gold').sum():,}")
        logger.info(f"  Silver: {(df['HCP_Tier'] == 'Silver').sum():,}")
        
        return df
    
    def identify_whitespace_opportunities(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Identify white space: high-potential HCPs not currently being detailed
        """
        logger.info("Identifying whitespace opportunities...")
        
        # HCPs with high specialty alignment but low/no IBSA TRx
        df['Whitespace_Opportunity'] = (
            (df.get('Is_Target_Specialty', False)) & 
            (df['Total_IBSA_TRx'] == 0)
        )
        
        whitespace_count = df['Whitespace_Opportunity'].sum()
        logger.info(f"  Found {whitespace_count:,} whitespace opportunities")
        
        return df
    
    def calculate_hcp_potential(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Calculate HCP potential score for prioritization
        Factors: Specialty, Geography, Historical Rx, Competitor Rx
        """
        logger.info("Calculating HCP potential scores...")
        
        df['HCP_Potential_Score'] = 0.0
        
        # Specialty weight (40%)
        if 'Is_Target_Specialty' in df.columns:
            df['HCP_Potential_Score'] += df['Is_Target_Specialty'].astype(int) * 40
        
        # Volume weight (30%)
        if 'Total_IBSA_TRx' in df.columns:
            max_trx = df['Total_IBSA_TRx'].max()
            if max_trx > 0:
                df['HCP_Potential_Score'] += (df['Total_IBSA_TRx'] / max_trx) * 30
        
        # Growth potential (30%) - based on NRx vs TRx ratio
        nrx_cols = [col for col in df.columns if 'NRx' in col or 'nrx' in col.lower()]
        if nrx_cols and 'Total_IBSA_TRx' in df.columns:
            df['Total_IBSA_NRx'] = df[nrx_cols].fillna(0).sum(axis=1)
            df['NRx_Ratio'] = df['Total_IBSA_NRx'] / (df['Total_IBSA_TRx'] + 1)
            df['HCP_Potential_Score'] += (df['NRx_Ratio'] * 30).clip(upper=30)
        
        logger.info("  ✓ HCP potential scores calculated")
        return df

# =============================================================================
# 📞 CALL PLANNING ENGINE
# =============================================================================

class CallPlanningEngine:
    """
    Optimized Call Planning based on ODIA Pre-call Plan
    Integrates with Veeva CRM
    """
    
    def __init__(self, call_activity_df: pd.DataFrame, hcp_segments_df: pd.DataFrame):
        self.call_activity_df = call_activity_df
        self.hcp_segments_df = hcp_segments_df
        
    def calculate_optimal_call_frequency(self) -> pd.DataFrame:
        """
        Calculate optimal call frequency by HCP tier
        Based on tier, response rate, and capacity constraints
        """
        logger.info("Calculating optimal call frequencies...")
        
        df = self.hcp_segments_df.copy()
        
        # Tier-based call frequency
        call_frequency_map = {
            'Platinum': 8,  # 8 calls per quarter
            'Gold': 6,      # 6 calls per quarter
            'Silver': 4,    # 4 calls per quarter
            'Bronze': 2,    # 2 calls per quarter
            'Non-Target': 0
        }
        
        df['Recommended_Call_Frequency'] = df['HCP_Tier'].map(call_frequency_map)
        
        logger.info("  ✓ Call frequency recommendations generated")
        return df
    
    def generate_call_plan(self, territory_id: str = None) -> pd.DataFrame:
        """
        Generate detailed call plan for territory
        Output format matches ODIA Precall Plan Veeva Integration
        """
        logger.info(f"Generating call plan{' for territory ' + territory_id if territory_id else ''}...")
        
        df = self.hcp_segments_df.copy()
        
        if territory_id and 'Territory' in df.columns:
            df = df[df['Territory'] == territory_id]
        
        # Priority ranking
        df = df.sort_values(['HCP_Potential_Score', 'Total_IBSA_TRx'], ascending=[False, False])
        df['Call_Priority'] = range(1, len(df) + 1)
        
        # Veeva CRM fields
        df['Next_Call_Action'] = df['HCP_Tier'].map({
            'Platinum': 'Detail + Sample',
            'Gold': 'Detail + Sample',
            'Silver': 'Detail Only',
            'Bronze': 'Leave Sample',
            'Non-Target': 'Monitor'
        })
        
        logger.info(f"  ✓ Call plan generated for {len(df):,} HCPs")
        return df[[
            'HCP_NPI', 'HCP_Name', 'Specialty', 'Territory',
            'HCP_Tier', 'HCP_Potential_Score', 'Call_Priority',
            'Recommended_Call_Frequency', 'Next_Call_Action'
        ]]

# =============================================================================
# 🎯 MAIN EXECUTION
# =============================================================================

def main():
    """Main execution pipeline"""
    
    print("=" * 80)
    print("🎯 IBSA PRE-CALL PLANNING & TARGETING ENGINE")
    print("=" * 80)
    print()
    
    # Load data
    loader = DataLoader()
    datasets = loader.load_all_tables()
    
    if not datasets:
        logger.error("No datasets loaded. Exiting...")
        return
    
    # HCP Targeting
    if 'prescriber_profile' in datasets:
        targeting = HCPTargetingEngine(
            datasets['prescriber_profile'],
            datasets.get('trx_summary')
        )
        
        # Segment HCPs
        segmented_hcps = targeting.segment_hcps()
        segmented_hcps = targeting.identify_whitespace_opportunities(segmented_hcps)
        segmented_hcps = targeting.calculate_hcp_potential(segmented_hcps)
        
        # Generate call plan
        if 'call_activity' in datasets:
            planner = CallPlanningEngine(datasets['call_activity'], segmented_hcps)
            call_plan = planner.calculate_optimal_call_frequency()
            final_plan = planner.generate_call_plan()
            
            # Save outputs
            os.makedirs(config.OUTPUT_DIR, exist_ok=True)
            output_file = os.path.join(config.OUTPUT_DIR, 
                                      f"IBSA_Call_Plan_{datetime.now().strftime('%Y%m%d_%H%M')}.csv")
            final_plan.to_csv(output_file, index=False)
            logger.info(f"\n✓ Call plan saved to: {output_file}")
    
    print("\n" + "=" * 80)
    print("✓ Analysis complete!")
    print("=" * 80)

if __name__ == "__main__":
    main()

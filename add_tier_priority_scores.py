#!/usr/bin/env python3
"""
ADD TIER, PRIORITY, AND SCORE FIELDS FOR UI
============================================
Creates proper tier assignments, HCP Power Score, and priority flags
"""

import pandas as pd
import numpy as np

print("="*80)
print("ADDING TIER, PRIORITY, AND SCORE FIELDS")
print("="*80)

# Load UI dataset
df = pd.read_csv(r'ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced.csv', low_memory=False)
print(f"\nLoaded: {len(df):,} HCPs")

# ============================================================================
# 1. CREATE HCP POWER SCORE (replacing AI Score)
# ============================================================================
print(f"\n1. CREATING HCP POWER SCORE...")

# Use multiple factors to create a comprehensive power score (0-100)
components = []

# Factor 1: TRx Volume (40% weight)
if 'trx_prior_qtd' in df.columns:
    trx_score = (df['trx_prior_qtd'] / df['trx_prior_qtd'].quantile(0.95)).clip(0, 1) * 40
    components.append(trx_score)
    print(f"  + TRx volume score (40%)")

# Factor 2: Growth Potential (30% weight)
if 'growth_opportunity_hist' in df.columns:
    growth_score = (df['growth_opportunity_hist'] / 100) * 30
    components.append(growth_score)
    print(f"  + Growth opportunity score (30%)")

# Factor 3: Engagement (20% weight)
if 'engagement_score' in df.columns:
    engagement_score = (df['engagement_score'] / 100) * 20
    components.append(engagement_score)
    print(f"  + Engagement score (20%)")

# Factor 4: Call Success Prediction (10% weight)
if 'call_success' in df.columns:
    call_success_score = df['call_success'] * 10
    components.append(call_success_score)
    print(f"  + Call success prediction (10%)")

# Combine into HCP Power Score
if components:
    df['hcp_power_score'] = sum(components)
    df['hcp_power_score'] = df['hcp_power_score'].clip(0, 100).round(1)
    print(f"  OK HCP Power Score created: min={df['hcp_power_score'].min():.1f}, max={df['hcp_power_score'].max():.1f}, mean={df['hcp_power_score'].mean():.1f}")

# Also create ngd_score_continuous from ngd_category
if 'ngd_category' in df.columns:
    # Convert NGD category to continuous score
    # NEW=1 (high), GROWTH=2 (high), STABLE=0 (medium), DECLINE=3 (low)
    ngd_map = {0: 50, 1: 90, 2: 80, 3: 30}  # STABLE, NEW, GROWTH, DECLINE
    df['ngd_score_continuous'] = df['ngd_category'].map(ngd_map).fillna(50)
    print(f"  OK NGD continuous score created")

# ============================================================================
# 2. CREATE TIER ASSIGNMENTS (Platinum, Gold, Silver, Bronze)
# ============================================================================
print(f"\n2. CREATING TIER ASSIGNMENTS...")

if 'hcp_power_score' in df.columns:
    # Define tier thresholds based on power score
    df['tier'] = pd.cut(
        df['hcp_power_score'],
        bins=[0, 25, 50, 75, 100],
        labels=['Bronze', 'Silver', 'Gold', 'Platinum'],
        include_lowest=True
    )
    
    # Create binary tier flags (for UI filtering)
    df['hcp_tier_platinum'] = (df['tier'] == 'Platinum').astype(int)
    df['hcp_tier_gold'] = (df['tier'] == 'Gold').astype(int)
    df['hcp_tier_silver'] = (df['tier'] == 'Silver').astype(int)
    df['hcp_tier_bronze'] = (df['tier'] == 'Bronze').astype(int)
    
    print(f"  Tier distribution:")
    for tier in ['Platinum', 'Gold', 'Silver', 'Bronze']:
        count = (df['tier'] == tier).sum()
        pct = (count / len(df)) * 100
        print(f"    {tier}: {count:,} ({pct:.1f}%)")

# ============================================================================
# 3. FIX PRIORITY TIER ASSIGNMENTS
# ============================================================================
print(f"\n3. FIXING PRIORITY TIER ASSIGNMENTS...")

# Priority should be based on multiple factors
priority_score = 0

# High TRx volume
if 'trx_prior_qtd' in df.columns:
    high_trx = df['trx_prior_qtd'] >= df['trx_prior_qtd'].quantile(0.75)
    priority_score += high_trx.astype(int)

# High growth opportunity
if 'growth_opportunity_hist' in df.columns:
    high_growth = df['growth_opportunity_hist'] >= 70
    priority_score += high_growth.astype(int)

# Call success prediction
if 'call_success' in df.columns:
    likely_success = df['call_success'] >= 0.5
    priority_score += likely_success.astype(int)

# New or Growth NGD
if 'ngd_category' in df.columns:
    new_or_growth = df['ngd_category'].isin([1, 2])  # NEW or GROWTH
    priority_score += new_or_growth.astype(int)

# Assign priority tiers based on score
df['priority_tier1'] = (priority_score >= 3).astype(int)  # Top priority (3-4 factors)
df['priority_tier2'] = (priority_score == 2).astype(int)  # Medium priority (2 factors)
df['priority_tier3'] = (priority_score == 1).astype(int)  # Low priority (1 factor)

print(f"  Priority distribution:")
print(f"    Tier 1 (High): {df['priority_tier1'].sum():,} ({df['priority_tier1'].sum()/len(df)*100:.1f}%)")
print(f"    Tier 2 (Medium): {df['priority_tier2'].sum():,} ({df['priority_tier2'].sum()/len(df)*100:.1f}%)")
print(f"    Tier 3 (Low): {df['priority_tier3'].sum():,} ({df['priority_tier3'].sum()/len(df)*100:.1f}%)")
print(f"    No Priority: {(priority_score == 0).sum():,} ({(priority_score == 0).sum()/len(df)*100:.1f}%)")

# ============================================================================
# 4. CREATE NGD DECILE
# ============================================================================
print(f"\n4. CREATING NGD DECILE...")

if 'ngd_score_continuous' in df.columns:
    try:
        df['ngd_decile'] = pd.qcut(
            df['ngd_score_continuous'],
            q=10,
            labels=False,
            duplicates='drop'
        ) + 1  # 1-10 scale
        df['ngd_decile'] = df['ngd_decile'].fillna(5).astype(int)
        print(f"  OK NGD decile created (1-10 scale)")
    except:
        df['ngd_decile'] = 5
        print(f"  OK NGD decile set to default (5)")

# ============================================================================
# SAVE
# ============================================================================
print(f"\nSaving updated dataset...")
output_file = r'ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced.csv'
df.to_csv(output_file, index=False)

import os
file_size = os.path.getsize(output_file) / 1024 / 1024
print(f"  Saved: {output_file}")
print(f"  Size: {file_size:.1f} MB")

print("\n" + "="*80)
print("TIER, PRIORITY, AND SCORES ADDED!")
print("="*80)
print(f"\nNEW FIELDS CREATED:")
print(f"  1. hcp_power_score (0-100): Replaces 'AI Score'")
print(f"  2. tier (Platinum/Gold/Silver/Bronze): Shows in HCP cards")
print(f"  3. priority_tier1/2/3: Fixed to show real priorities")
print(f"  4. ngd_score_continuous (0-100): For NGD analysis")
print(f"  5. ngd_decile (1-10): NGD performance decile")
print(f"\n  Refresh UI to see changes!")
print("="*80)

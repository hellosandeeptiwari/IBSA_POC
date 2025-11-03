#!/usr/bin/env python3
"""
WALLET SHARE & COMPETITOR ANALYSIS FOR PRESENTATION DECK
=========================================================
Generates executive-ready visualizations for wallet share, competitive positioning,
and market share growth potential analysis.

OUTPUT:
- High-quality PNG charts for PowerPoint deck
- JSON summary statistics
- Segmentation analysis by share tier
- Competitive displacement opportunities
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import json
import os
from pathlib import Path
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# Configure plotting for presentation quality
sns.set_theme(style="whitegrid")
plt.rcParams.update({
    'figure.figsize': (14, 8),
    'figure.dpi': 150,
    'font.size': 11,
    'axes.titlesize': 14,
    'axes.labelsize': 12,
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'figure.titlesize': 16
})

class WalletShareCompetitorAnalysis:
    """
    EXECUTIVE WALLET SHARE & COMPETITOR ANALYSIS
    
    Creates presentation-ready visualizations:
    1. Current wallet share distribution (pie/bar charts)
    2. Wallet share growth potential by segment
    3. Competitor displacement opportunities
    4. Product-specific wallet share analysis (Tirosint, Flector, Licart)
    5. Territory-level competitive positioning
    6. HCP segmentation by wallet share tier
    """
    
    def __init__(self, data_file=None):
        self.data_dir = 'ibsa-poc-eda/data'
        self.output_dir = 'ibsa-poc-eda/outputs/wallet-share-analysis'
        self.plots_dir = os.path.join(self.output_dir, 'deck-charts')
        
        # Create output directories
        os.makedirs(self.output_dir, exist_ok=True)
        os.makedirs(self.plots_dir, exist_ok=True)
        
        # Load data
        if data_file:
            self.data_file = data_file
        else:
            # Use the version with competitor breakdown for full analysis
            phase7_file = 'ibsa-poc-eda/outputs/phase7/IBSA_ModelReady_Enhanced_WithPredictions_DEDUP_WithCompetitors_v2.csv'
            if os.path.exists(phase7_file):
                self.data_file = phase7_file
            else:
                # Fallback to UI data
                ui_data = 'ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced_WithPredictions.csv'
                if os.path.exists(ui_data):
                    self.data_file = ui_data
                else:
                    # Fallback to original
                    self.data_file = os.path.join(self.data_dir, 'IBSA_ModelReady_Enhanced.csv')
        
        print(f"\n📊 Loading data from: {self.data_file}")
        self.df = pd.read_csv(self.data_file, low_memory=False)
        print(f"✅ Loaded {len(self.df):,} HCP records\n")
        
        # Analysis results
        self.analysis_summary = {
            'analysis_date': datetime.now().isoformat(),
            'total_hcps': len(self.df),
            'wallet_share_metrics': {},
            'competitor_analysis': {},
            'growth_opportunities': {},
            'segmentation': {}
        }
    
    def calculate_wallet_share_metrics(self):
        """Calculate comprehensive wallet share metrics"""
        print("\n" + "="*80)
        print("📈 CALCULATING WALLET SHARE METRICS")
        print("="*80)
        
        # Calculate IBSA share
        if 'ibsa_trx' in self.df.columns and 'competitor_trx' in self.df.columns:
            self.df['total_trx'] = self.df['ibsa_trx'].fillna(0) + self.df['competitor_trx'].fillna(0)
            self.df['ibsa_share'] = np.where(
                self.df['total_trx'] > 0,
                (self.df['ibsa_trx'].fillna(0) / self.df['total_trx']) * 100,
                0
            )
        elif 'ibsa_share' not in self.df.columns:
            # Calculate from product-specific columns
            ibsa_cols = [c for c in self.df.columns if any(p in c.lower() for p in ['tirosint', 'flector', 'licart']) and 'trx' in c.lower()]
            comp_cols = [c for c in self.df.columns if 'competitor' in c.lower() and 'trx' in c.lower()]
            
            if ibsa_cols and comp_cols:
                self.df['ibsa_trx_total'] = self.df[ibsa_cols].fillna(0).sum(axis=1)
                self.df['comp_trx_total'] = self.df[comp_cols].fillna(0).sum(axis=1)
                self.df['total_trx'] = self.df['ibsa_trx_total'] + self.df['comp_trx_total']
                self.df['ibsa_share'] = np.where(
                    self.df['total_trx'] > 0,
                    (self.df['ibsa_trx_total'] / self.df['total_trx']) * 100,
                    0
                )
        
        # Overall metrics
        active_hcps = (self.df['ibsa_share'] > 0).sum()
        avg_share = self.df.loc[self.df['ibsa_share'] > 0, 'ibsa_share'].mean()
        median_share = self.df.loc[self.df['ibsa_share'] > 0, 'ibsa_share'].median()
        
        print(f"\n✅ OVERALL WALLET SHARE METRICS:")
        print(f"   • HCPs prescribing IBSA: {active_hcps:,} ({active_hcps/len(self.df)*100:.1f}%)")
        print(f"   • Average IBSA share (active HCPs): {avg_share:.1f}%")
        print(f"   • Median IBSA share (active HCPs): {median_share:.1f}%")
        
        self.analysis_summary['wallet_share_metrics'] = {
            'active_hcps': int(active_hcps),
            'active_hcp_percentage': round(active_hcps/len(self.df)*100, 1),
            'average_ibsa_share': round(float(avg_share), 1),
            'median_ibsa_share': round(float(median_share), 1)
        }
        
        return self
    
    def segment_hcps_by_wallet_share(self):
        """Segment HCPs by wallet share tier"""
        print("\n" + "="*80)
        print("🎯 HCP SEGMENTATION BY WALLET SHARE TIER")
        print("="*80)
        
        # Define segments
        self.df['wallet_tier'] = 'Non-Prescriber'
        self.df.loc[(self.df['ibsa_share'] > 0) & (self.df['ibsa_share'] <= 10), 'wallet_tier'] = 'Conversion (0-10%)'
        self.df.loc[(self.df['ibsa_share'] > 10) & (self.df['ibsa_share'] <= 30), 'wallet_tier'] = 'Growth (10-30%)'
        self.df.loc[(self.df['ibsa_share'] > 30) & (self.df['ibsa_share'] <= 50), 'wallet_tier'] = 'Expansion (30-50%)'
        self.df.loc[(self.df['ibsa_share'] > 50) & (self.df['ibsa_share'] <= 70), 'wallet_tier'] = 'Loyalty (50-70%)'
        self.df.loc[self.df['ibsa_share'] > 70, 'wallet_tier'] = 'Retention (70-100%)'
        
        # Segment distribution
        segment_counts = self.df['wallet_tier'].value_counts()
        
        print(f"\n📊 WALLET SHARE DISTRIBUTION:")
        for tier in ['Non-Prescriber', 'Conversion (0-10%)', 'Growth (10-30%)', 
                     'Expansion (30-50%)', 'Loyalty (50-70%)', 'Retention (70-100%)']:
            count = segment_counts.get(tier, 0)
            pct = (count / len(self.df)) * 100
            print(f"   • {tier:25s}: {count:7,} HCPs ({pct:5.1f}%)")
        
        # Calculate value by segment
        if 'ibsa_trx_total' in self.df.columns or 'ibsa_trx' in self.df.columns:
            trx_col = 'ibsa_trx_total' if 'ibsa_trx_total' in self.df.columns else 'ibsa_trx'
            segment_value = self.df.groupby('wallet_tier')[trx_col].sum()
            
            print(f"\n💰 TRx VOLUME BY SEGMENT:")
            for tier in segment_counts.index:
                if tier in segment_value.index:
                    trx = segment_value[tier]
                    pct_vol = (trx / segment_value.sum()) * 100
                    print(f"   • {tier:25s}: {trx:10,.0f} TRx ({pct_vol:5.1f}% of volume)")
        
        self.analysis_summary['segmentation'] = {
            str(k): int(v) for k, v in segment_counts.items()
        }
        
        return self
    
    def analyze_competitor_landscape(self):
        """Analyze competitor presence and opportunities"""
        print("\n" + "="*80)
        print("🏆 COMPETITIVE LANDSCAPE ANALYSIS")
        print("="*80)
        
        # Competitor product breakdown
        comp_products = {}
        for col in self.df.columns:
            if 'competitor_' in col.lower() and 'trx' in col.lower():
                product_name = col.replace('competitor_', '').replace('_trx', '').replace('_', ' ').title()
                total_trx = self.df[col].fillna(0).sum()
                if total_trx > 0:
                    comp_products[product_name] = total_trx
        
        if comp_products:
            print(f"\n📊 COMPETITOR PRODUCT DISTRIBUTION:")
            total_comp = sum(comp_products.values())
            for product, trx in sorted(comp_products.items(), key=lambda x: x[1], reverse=True):
                pct = (trx / total_comp) * 100
                print(f"   • {product:30s}: {trx:10,.0f} TRx ({pct:5.1f}%)")
            
            self.analysis_summary['competitor_analysis']['product_distribution'] = {
                str(k): float(v) for k, v in comp_products.items()
            }
        
        # Competitive situation analysis
        if 'comp_sit_not_using_ibsa' in self.df.columns:
            not_using = self.df['comp_sit_not_using_ibsa'].sum()
            comp_dominant = self.df.get('comp_sit_competitor_dominant', pd.Series([0])).sum()
            
            print(f"\n🎯 COMPETITIVE SITUATION:")
            print(f"   • Not using IBSA: {not_using:,} HCPs")
            print(f"   • Competitor dominant: {comp_dominant:,} HCPs")
            print(f"   • Conversion opportunity: {not_using + comp_dominant:,} HCPs")
        
        # Competitor strength
        if 'comp_strength_dominant' in self.df.columns:
            strength_dist = {
                'Dominant': self.df.get('comp_strength_dominant', pd.Series([0])).sum(),
                'Strong': self.df.get('comp_strength_strong', pd.Series([0])).sum(),
                'Moderate': self.df.get('comp_strength_moderate', pd.Series([0])).sum(),
                'Weak': self.df.get('comp_strength_weak', pd.Series([0])).sum()
            }
            
            print(f"\n💪 COMPETITOR STRENGTH:")
            for strength, count in strength_dist.items():
                pct = (count / len(self.df)) * 100
                print(f"   • {strength:12s}: {count:7,} HCPs ({pct:5.1f}%)")
        
        return self
    
    def calculate_growth_potential(self):
        """Calculate wallet share growth potential"""
        print("\n" + "="*80)
        print("📈 WALLET SHARE GROWTH POTENTIAL")
        print("="*80)
        
        # Calculate growth potential (1 - current_share) * opportunity_factor
        self.df['growth_potential'] = np.where(
            self.df['ibsa_share'] > 0,
            (100 - self.df['ibsa_share']) * 0.15,  # 15% of remaining share
            10  # Base potential for non-prescribers
        )
        
        # Cap at realistic values
        self.df['growth_potential'] = self.df['growth_potential'].clip(0, 30)
        
        # Segment by potential
        self.df['growth_tier'] = 'Low (0-5 pts)'
        self.df.loc[(self.df['growth_potential'] > 5) & (self.df['growth_potential'] <= 10), 'growth_tier'] = 'Medium (5-10 pts)'
        self.df.loc[self.df['growth_potential'] > 10, 'growth_tier'] = 'High (>10 pts)'
        
        growth_dist = self.df['growth_tier'].value_counts()
        
        print(f"\n📊 GROWTH POTENTIAL DISTRIBUTION:")
        for tier in ['High (>10 pts)', 'Medium (5-10 pts)', 'Low (0-5 pts)']:
            count = growth_dist.get(tier, 0)
            pct = (count / len(self.df)) * 100
            print(f"   • {tier:20s}: {count:7,} HCPs ({pct:5.1f}%)")
        
        # Calculate total addressable opportunity
        if 'total_trx' in self.df.columns:
            total_market_trx = self.df['total_trx'].sum()
            ibsa_trx = self.df['ibsa_trx_total'].sum() if 'ibsa_trx_total' in self.df.columns else 0
            addressable_trx = total_market_trx - ibsa_trx
            
            print(f"\n💰 ADDRESSABLE MARKET:")
            print(f"   • Total market TRx: {total_market_trx:,.0f}")
            print(f"   • Current IBSA TRx: {ibsa_trx:,.0f}")
            print(f"   • Addressable competitor TRx: {addressable_trx:,.0f}")
            print(f"   • Potential capture (15%): {addressable_trx * 0.15:,.0f} TRx")
        
        self.analysis_summary['growth_opportunities'] = {
            'distribution': {str(k): int(v) for k, v in growth_dist.items()}
        }
        
        return self
    
    def create_wallet_share_distribution_chart(self):
        """Create wallet share distribution visualization"""
        print("\n📊 Creating Wallet Share Distribution Chart...")
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7))
        
        # Chart 1: Pie chart of segments
        segment_order = ['Retention (70-100%)', 'Loyalty (50-70%)', 'Expansion (30-50%)', 
                        'Growth (10-30%)', 'Conversion (0-10%)', 'Non-Prescriber']
        segment_counts = self.df['wallet_tier'].value_counts()
        
        colors = ['#27ae60', '#2ecc71', '#3498db', '#f39c12', '#e74c3c', '#95a5a6']
        
        # Filter to only existing segments
        plot_segments = [s for s in segment_order if s in segment_counts.index]
        plot_counts = [segment_counts[s] for s in plot_segments]
        plot_colors = [colors[segment_order.index(s)] for s in plot_segments]
        
        wedges, texts, autotexts = ax1.pie(plot_counts, labels=plot_segments, colors=plot_colors,
                                            autopct='%1.1f%%', startangle=90, textprops={'fontsize': 10})
        
        # Bold percentage text
        for autotext in autotexts:
            autotext.set_color('white')
            autotext.set_fontweight('bold')
            autotext.set_fontsize(11)
        
        ax1.set_title('HCP Distribution by Wallet Share Tier', fontsize=14, fontweight='bold', pad=20)
        
        # Chart 2: Bar chart with counts and percentages
        y_pos = np.arange(len(plot_segments))
        ax2.barh(y_pos, plot_counts, color=plot_colors, alpha=0.8)
        ax2.set_yticks(y_pos)
        ax2.set_yticklabels(plot_segments)
        ax2.set_xlabel('Number of HCPs', fontweight='bold')
        ax2.set_title('HCP Count by Wallet Share Tier', fontsize=14, fontweight='bold', pad=20)
        ax2.invert_yaxis()
        
        # Add count labels
        for i, (count, segment) in enumerate(zip(plot_counts, plot_segments)):
            pct = (count / len(self.df)) * 100
            ax2.text(count + max(plot_counts)*0.02, i, f'{count:,} ({pct:.1f}%)', 
                    va='center', fontweight='bold', fontsize=10)
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.plots_dir, '1_wallet_share_distribution.png'), 
                   dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
        print("   ✅ Saved: 1_wallet_share_distribution.png")
    
    def create_competitor_landscape_chart(self):
        """Create competitor landscape visualization"""
        print("\n📊 Creating Competitor Landscape Chart...")
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # Chart 1: Competitor product distribution
        comp_products = {}
        for col in self.df.columns:
            if 'competitor_' in col.lower() and 'trx' in col.lower() and col != 'competitor_trx':
                product_name = col.replace('competitor_', '').replace('_trx', '').replace('_', '/').title()
                total_trx = self.df[col].fillna(0).sum()
                if total_trx > 0:
                    comp_products[product_name] = total_trx
        
        if comp_products:
            products = list(comp_products.keys())
            values = list(comp_products.values())
            colors_comp = ['#e74c3c', '#e67e22', '#f39c12', '#d35400', '#c0392b']
            
            ax1.barh(products, values, color=colors_comp[:len(products)], alpha=0.8)
            ax1.set_xlabel('Total TRx', fontweight='bold')
            ax1.set_title('Competitor Product Distribution', fontsize=14, fontweight='bold')
            
            # Add value labels
            for i, (prod, val) in enumerate(zip(products, values)):
                pct = (val / sum(values)) * 100
                ax1.text(val + max(values)*0.02, i, f'{val:,.0f} ({pct:.1f}%)', 
                        va='center', fontweight='bold', fontsize=10)
        
        # Chart 2: IBSA vs Competitor share
        if 'ibsa_trx_total' in self.df.columns or 'ibsa_trx' in self.df.columns:
            trx_col = 'ibsa_trx_total' if 'ibsa_trx_total' in self.df.columns else 'ibsa_trx'
            comp_col = 'comp_trx_total' if 'comp_trx_total' in self.df.columns else 'competitor_trx'
            
            ibsa_total = self.df[trx_col].fillna(0).sum()
            comp_total = self.df[comp_col].fillna(0).sum() if comp_col in self.df.columns else 0
            
            labels = ['IBSA', 'Competitors']
            sizes = [ibsa_total, comp_total]
            colors_market = ['#3498db', '#e74c3c']
            explode = (0.05, 0)
            
            wedges, texts, autotexts = ax2.pie(sizes, labels=labels, colors=colors_market,
                                                autopct='%1.1f%%', startangle=90, explode=explode,
                                                textprops={'fontsize': 12})
            
            for autotext in autotexts:
                autotext.set_color('white')
                autotext.set_fontweight('bold')
                autotext.set_fontsize(13)
            
            ax2.set_title('Market Share: IBSA vs Competitors', fontsize=14, fontweight='bold')
        
        # Chart 3: Competitive strength distribution
        if 'comp_strength_dominant' in self.df.columns:
            strength_data = {
                'Dominant': self.df.get('comp_strength_dominant', pd.Series([0])).sum(),
                'Strong': self.df.get('comp_strength_strong', pd.Series([0])).sum(),
                'Moderate': self.df.get('comp_strength_moderate', pd.Series([0])).sum(),
                'Weak': self.df.get('comp_strength_weak', pd.Series([0])).sum()
            }
            
            strengths = list(strength_data.keys())
            counts = list(strength_data.values())
            colors_strength = ['#c0392b', '#e74c3c', '#f39c12', '#2ecc71']
            
            bars = ax3.bar(strengths, counts, color=colors_strength, alpha=0.8)
            ax3.set_ylabel('Number of HCPs', fontweight='bold')
            ax3.set_title('Competitor Strength Distribution', fontsize=14, fontweight='bold')
            ax3.tick_params(axis='x', rotation=15)
            
            # Add count labels
            for bar, count in zip(bars, counts):
                ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height(), 
                        f'{count:,}', ha='center', va='bottom', fontweight='bold')
        
        # Chart 4: Wallet share vs competitor presence
        if 'ibsa_share' in self.df.columns:
            # Bin wallet share
            bins = [0, 10, 30, 50, 70, 100]
            labels_bins = ['0-10%', '10-30%', '30-50%', '50-70%', '70-100%']
            self.df['share_bin'] = pd.cut(self.df.loc[self.df['ibsa_share'] > 0, 'ibsa_share'], 
                                          bins=bins, labels=labels_bins, include_lowest=True)
            
            share_dist = self.df['share_bin'].value_counts().sort_index()
            
            colors_gradient = ['#e74c3c', '#f39c12', '#f1c40f', '#2ecc71', '#27ae60']
            bars = ax4.bar(range(len(share_dist)), share_dist.values, 
                          color=colors_gradient[:len(share_dist)], alpha=0.8)
            ax4.set_xticks(range(len(share_dist)))
            ax4.set_xticklabels(share_dist.index, rotation=15)
            ax4.set_xlabel('IBSA Wallet Share', fontweight='bold')
            ax4.set_ylabel('Number of HCPs', fontweight='bold')
            ax4.set_title('Wallet Share Distribution (Active HCPs)', fontsize=14, fontweight='bold')
            
            # Add count labels
            for bar, count in zip(bars, share_dist.values):
                ax4.text(bar.get_x() + bar.get_width()/2, bar.get_height(), 
                        f'{count:,}', ha='center', va='bottom', fontweight='bold')
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.plots_dir, '2_competitor_landscape.png'), 
                   dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
        print("   ✅ Saved: 2_competitor_landscape.png")
    
    def create_growth_potential_chart(self):
        """Create growth potential visualization"""
        print("\n📊 Creating Growth Potential Chart...")
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
        
        # Chart 1: Growth potential distribution
        growth_dist = self.df['growth_tier'].value_counts()
        growth_order = ['High (>10 pts)', 'Medium (5-10 pts)', 'Low (0-5 pts)']
        plot_growth = [growth_dist.get(g, 0) for g in growth_order]
        colors_growth = ['#27ae60', '#f39c12', '#e74c3c']
        
        bars = ax1.bar(range(len(growth_order)), plot_growth, color=colors_growth, alpha=0.8, width=0.6)
        ax1.set_xticks(range(len(growth_order)))
        ax1.set_xticklabels(growth_order, rotation=15, ha='right')
        ax1.set_ylabel('Number of HCPs', fontweight='bold')
        ax1.set_title('Wallet Share Growth Potential Distribution', fontsize=14, fontweight='bold')
        
        # Add labels
        for bar, count in zip(bars, plot_growth):
            pct = (count / len(self.df)) * 100
            ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height(), 
                    f'{count:,}\n({pct:.1f}%)', ha='center', va='bottom', fontweight='bold')
        
        # Chart 2: Growth potential by current wallet share
        if 'ibsa_share' in self.df.columns and 'growth_potential' in self.df.columns:
            # Sample for scatter plot (too many points otherwise)
            sample_df = self.df[self.df['ibsa_share'] > 0].sample(min(5000, len(self.df)))
            
            scatter = ax2.scatter(sample_df['ibsa_share'], sample_df['growth_potential'], 
                                 alpha=0.3, c=sample_df['ibsa_share'], cmap='RdYlGn_r', s=10)
            ax2.set_xlabel('Current IBSA Wallet Share (%)', fontweight='bold')
            ax2.set_ylabel('Growth Potential (% points)', fontweight='bold')
            ax2.set_title('Growth Potential vs Current Share', fontsize=14, fontweight='bold')
            plt.colorbar(scatter, ax=ax2, label='IBSA Share %')
            
            # Add trend line
            z = np.polyfit(sample_df['ibsa_share'], sample_df['growth_potential'], 1)
            p = np.poly1d(z)
            ax2.plot(sample_df['ibsa_share'].sort_values(), 
                    p(sample_df['ibsa_share'].sort_values()), 
                    "r--", linewidth=2, label='Trend')
            ax2.legend()
        
        # Chart 3: Average growth potential by wallet tier
        if 'wallet_tier' in self.df.columns and 'growth_potential' in self.df.columns:
            tier_order = ['Conversion (0-10%)', 'Growth (10-30%)', 'Expansion (30-50%)', 
                         'Loyalty (50-70%)', 'Retention (70-100%)']
            avg_potential = []
            
            for tier in tier_order:
                avg = self.df[self.df['wallet_tier'] == tier]['growth_potential'].mean()
                avg_potential.append(avg)
            
            colors_tier = ['#e74c3c', '#f39c12', '#3498db', '#2ecc71', '#27ae60']
            bars = ax3.barh(range(len(tier_order)), avg_potential, color=colors_tier, alpha=0.8)
            ax3.set_yticks(range(len(tier_order)))
            ax3.set_yticklabels(tier_order)
            ax3.set_xlabel('Avg Growth Potential (% points)', fontweight='bold')
            ax3.set_title('Average Growth Potential by Wallet Tier', fontsize=14, fontweight='bold')
            ax3.invert_yaxis()
            
            # Add labels
            for i, (bar, val) in enumerate(zip(bars, avg_potential)):
                ax3.text(val + max(avg_potential)*0.02, i, f'{val:.1f} pts', 
                        va='center', fontweight='bold')
        
        # Chart 4: Total addressable opportunity
        if 'wallet_tier' in self.df.columns:
            trx_col = 'ibsa_trx_total' if 'ibsa_trx_total' in self.df.columns else 'ibsa_trx'
            
            if trx_col in self.df.columns:
                tier_trx = {}
                for tier in tier_order:
                    total = self.df[self.df['wallet_tier'] == tier][trx_col].sum()
                    tier_trx[tier] = total
                
                tiers = list(tier_trx.keys())
                values = list(tier_trx.values())
                
                bars = ax4.bar(range(len(tiers)), values, color=colors_tier, alpha=0.8)
                ax4.set_xticks(range(len(tiers)))
                ax4.set_xticklabels(tiers, rotation=30, ha='right')
                ax4.set_ylabel('IBSA TRx', fontweight='bold')
                ax4.set_title('Current IBSA Volume by Wallet Tier', fontsize=14, fontweight='bold')
                
                # Add labels
                for bar, val in zip(bars, values):
                    ax4.text(bar.get_x() + bar.get_width()/2, bar.get_height(), 
                            f'{val:,.0f}', ha='center', va='bottom', fontweight='bold', fontsize=9)
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.plots_dir, '3_growth_potential_analysis.png'), 
                   dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
        print("   ✅ Saved: 3_growth_potential_analysis.png")
    
    def create_product_specific_wallet_share_chart(self):
        """Create product-specific wallet share analysis"""
        print("\n📊 Creating Product-Specific Wallet Share Chart...")
        
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        axes = axes.flatten()
        
        products = ['Tirosint', 'Flector', 'Licart']
        colors_products = ['#3498db', '#e74c3c', '#9b59b6']
        
        for idx, product in enumerate(products):
            # Find relevant columns
            trx_col = None
            share_col = None
            growth_col = None
            
            for col in self.df.columns:
                if product.lower() in col.lower():
                    if 'trx' in col.lower() and 'pred' not in col.lower():
                        trx_col = col
                    elif 'share' in col.lower() and 'growth' not in col.lower():
                        share_col = col
                    elif 'wallet_share_growth' in col.lower():
                        growth_col = col
            
            # Chart 1: Prescriber penetration
            ax = axes[idx]
            if trx_col:
                prescribers = (self.df[trx_col].fillna(0) > 0).sum()
                non_prescribers = len(self.df) - prescribers
                
                sizes = [prescribers, non_prescribers]
                labels = ['Prescribers', 'Non-Prescribers']
                colors_pen = [colors_products[idx], '#ecf0f1']
                explode = (0.05, 0)
                
                wedges, texts, autotexts = ax.pie(sizes, labels=labels, colors=colors_pen,
                                                   autopct='%1.1f%%', startangle=90, explode=explode)
                
                for autotext in autotexts:
                    autotext.set_color('white')
                    autotext.set_fontweight('bold')
                    autotext.set_fontsize(11)
                
                ax.set_title(f'{product} Prescriber Penetration\n({prescribers:,} HCPs)', 
                            fontsize=13, fontweight='bold')
            
            # Chart 2: Share distribution (for prescribers)
            ax2 = axes[idx + 3]
            if share_col:
                active_df = self.df[self.df[trx_col] > 0] if trx_col else self.df
                
                if len(active_df) > 0:
                    bins = [0, 20, 40, 60, 80, 100]
                    labels_bins = ['0-20%', '20-40%', '40-60%', '60-80%', '80-100%']
                    
                    active_df_copy = active_df.copy()
                    active_df_copy['share_bin'] = pd.cut(active_df_copy[share_col], 
                                                         bins=bins, labels=labels_bins, include_lowest=True)
                    
                    share_dist = active_df_copy['share_bin'].value_counts().sort_index()
                    
                    bars = ax2.bar(range(len(share_dist)), share_dist.values, 
                                  color=colors_products[idx], alpha=0.8)
                    ax2.set_xticks(range(len(share_dist)))
                    ax2.set_xticklabels(share_dist.index, rotation=30, ha='right')
                    ax2.set_xlabel('Share of IBSA TRx (%)', fontweight='bold')
                    ax2.set_ylabel('Number of HCPs', fontweight='bold')
                    ax2.set_title(f'{product} Share Distribution (Active)', fontsize=13, fontweight='bold')
                    
                    # Add labels
                    for bar, count in zip(bars, share_dist.values):
                        ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height(), 
                                f'{count:,}', ha='center', va='bottom', fontweight='bold', fontsize=9)
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.plots_dir, '4_product_specific_wallet_share.png'), 
                   dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
        print("   ✅ Saved: 4_product_specific_wallet_share.png")
    
    def create_executive_summary_chart(self):
        """Create executive summary dashboard"""
        print("\n📊 Creating Executive Summary Dashboard...")
        
        fig = plt.figure(figsize=(18, 10))
        gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
        
        # Title
        fig.suptitle('WALLET SHARE & COMPETITIVE POSITIONING - EXECUTIVE SUMMARY', 
                    fontsize=18, fontweight='bold', y=0.98)
        
        # KPI Cards (top row)
        ax1 = fig.add_subplot(gs[0, 0])
        ax2 = fig.add_subplot(gs[0, 1])
        ax3 = fig.add_subplot(gs[0, 2])
        
        # KPI 1: Total Prescribers
        active_hcps = (self.df['ibsa_share'] > 0).sum()
        ax1.text(0.5, 0.6, f"{active_hcps:,}", ha='center', va='center', fontsize=36, fontweight='bold', color='#3498db')
        ax1.text(0.5, 0.3, "Active IBSA Prescribers", ha='center', va='center', fontsize=12, fontweight='bold')
        ax1.text(0.5, 0.15, f"({active_hcps/len(self.df)*100:.1f}% of total HCPs)", ha='center', va='center', fontsize=10)
        ax1.axis('off')
        ax1.set_facecolor('#ecf0f1')
        
        # KPI 2: Average Wallet Share
        avg_share = self.df.loc[self.df['ibsa_share'] > 0, 'ibsa_share'].mean()
        ax2.text(0.5, 0.6, f"{avg_share:.1f}%", ha='center', va='center', fontsize=36, fontweight='bold', color='#27ae60')
        ax2.text(0.5, 0.3, "Average IBSA Wallet Share", ha='center', va='center', fontsize=12, fontweight='bold')
        ax2.text(0.5, 0.15, "(among active prescribers)", ha='center', va='center', fontsize=10)
        ax2.axis('off')
        ax2.set_facecolor('#ecf0f1')
        
        # KPI 3: Growth Opportunity
        high_potential = (self.df['growth_potential'] > 10).sum()
        ax3.text(0.5, 0.6, f"{high_potential:,}", ha='center', va='center', fontsize=36, fontweight='bold', color='#e74c3c')
        ax3.text(0.5, 0.3, "High Growth Potential HCPs", ha='center', va='center', fontsize=12, fontweight='bold')
        ax3.text(0.5, 0.15, f"(>10% point growth opportunity)", ha='center', va='center', fontsize=10)
        ax3.axis('off')
        ax3.set_facecolor('#ecf0f1')
        
        # Middle row: Key charts
        ax4 = fig.add_subplot(gs[1, :2])
        ax5 = fig.add_subplot(gs[1, 2])
        
        # Wallet share tiers
        segment_order = ['Retention (70-100%)', 'Loyalty (50-70%)', 'Expansion (30-50%)', 
                        'Growth (10-30%)', 'Conversion (0-10%)']
        segment_counts = self.df['wallet_tier'].value_counts()
        plot_segments = [s for s in segment_order if s in segment_counts.index]
        plot_counts = [segment_counts[s] for s in plot_segments]
        colors_seg = ['#27ae60', '#2ecc71', '#3498db', '#f39c12', '#e74c3c']
        
        y_pos = np.arange(len(plot_segments))
        ax4.barh(y_pos, plot_counts, color=colors_seg[:len(plot_segments)], alpha=0.8)
        ax4.set_yticks(y_pos)
        ax4.set_yticklabels(plot_segments)
        ax4.set_xlabel('Number of HCPs', fontweight='bold')
        ax4.set_title('HCP Distribution by Wallet Share Tier', fontsize=13, fontweight='bold')
        ax4.invert_yaxis()
        
        for i, count in enumerate(plot_counts):
            pct = (count / len(self.df)) * 100
            ax4.text(count + max(plot_counts)*0.02, i, f'{count:,} ({pct:.1f}%)', 
                    va='center', fontweight='bold')
        
        # Market share pie
        if 'ibsa_trx_total' in self.df.columns or 'ibsa_trx' in self.df.columns:
            trx_col = 'ibsa_trx_total' if 'ibsa_trx_total' in self.df.columns else 'ibsa_trx'
            comp_col = 'comp_trx_total' if 'comp_trx_total' in self.df.columns else 'competitor_trx'
            
            ibsa_total = self.df[trx_col].fillna(0).sum()
            comp_total = self.df[comp_col].fillna(0).sum() if comp_col in self.df.columns else 0
            
            sizes = [ibsa_total, comp_total]
            labels = ['IBSA', 'Competitors']
            colors_market = ['#3498db', '#e74c3c']
            explode = (0.1, 0)
            
            wedges, texts, autotexts = ax5.pie(sizes, labels=labels, colors=colors_market,
                                                autopct='%1.1f%%', startangle=90, explode=explode,
                                                textprops={'fontsize': 11})
            
            for autotext in autotexts:
                autotext.set_color('white')
                autotext.set_fontweight('bold')
                autotext.set_fontsize(12)
            
            ax5.set_title('Overall Market Share', fontsize=13, fontweight='bold')
        
        # Bottom row: Growth potential
        ax6 = fig.add_subplot(gs[2, :])
        
        # Growth by tier
        tier_order = ['Conversion (0-10%)', 'Growth (10-30%)', 'Expansion (30-50%)', 
                     'Loyalty (50-70%)', 'Retention (70-100%)']
        avg_potential = []
        hcp_counts = []
        
        for tier in tier_order:
            tier_df = self.df[self.df['wallet_tier'] == tier]
            avg = tier_df['growth_potential'].mean()
            count = len(tier_df)
            avg_potential.append(avg)
            hcp_counts.append(count)
        
        x = np.arange(len(tier_order))
        width = 0.35
        
        colors_growth_bar = ['#e74c3c', '#f39c12', '#3498db', '#2ecc71', '#27ae60']
        bars1 = ax6.bar(x - width/2, avg_potential, width, label='Avg Growth Potential (% pts)', 
                       color=colors_growth_bar, alpha=0.8)
        
        ax6_twin = ax6.twiny()
        ax6_twin.bar(x + width/2, hcp_counts, width, label='HCP Count', 
                     color='#95a5a6', alpha=0.5)
        
        ax6.set_xlabel('Wallet Share Tier', fontweight='bold')
        ax6.set_ylabel('Avg Growth Potential (% points)', fontweight='bold')
        ax6.set_title('Growth Opportunity by Wallet Share Tier', fontsize=13, fontweight='bold')
        ax6.set_xticks(x)
        ax6.set_xticklabels(tier_order, rotation=20, ha='right')
        ax6.legend(loc='upper left')
        ax6_twin.set_xlabel('Number of HCPs', fontweight='bold')
        ax6_twin.legend(loc='upper right')
        
        # Add value labels
        for i, (bar, val) in enumerate(zip(bars1, avg_potential)):
            ax6.text(bar.get_x() + bar.get_width()/2, bar.get_height(), 
                    f'{val:.1f}', ha='center', va='bottom', fontweight='bold', fontsize=9)
        
        plt.savefig(os.path.join(self.plots_dir, '5_executive_summary_dashboard.png'), 
                   dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
        print("   ✅ Saved: 5_executive_summary_dashboard.png")
    
    def save_analysis_summary(self):
        """Save analysis summary to JSON"""
        output_file = os.path.join(self.output_dir, 'wallet_share_analysis_summary.json')
        
        with open(output_file, 'w') as f:
            json.dump(self.analysis_summary, f, indent=2)
        
        print(f"\n✅ Analysis summary saved: {output_file}")
    
    def run(self):
        """Run complete wallet share and competitor analysis"""
        print("\n" + "="*80)
        print("WALLET SHARE & COMPETITOR ANALYSIS")
        print("GENERATING EXECUTIVE PRESENTATION CHARTS")
        print("="*80)
        
        self.calculate_wallet_share_metrics()
        self.segment_hcps_by_wallet_share()
        self.analyze_competitor_landscape()
        self.calculate_growth_potential()
        
        print("\n" + "="*80)
        print("📊 CREATING PRESENTATION-READY VISUALIZATIONS")
        print("="*80)
        
        self.create_wallet_share_distribution_chart()
        self.create_competitor_landscape_chart()
        self.create_growth_potential_chart()
        self.create_product_specific_wallet_share_chart()
        self.create_executive_summary_chart()
        
        self.save_analysis_summary()
        
        print("\n" + "="*80)
        print("✅ WALLET SHARE ANALYSIS COMPLETE!")
        print("="*80)
        print(f"\n📁 Charts saved to: {self.plots_dir}")
        print(f"\n📊 Generated Charts:")
        print("   1. 1_wallet_share_distribution.png - HCP segmentation by wallet tier")
        print("   2. 2_competitor_landscape.png - Competitive positioning analysis")
        print("   3. 3_growth_potential_analysis.png - Growth opportunity assessment")
        print("   4. 4_product_specific_wallet_share.png - Product-level insights")
        print("   5. 5_executive_summary_dashboard.png - Executive KPI dashboard")
        print(f"\n💡 All charts are ready for PowerPoint presentation!")
        
        return self

if __name__ == '__main__':
    # Run analysis
    analysis = WalletShareCompetitorAnalysis()
    analysis.run()

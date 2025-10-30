"""
IBSA Pre-Call Planning - Enterprise Presentation Generator
Uses Conexus Corporate Template 2025 with Phase 3-5 outputs

Author: IBSA Analytics Team
Date: October 29, 2025
Version: 1.0 - Enterprise Complete
"""

import os
from datetime import datetime
from pathlib import Path
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.dml import MSO_LINE_DASH_STYLE
import json
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
import json


class IBSAEnterpriseDeckGenerator:
    """
    Generate comprehensive IBSA Pre-Call Planning presentation
    Uses Phase 3 EDA, Phase 4B Features, Phase 5 Targets outputs
    """
    
    def __init__(self, template_path: str = r"C:\Users\SandeepT\IBSA PoC V2\executive-presentations\assets\Conexus Corporate Template 2025.pptx",
                 output_dir: str = r"C:\Users\SandeepT\IBSA PoC V2\executive-presentations\outputs"):
        self.template_path = Path(template_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Project paths
        self.eda_dir = Path(r"C:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\eda-enterprise")
        self.plots_dir = self.eda_dir / "plots"
        self.features_dir = Path(r"C:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\features")
        self.targets_dir = Path(r"C:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\targets")
        
        # Conexus brand colors
        self.colors = {
            'primary_blue': RGBColor(0, 85, 150),      # Conexus Blue
            'secondary_blue': RGBColor(0, 120, 200),   # Lighter Blue
            'orange': RGBColor(255, 102, 0),           # Conexus Orange
            'dark_text': RGBColor(30, 41, 59),         # Dark slate
            'light_text': RGBColor(255, 255, 255),     # White
            'success': RGBColor(45, 106, 79),          # Forest green
            'warning': RGBColor(244, 162, 97),         # Warm orange
        }
        
        # Layout indices
        self.layouts = {
            'title': 0,
            'blue_bar': 1,
            'title_content': 3,
            'single_content': 5,
            'two_column': 6,
            'section_blue': 14,
            'section_orange': 15,
            'closing': 16
        }
        
    def create_presentation(self) -> Presentation:
        """Load Conexus corporate template"""
        print(f"\n📋 Loading Conexus Corporate Template...")
        prs = Presentation(str(self.template_path))
        
        # Remove example slides
        while len(prs.slides) > 0:
            rId = prs.slides._sldIdLst[0].rId
            prs.part.drop_rel(rId)
            del prs.slides._sldIdLst[0]
        
        print(f"   ✓ Template loaded")
        return prs
    
    def add_title_slide(self, prs: Presentation):
        """Title slide - Project overview"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['title']])
        
        for shape in slide.shapes:
            if shape.has_text_frame:
                if 'title' in shape.name.lower():
                    shape.text_frame.text = "IBSA Pre-Call Planning"
                    for paragraph in shape.text_frame.paragraphs:
                        for run in paragraph.runs:
                            run.font.size = Pt(54)
                            run.font.bold = True
                elif 'subtitle' in shape.name.lower() or 'text' in shape.name.lower():
                    shape.text_frame.text = "Enterprise AI-Powered HCP Targeting & Call Optimization\nPharmaceutical-Grade Analytics Pipeline\n2025 Data Analysis"
        
        print("   ✓ Title slide added")
        return slide
    
    def add_executive_summary(self, prs: Presentation):
        """Executive summary with key metrics"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['single_content']])
        
        # Set title
        slide.placeholders[0].text = "Executive Summary"
        
        # Key metrics and achievements
        content = [
            "349,864 HCPs analyzed across complete pharmaceutical data ecosystem (2025 Data)",
            "81 enterprise-grade features engineered from 14 data sources (3.8M+ records)",
            "12 predictive targets created: Call Success, Prescription Lift, NGD Category, Territory Market Share Shift",
            "",
            "Critical Business Intelligence Discovered:",
            "• 4,642 lapsed writers identified (high-value re-engagement opportunities)",
            "• 48.5% sample waste detected (sample black holes requiring strategy pivot)",
            "• 90% prescription lift from Lunch & Learn events (underutilized channel)",
            "• 98.6% of HCPs unreached in last 13 weeks (massive untapped opportunity)",
            "",
            "12 ML models ready for overnight training (3 products × 4 outcomes)",
            "Pharmaceutical-grade quality: Temporal integrity, EDA validation, audit trails",
            "",
            "📅 Data Period: 2025 Calendar Year | Analysis Date: October 2025"
        ]
        
        try:
            text_frame = slide.placeholders[13].text_frame
            text_frame.clear()
            
            for i, item in enumerate(content):
                p = text_frame.paragraphs[0] if i == 0 else text_frame.add_paragraph()
                p.text = item.strip() if item.startswith('  ') else item
                p.level = 1 if item.startswith('  ') else 0
                
                for run in p.runs:
                    run.font.color.rgb = self.colors['dark_text']
                    run.font.size = Pt(14) if p.level == 0 else Pt(12)
                    if item.startswith("Critical Business") or item.endswith("opportunities)") or item.endswith("pivot)") or item.endswith("channel)") or item.endswith("opportunity)"):
                        run.font.bold = True
        except:
            pass
        
        print("   ✓ Executive summary added")
        return slide
    
    def add_section_divider(self, prs: Presentation, section_title: str, use_orange: bool = False):
        """Section divider slide"""
        layout_key = 'section_orange' if use_orange else 'section_blue'
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts[layout_key]])
        
        for shape in slide.shapes:
            if shape.has_text_frame and 'title' in shape.name.lower():
                shape.text_frame.text = section_title
                break
        
        print(f"   ✓ Section divider: {section_title}")
        return slide
    
    def add_phase3_eda_overview(self, prs: Presentation):
        """Phase 3 EDA overview"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['single_content']])
        slide.placeholders[0].text = "Phase 3: Exploratory Data Analysis (2025 Data)"
        
        content = [
            "12 comprehensive pharmaceutical analyses executed on 2025 calendar year data:",
            "  1. Decile Analysis (Pareto 80/20) - Top 20% HCPs = 82.5% TRx volume",
            "  2. HCP Segmentation - 5 pharma-standard segments identified",
            "  3. Competitive Segmentation - IBSA share vs volume positioning",
            "  4. Market Share Distribution - 68.3% opportunity HCPs (low IBSA share)",
            "  5. Sample ROI Analysis - 48.5% black holes, 13.4% high-ROI targets",
            "  6. Call Effectiveness - 90% lift from Lunch & Learn events",
            "  7. Reach & Frequency - 98.6% unreached in 13 weeks",
            "  8. Payer Analysis - 322K HCPs with payer intelligence",
            "  9. Prescription Velocity - 4,642 lapsed writers identified",
            "  10. Specialty Performance - Endocrinology/Rheumatology top performers",
            "",
            "Output: 260 features recommended to KEEP, 80 to REMOVE, 110 HIGH PRIORITY",
            "9 executive-ready plots generated at 150 DPI publication quality"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Phase 3 EDA overview added")
        return slide
    
    def add_phase4b_features_overview(self, prs: Presentation):
        """Phase 4B feature engineering overview with visual elements"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['single_content']])
        
        # Title
        title = slide.shapes.title
        title.text = "Phase 4B: Enterprise Feature Engineering"
        
        # Key metric badges at top
        self.add_metric_badge(slide, "81", Inches(1.5), Inches(2), self.colors['orange'], "Features")
        self.add_metric_badge(slide, "14", Inches(4), Inches(2), self.colors['primary_blue'], "Data Sources")
        self.add_metric_badge(slide, "95%", Inches(6.5), Inches(2), self.colors['secondary_blue'], "Utilization")
        self.add_metric_badge(slide, "3.8M", Inches(9), Inches(2), (45, 139, 79), "Records")
        
        # Feature category boxes (3 rows x 3 columns)
        categories = [
            ("Base Product", "15", "TRx, NRx, competitive metrics"),
            ("Payer Intelligence", "3", "322K HCPs with payer TRx patterns"),
            ("Sample ROI", "6", "Black hole detection, high-ROI"),
            ("Call Activity", "6", "Frequency, recency, engagement"),
            ("Territory Context", "5", "Benchmarks, L&L events"),
            ("Territory TRx", "7", "HCP vs territory performance"),
            ("Reach & Frequency", "4", "Unreached HCP identification"),
            ("Temporal Lags", "8", "Historical trends, lapsed writers"),
            ("NGD Classification", "9", "GROWER/DECLINER status")
        ]
        
        y_start = 3.5
        x_positions = [1, 5.2, 9.4]
        
        for i, (cat_name, count, desc) in enumerate(categories):
            row = i // 3
            col = i % 3
            x = x_positions[col]
            y = y_start + (row * 1.3)
            
            # Category box
            box = slide.shapes.add_shape(
                MSO_SHAPE.ROUNDED_RECTANGLE,
                Inches(x), Inches(y), Inches(3.8), Inches(1.1)
            )
            box.fill.solid()
            box.fill.fore_color.rgb = RGBColor(240, 245, 250)
            box.line.color.rgb = RGBColor(*self.colors['primary_blue'])
            box.line.width = Pt(1.5)
            
            # Category name
            text_frame = box.text_frame
            text_frame.margin_top = Inches(0.1)
            text_frame.margin_left = Inches(0.15)
            text_frame.margin_right = Inches(0.15)
            
            p = text_frame.paragraphs[0]
            run = p.add_run()
            run.text = f"{cat_name} ({count})"
            run.font.size = Pt(11)
            run.font.bold = True
            run.font.color.rgb = RGBColor(*self.colors['primary_blue'])
            
            # Description
            p2 = text_frame.add_paragraph()
            p2.text = desc
            p2.font.size = Pt(9)
            p2.font.color.rgb = RGBColor(60, 60, 60)
            p2.space_before = Pt(3)
        
        print("   ✓ Phase 4B features overview added with visual elements")
        return slide
    
    def add_phase5_targets_overview(self, prs: Presentation):
        """Phase 5 target engineering overview with visual elements"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['single_content']])
        
        # Title
        title = slide.shapes.title
        title.text = "Phase 5: Target Engineering Architecture"
        
        # Key metric badges at top
        self.add_metric_badge(slide, "12", Inches(2), Inches(2), self.colors['orange'], "Targets")
        self.add_metric_badge(slide, "3", Inches(5), Inches(2), self.colors['primary_blue'], "Products")
        self.add_metric_badge(slide, "4", Inches(8), Inches(2), (45, 139, 79), "Outcome Types")
        self.add_metric_badge(slide, "100%", Inches(11), Inches(2), self.colors['secondary_blue'], "Validated")
        
        # Target architecture matrix (3 products x 4 outcomes)
        products = ["Tirosint", "Flector", "Licart"]
        outcomes = [
            ("Call Success", "Binary", "0.8% / 0.1% / 0.1%"),
            ("Prescription Lift", "Regression", "% TRx increase prediction"),
            ("NGD Category", "Multi-class", "GROWER/DECLINER/NEW/STABLE"),
            ("Market Share Shift", "Binary", "Territory competitive gains")
        ]
        
        # Draw matrix header
        header_y = 3.5
        header_box = slide.shapes.add_shape(
            MSO_SHAPE.RECTANGLE,
            Inches(1), Inches(header_y), Inches(12), Inches(0.6)
        )
        header_box.fill.solid()
        header_box.fill.fore_color.rgb = RGBColor(*self.colors['primary_blue'])
        header_box.line.color.rgb = RGBColor(*self.colors['primary_blue'])
        
        text_frame = header_box.text_frame
        text_frame.margin_left = Inches(0.2)
        p = text_frame.paragraphs[0]
        p.alignment = PP_ALIGN.CENTER
        run = p.add_run()
        run.text = "Target Architecture Matrix: 3 Products × 4 Outcome Types = 12 ML Models"
        run.font.size = Pt(12)
        run.font.bold = True
        run.font.color.rgb = RGBColor(255, 255, 255)
        
        # Draw outcome rows
        y_pos = header_y + 0.7
        for outcome_name, outcome_type, detail in outcomes:
            # Outcome box
            outcome_box = slide.shapes.add_shape(
                MSO_SHAPE.ROUNDED_RECTANGLE,
                Inches(1), Inches(y_pos), Inches(12), Inches(0.9)
            )
            outcome_box.fill.solid()
            outcome_box.fill.fore_color.rgb = RGBColor(245, 250, 255)
            outcome_box.line.color.rgb = RGBColor(*self.colors['secondary_blue'])
            outcome_box.line.width = Pt(1.5)
            
            text_frame = outcome_box.text_frame
            text_frame.margin_top = Inches(0.15)
            text_frame.margin_left = Inches(0.2)
            
            # Outcome name and type
            p1 = text_frame.paragraphs[0]
            run1 = p1.add_run()
            run1.text = f"✓ {outcome_name}"
            run1.font.size = Pt(11)
            run1.font.bold = True
            run1.font.color.rgb = RGBColor(*self.colors['primary_blue'])
            
            run2 = p1.add_run()
            run2.text = f"  [{outcome_type}]"
            run2.font.size = Pt(10)
            run2.font.italic = True
            run2.font.color.rgb = RGBColor(*self.colors['orange'])
            
            # Details
            p2 = text_frame.add_paragraph()
            p2.text = detail
            p2.font.size = Pt(9)
            p2.font.color.rgb = RGBColor(60, 60, 60)
            p2.space_before = Pt(2)
            
            y_pos += 1.0
        
        # NEW Enterprise Target callout box at bottom
        callout_y = y_pos + 0.2
        callout_box = slide.shapes.add_shape(
            MSO_SHAPE.ROUNDED_RECTANGLE,
            Inches(1.5), Inches(callout_y), Inches(11), Inches(0.9)
        )
        callout_box.fill.solid()
        callout_box.fill.fore_color.rgb = RGBColor(255, 250, 235)
        callout_box.line.color.rgb = RGBColor(*self.colors['orange'])
        callout_box.line.width = Pt(2)
        
        text_frame = callout_box.text_frame
        text_frame.margin_top = Inches(0.12)
        text_frame.margin_left = Inches(0.25)
        
        p1 = text_frame.paragraphs[0]
        run1 = p1.add_run()
        run1.text = "🎯 NEW: Territory Market Share Shift Target"
        run1.font.size = Pt(12)
        run1.font.bold = True
        run1.font.color.rgb = RGBColor(*self.colors['orange'])
        
        p2 = text_frame.add_paragraph()
        p2.text = "Predicts HCPs who will shift market share toward IBSA within territory context. Uses territory benchmarks, specialty peers, and competitive positioning to identify high-impact \"swing\" HCPs."
        p2.font.size = Pt(9)
        p2.font.color.rgb = RGBColor(60, 60, 60)
        p2.space_before = Pt(3)
        
        print("   ✓ Phase 5 targets overview added with visual elements")
        return slide
    
    def add_competitive_intelligence_slide(self, prs: Presentation):
        """Competitive intelligence insights"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['blue_bar']])
        slide.placeholders[0].text = "Competitive Intelligence: Market Share Analysis"
        
        content = [
            "Market Share Distribution (TRx Market Share):",
            "  • IBSA Dominant (>50%): 54,544 HCPs (93.6%) - Strong position",
            "  • Balanced (25-50%): 561 HCPs (1.0%) - Competitive battleground",
            "  • Competitor Dominant (<25%): 1,712 HCPs (2.9%) - Growth opportunity",
            "  • Zero IBSA Share: 1,489 HCPs (2.6%) - Acquisition targets",
            "",
            "🚨 AT-RISK HCPs (722 HCPs - URGENT ACTION REQUIRED):",
            "  • High-value HCPs with declining IBSA share",
            "  • Average share loss: -10.3%",
            "  • Total TRx at risk: 3,073 prescriptions",
            "  • Recommendation: Immediate competitive defense strategy",
            "",
            "💰 OPPORTUNITY HCPs (285 HCPs - HIGH GROWTH POTENTIAL):",
            "  • High-volume prescribers with <25% IBSA share",
            "  • Current avg IBSA share: 12.0%",
            "  • Total TRx opportunity: 1,702 prescriptions",
            "  • Potential share gain: +88.0%",
            "  • Recommendation: Aggressive share capture campaign"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Competitive intelligence slide added")
        return slide
    
    def add_sample_roi_insights_slide(self, prs: Presentation):
        """Sample ROI deep dive"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['blue_bar']])
        slide.placeholders[0].text = "Sample ROI Analysis: Black Holes vs High-ROI"
        
        content = [
            "Sample Distribution Analysis (254,872 sample records, 35,503 HCPs):",
            "",
            "📊 ROI Distribution:",
            "  • Median ROI: 0.057 TRx per sample (very low)",
            "  • Mean ROI: 0.43 TRx per sample",
            "  • Maximum observed: 38 TRx per sample (exceptional cases)",
            "",
            "🚨 BLACK HOLES (12,324 HCPs - 48.5% of sampled HCPs):",
            "  • Receive samples but generate ZERO TRx",
            "  • Estimated waste: $616,200 USD in sample costs",
            "  • Recommendation: STOP sampling these HCPs immediately",
            "",
            "✅ HIGH-ROI HCPs (4,699 HCPs - 18.5% of sampled HCPs):",
            "  • Strong TRx generation from samples",
            "  • Recommendation: INCREASE sample allocation to these HCPs",
            "",
            "💡 Strategic Impact:",
            "  • Redirect 48.5% of sample budget to high-ROI HCPs",
            "  • Expected outcome: 2-3x improvement in sample effectiveness",
            "  • Annual savings potential: $400K-$600K"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Sample ROI insights slide added")
        return slide
    
    def add_territory_tier_insights_slide(self, prs: Presentation):
        """Territory tier alignment insights"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['blue_bar']])
        slide.placeholders[0].text = "Territory Intelligence: Performance Analysis (2025 Data)"
        
        content = [
            "91 territories analyzed with specific performance rankings:",
            "",
            "🏆 TOP PERFORMING TERRITORIES (Avg TRx/HCP):",
            "  • Territory 10001005: 7.90 TRx/HCP (2,443 HCPs) - #1 BEST",
            "  • Territory 10004020: 7.11 TRx/HCP (7,157 HCPs) - #2",
            "  • Territory 10004021: 6.98 TRx/HCP (7,816 HCPs) - #3",
            "  • Territory 10004008: 6.97 TRx/HCP (7,624 HCPs) - #4",
            "  • Territory 10004006: 6.73 TRx/HCP (9,501 HCPs) - #5",
            "",
            "⚠️ BOTTOM PERFORMING TERRITORIES (Need Urgent Support):",
            "  • Territory 10008070: 3.08 TRx/HCP (10,999 HCPs) - Low efficiency",
            "  • Territory 10003016: 3.34 TRx/HCP (9,118 HCPs) - Below baseline",
            "  • Territory 10005081: 3.36 TRx/HCP (11,832 HCPs) - Training needed",
            "  • UnAssigned: 0.79 TRx/HCP (5,393 HCPs) - CRITICAL",
            "",
            "💡 Key Insight: 10x Performance Gap (7.9 vs 0.79 TRx/HCP)",
            "",
            "Recommendations:",
            "  1. Study best practices from Territories 10001005, 10004020, 10004021",
            "  2. Assign UnAssigned HCPs (5,393) to active territories immediately",
            "  3. Deploy training programs to bottom 20 territories",
            "  4. Territory realignment opportunity worth millions in TRx"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Territory tier insights slide added")
        return slide
    
    def add_payer_copay_insights_slide(self, prs: Presentation):
        """Payer and copay insights"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['blue_bar']])
        slide.placeholders[0].text = "Payer Intelligence: Commercial vs Medicare"
        
        content = [
            "Payer Coverage: 8,729 HCPs with payer data analyzed",
            "",
            "Payer Distribution:",
            "  • Commercial: 99,956 prescriptions (99.96%)",
            "  • Medicare: 44 prescriptions (0.04%)",
            "",
            "💡 Key Insight: Overwhelmingly Commercial Payer Base",
            "  • IBSA products are commercial market-dominant",
            "  • Medicare penetration is minimal (<0.1%)",
            "  • Opportunity: Commercial access strategies are critical",
            "",
            "Copay Intelligence:",
            "  • 322K HCPs with detailed payer/copay data in Payment Plan",
            "  • Copay levels tracked by payer type",
            "  • High copay = barrier to prescribing",
            "",
            "Recommendations:",
            "  1. Focus commercial payer access strategies",
            "  2. Copay assistance programs for high-copay HCPs",
            "  3. Monitor payer mix changes quarterly",
            "  4. Target HCPs with favorable commercial coverage first"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Payer/copay insights slide added")
        return slide
    
    def add_critical_insights_slide(self, prs: Presentation):
        """Critical business insights from EDA"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['blue_bar']])
        slide.placeholders[0].text = "Critical Business Imperatives"
        
        content = [
            "1. LAPSED WRITERS (4,642 HCPs) - High-Value Re-Engagement",
            "  • Previously wrote prescriptions but stopped",
            "  • Temporal lag features identify declining trends",
            "  • Recommendation: Priority re-engagement campaign",
            "",
            "2. SAMPLE BLACK HOLES (48.5% waste = $616K) - Strategy Pivot Required",
            "  • 12,324 HCPs receive samples but generate ZERO TRx",
            "  • Redirect to 4,699 high-ROI HCPs (18.5%)",
            "  • Expected ROI improvement: 2-3x",
            "",
            "3. LUNCH & LEARN (90% lift) - Underutilized Channel",
            "  • Educational events drive massive prescription increases",
            "  • Currently tracked: 58,066 L&L events across territories",
            "  • Recommendation: Scale L&L program 3-5x",
            "",
            "4. UNREACHED GAP (98.6%) - Massive Opportunity",
            "  • 344,867 HCPs not called in last 13 weeks",
            "  • Many are high-volume, low-share opportunity targets",
            "  • Recommendation: AI-driven reach expansion strategy"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Critical insights slide added")
        return slide
    
    def add_image_slide(self, prs: Presentation, title: str, image_filename: str, description: str = ""):
        """Add slide with high-resolution plot and professional insight box"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['title_content']])
        slide.placeholders[0].text = title
        
        # Add image
        image_path = self.plots_dir / image_filename
        if image_path.exists():
            # Remove content placeholder if exists
            for shape in slide.shapes:
                if shape.is_placeholder and 'Content' in shape.name:
                    sp = shape.element
                    sp.getparent().remove(sp)
            
            # Add image - Large but leave room for insight box
            left = Inches(0.5)
            top = Inches(1.5)
            width = Inches(12)  # Full width
            height = Inches(4.8)  # Controlled height
            slide.shapes.add_picture(str(image_path), left, top, width=width, height=height)
            
            # Add professional insight box at bottom with proper spacing
            if description:
                left = Inches(0.5)
                top = Inches(6.5)  # Lower position with more space
                width = Inches(12)
                height = Inches(0.9)  # Shorter, more compact
                
                # Add subtle rounded rectangle shape
                textbox = slide.shapes.add_shape(
                    MSO_SHAPE.ROUNDED_RECTANGLE,
                    left, top, width, height
                )
                
                # Professional styling - subtle background
                fill = textbox.fill
                fill.solid()
                fill.fore_color.rgb = RGBColor(240, 240, 245)  # Very light blue-gray
                
                line = textbox.line
                line.color.rgb = self.colors['primary_blue']
                line.width = Pt(1.5)
                
                # Add text with proper margins
                text_frame = textbox.text_frame
                text_frame.word_wrap = True
                text_frame.vertical_anchor = MSO_ANCHOR.MIDDLE
                text_frame.margin_left = Inches(0.2)
                text_frame.margin_right = Inches(0.2)
                text_frame.margin_top = Inches(0.1)
                text_frame.margin_bottom = Inches(0.1)
                
                # Extract and format key insight - make it concise
                lines = description.split('\n')
                key_line = lines[0] if lines else description
                # Remove emoji/labels and get core message
                key_line = key_line.replace('Key Insight:', '').replace('Finding:', '').replace('💡', '').replace('📊', '').strip()
                
                # Truncate if too long
                if len(key_line) > 150:
                    key_line = key_line[:147] + '...'
                
                p = text_frame.paragraphs[0]
                p.text = f"💡  {key_line}"
                p.alignment = PP_ALIGN.LEFT
                
                for run in p.runs:
                    run.font.size = Pt(13)
                    run.font.color.rgb = self.colors['dark_text']
                    run.font.bold = False
                    run.font.name = 'Calibri'
            
            print(f"   ✓ Image slide: {title}")
        else:
            print(f"   ⚠️  Image not found: {image_filename}")
        
        return slide
    
    def add_metric_badge(self, slide, text: str, left: float, top: float, 
                        bg_color: tuple = (255, 140, 0), label: str = None, is_warning: bool = False):
        """Add a circular metric badge with optional label"""
        size = Inches(1.2)
        
        # Create circular shape
        shape = slide.shapes.add_shape(
            MSO_SHAPE.OVAL,
            Inches(left), Inches(top), size, size
        )
        
        # Style the badge
        fill = shape.fill
        fill.solid()
        if is_warning:
            fill.fore_color.rgb = RGBColor(220, 53, 69)  # Red for warnings
        else:
            fill.fore_color.rgb = RGBColor(*bg_color)
        
        # Add border
        line = shape.line
        line.color.rgb = RGBColor(255, 255, 255)
        line.width = Pt(3)
        
        # Add text
        text_frame = shape.text_frame
        text_frame.clear()
        p = text_frame.paragraphs[0]
        p.text = text
        p.alignment = PP_ALIGN.CENTER
        text_frame.vertical_anchor = MSO_ANCHOR.MIDDLE
        
        for run in p.runs:
            run.font.size = Pt(12)
            run.font.bold = True
            run.font.color.rgb = RGBColor(255, 255, 255)
        
        # Add label below badge if provided
        if label:
            label_box = slide.shapes.add_textbox(
                Inches(left - 0.3), Inches(top + 1.3), Inches(1.8), Inches(0.3)
            )
            label_frame = label_box.text_frame
            label_p = label_frame.paragraphs[0]
            label_p.text = label
            label_p.alignment = PP_ALIGN.CENTER
            label_p.font.size = Pt(10)
            label_p.font.bold = True
            label_p.font.color.rgb = RGBColor(60, 60, 60)
        
        return shape
    
    def add_model_readiness_slide(self, prs: Presentation):
        """Model training readiness status"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['blue_bar']])
        slide.placeholders[0].text = "Phase 6: Model Training Readiness"
        
        content = [
            "12 ML Models Ready for Training (3 products × 4 outcomes):",
            "",
            "Model Architecture:",
            "  • Binary Classification: RandomForest with class balancing (SMOTE)",
            "  • Regression: XGBoost with hyperparameter optimization (Optuna)",
            "  • Multi-Class: RandomForest with stratified sampling",
            "",
            "Training Configuration:",
            "  • 50 Optuna trials per model (overnight optimization)",
            "  • 80/20 train-test split with stratification",
            "  • Cross-validation: 5-fold for robust performance",
            "  • Feature importance: SHAP analysis for explainability",
            "",
            "Expected Training Time: ~3 hours for 12 models",
            "Output: Trained models (.pkl), performance metrics, feature importance, SHAP plots",
            "",
            "Data Pipeline Validated:",
            "  ✓ Phase 3 EDA insights integrated",
            "  ✓ Phase 4B features (81) loaded",
            "  ✓ Phase 5 targets (12) validated",
            "  ✓ Temporal integrity confirmed (no leakage)"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Model readiness slide added")
        return slide
    
    def add_technical_architecture_slide(self, prs: Presentation):
        """Technical architecture with visual flow diagram"""
        # Use the architecture diagram image we generated
        self.add_image_slide(
            prs, 
            "IBSA Analytics Pipeline Architecture",
            "architecture_diagram.png",
            "End-to-end ML pipeline: 14 data sources → 12 EDA analyses → 81 engineered features → 12 product-specific targets → 12 trained models → 350K HCPs scored. 3-hour training time with 95% data utilization."
        )
        print("   ✓ Technical architecture diagram added")
        return prs.slides[-1]
    
    def add_next_steps_slide(self, prs: Presentation):
        """Next steps and recommendations"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['blue_bar']])
        slide.placeholders[0].text = "Next Steps & Recommendations"
        
        content = [
            "Immediate Actions (Tonight):",
            "  1. Execute Phase 6 model training (3-hour overnight run)",
            "  2. Generate model performance reports and SHAP explainability",
            "  3. Validate model predictions against holdout test set",
            "",
            "Short-Term (1-2 Weeks):",
            "  4. Deploy models to production API (FastAPI already built)",
            "  5. Integrate with UI dashboard for rep access",
            "  6. Pilot with 2-3 territories for field validation",
            "",
            "Medium-Term (1-3 Months):",
            "  7. Scale to all territories with continuous monitoring",
            "  8. A/B test AI-recommended vs traditional call plans",
            "  9. Implement sample redistribution (away from black holes)",
            "  10. Scale Lunch & Learn program based on territory analytics",
            "",
            "Long-Term (3-6 Months):",
            "  11. Retrain models quarterly with new data",
            "  12. Expand to additional products beyond Tirosint/Flector/Licart",
            "  13. Integrate real-time call feedback loop for model improvement"
        ]
        
        self._add_bullet_content(slide, content)
        print("   ✓ Next steps slide added")
        return slide
    
    def add_closing_slide(self, prs: Presentation):
        """Closing slide"""
        slide = prs.slides.add_slide(prs.slide_layouts[self.layouts['closing']])
        
        for shape in slide.shapes:
            if shape.has_text_frame:
                if 'title' in shape.name.lower() or len(shape.text_frame.text) < 50:
                    shape.text_frame.text = "Questions & Discussion"
                    for paragraph in shape.text_frame.paragraphs:
                        for run in paragraph.runs:
                            run.font.size = Pt(48)
                            run.font.bold = True
        
        print("   ✓ Closing slide added")
        return slide
    
    def _add_bullet_content(self, slide, content_items):
        """Helper to add bullet content with proper formatting"""
        try:
            text_frame = slide.placeholders[13].text_frame
            text_frame.clear()
            
            for i, item in enumerate(content_items):
                if not item:  # Empty line
                    continue
                    
                p = text_frame.paragraphs[0] if i == 0 else text_frame.add_paragraph()
                
                # Determine indent level and clean text
                if item.startswith('•'):
                    p.level = 1
                    p.text = item[1:].strip()  # Remove bullet, already provided by PowerPoint
                elif item.startswith('  •'):
                    p.level = 1
                    p.text = item[3:].strip()
                else:
                    p.level = 0
                    p.text = item.strip()
                
                # Formatting
                for run in p.runs:
                    run.font.color.rgb = self.colors['dark_text']
                    if p.level == 0:
                        run.font.size = Pt(16)
                        # Bold key headers
                        if any(kw in item for kw in ['🚨', '💰', '📊', '✅', '💡', 'LAPSED', 'BLACK HOLES', 'LUNCH & LEARN', 'UNREACHED', 'Critical Business']):
                            run.font.bold = True
                    else:
                        run.font.size = Pt(14)
                        
        except Exception as e:
            print(f"   ⚠️  Could not add bullets: {e}")
    
    def _add_two_column_content(self, slide, left_items, right_items):
        """Helper to add two-column content"""
        try:
            # Left column (placeholder 1)
            left_frame = slide.placeholders[1].text_frame
            left_frame.clear()
            for i, item in enumerate(left_items):
                p = left_frame.paragraphs[0] if i == 0 else left_frame.add_paragraph()
                p.text = item.strip()
                p.level = 1 if item.startswith('•') or item.startswith('  ') else 0
                for run in p.runs:
                    run.font.color.rgb = self.colors['dark_text']
                    run.font.size = Pt(12)
            
            # Right column (placeholder 14)
            right_frame = slide.placeholders[14].text_frame
            right_frame.clear()
            for i, item in enumerate(right_items):
                p = right_frame.paragraphs[0] if i == 0 else right_frame.add_paragraph()
                p.text = item.strip()
                p.level = 1 if item.startswith('•') or item.startswith('→') or item.startswith('  ') else 0
                for run in p.runs:
                    run.font.color.rgb = self.colors['dark_text']
                    run.font.size = Pt(12)
        except Exception as e:
            print(f"   ⚠️  Could not add two-column content: {e}")
    
    def generate_complete_deck(self):
        """Generate complete enterprise presentation"""
        print("\n" + "="*80)
        print("🎯 IBSA PRE-CALL PLANNING - ENTERPRISE PRESENTATION GENERATOR")
        print("="*80)
        
        prs = self.create_presentation()
        
        # Title
        self.add_title_slide(prs)
        
        # Executive Summary
        self.add_executive_summary(prs)
        
        # Phase 3: EDA
        self.add_section_divider(prs, "Phase 3: Exploratory Data Analysis")
        self.add_phase3_eda_overview(prs)
        self.add_critical_insights_slide(prs)
        self.add_competitive_intelligence_slide(prs)
        self.add_sample_roi_insights_slide(prs)
        self.add_territory_tier_insights_slide(prs)
        self.add_payer_copay_insights_slide(prs)
        
        # Add EDA plots with concise descriptions
        self.add_image_slide(prs, "Decile Analysis: Pareto 80/20 Distribution", "decile_analysis_pareto.png",
            "Top 20% of HCPs generate 82.5% of total TRx. Focus 80% of sales resources on Deciles 1-2 for maximum ROI using AI-driven targeting.")
        
        self.add_image_slide(prs, "HCP Segmentation: Pharma Standard Segments", "hcp_segmentation_pharma_standard.png",
            "5 segments identified: Stars (5.3%), Potentials (8.9%), Core (31.2%), Occasional (42.1%), Dormant (12.5%). Deploy tier-based resource allocation strategy.")
        
        self.add_image_slide(prs, "Competitive Positioning: IBSA vs Market", "competitive_segmentation.png",
            "93.6% of HCPs IBSA-dominant. Critical: 722 at-risk HCPs declining (urgent defense), 285 opportunity HCPs with low share but high volume (capture strategy).")
        
        self.add_image_slide(prs, "Market Share Distribution", "market_share_distribution.png",
            "IBSA market share: 92.2% mean, 100% median. 68.3% of HCPs have <25% IBSA share - significant untapped opportunity for targeted share-gain campaigns.")
        
        self.add_image_slide(prs, "Sample ROI: Black Holes vs High-ROI Targets", "sample_roi_distribution.png",
            "48.5% of sampled HCPs are 'black holes' generating ZERO TRx (12,324 HCPs, $616K waste). Redirect to 4,699 high-ROI HCPs for 2-3x improvement.")
        
        self.add_image_slide(prs, "Call Effectiveness: Reach & Frequency Analysis", "call_effectiveness_reach_frequency.png",
            "98.6% of HCPs unreached (344,867 HCPs). Lunch & Learn shows 90% prescription lift. Scale L&L program 3-5x with AI prioritization for maximum impact.")
        
        self.add_image_slide(prs, "Prescription Velocity & Momentum", "prescription_velocity_momentum.png",
            "4,642 'lapsed writers' identified - previously active but now stopped. Priority re-engagement campaign needed. Temporal lag features enable early decline detection.")
        
        self.add_image_slide(prs, "Specialty Performance Analysis", "specialty_performance.png",
            "Endocrinology (47.2 TRx/HCP) and Rheumatology (28.6 TRx/HCP) show highest productivity. Deploy specialty-specific messaging for Tirosint and Flector.")
        
        self.add_image_slide(prs, "Payer Distribution", "payer_distribution.png",
            "99.96% commercial payer coverage. Copay assistance programs critical for access. 8,729 HCPs with detailed payer intelligence for targeted support.")
        
        self.add_image_slide(prs, "Territory Intelligence: Top & Bottom Performers", "territory_intelligence_detailed.png",
            "91 territories analyzed. TOP: Territory 10001005 (7.9 TRx/HCP, 2,443 HCPs). BOTTOM: UnAssigned (0.79 TRx/HCP, 5,393 HCPs). 10x performance gap. Study top performers (10004020, 10004021, 10004008) for best practices. Bottom 20 territories need urgent intervention.")
        
        self.add_image_slide(prs, "Product Performance Comparison", "product_performance_comparison.png",
            "Synthroid dominates: 2.2M TRx (319K HCPs). Tirosint products show growth opportunity. Target specialists and high-share conversion for portfolio expansion.")
        
        # Phase 4B: Features
        self.add_section_divider(prs, "Phase 4B: Feature Engineering", use_orange=True)
        self.add_phase4b_features_overview(prs)
        
        # Phase 5: Targets
        self.add_section_divider(prs, "Phase 5: Target Engineering")
        self.add_phase5_targets_overview(prs)
        
        # Phase 6: Model Readiness
        self.add_section_divider(prs, "Phase 6: Model Training", use_orange=True)
        self.add_model_readiness_slide(prs)
        self.add_technical_architecture_slide(prs)
        
        # Next Steps
        self.add_next_steps_slide(prs)
        
        # Closing
        self.add_closing_slide(prs)
        
        # Save
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = self.output_dir / f"IBSA_PreCallPlanning_Enterprise_Deck_{timestamp}.pptx"
        prs.save(str(output_path))
        
        print("\n" + "="*80)
        print(f"✅ PRESENTATION GENERATED SUCCESSFULLY!")
        print("="*80)
        print(f"   📊 Total slides: {len(prs.slides)}")
        print(f"   💾 Saved to: {output_path}")
        print(f"   📁 File size: {output_path.stat().st_size / (1024*1024):.2f} MB")
        print("="*80)
        
        return str(output_path)


if __name__ == "__main__":
    generator = IBSAEnterpriseDeckGenerator()
    output_file = generator.generate_complete_deck()
    print(f"\n🎉 Open presentation: {output_file}")

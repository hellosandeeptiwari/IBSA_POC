# Enterprise PowerPoint (PPTX) Generator

**Professional presentation generator for high-end corporate decks**

## 🎯 Overview

This system generates **Microsoft PowerPoint (PPTX) files** with enterprise-grade styling, consistent with McKinsey, BCG, and Bain consulting standards. Unlike HTML presentations, PPTX files are:

- ✅ Editable in PowerPoint (full control over content)
- ✅ Native Office 365 integration
- ✅ Easy to share via email/SharePoint
- ✅ Supports animations and transitions
- ✅ Professional templates and themes

## 🚀 Quick Start

### Method 1: Direct Python Execution
```powershell
cd "c:\Users\SandeepT\NL2Q Analyst\executive-presentations"
python pptx_generator.py
```

### Method 2: Batch File Launcher
```powershell
.\launch-pptx.bat
```

### Method 3: PowerShell Script
```powershell
.\generate-pptx.ps1
```

## 📊 Generated Content

The default presentation includes **15 professional slides**:

### Section 1: Introduction
1. **Title Slide** - Power BI Integration Strategy
2. **Executive Summary** - Key highlights and business impact

### Section 2: Technical Architecture
3. **Section Divider** - Architecture Overview
4. **Integration Approaches** - Three implementation strategies
5. **Multi-Tenant Architecture** - Security and isolation model
6. **Implementation Timeline** - Phase-by-phase roadmap

### Section 3: Investment Analysis
7. **Section Divider** - Cost & Returns
8. **Investment Breakdown** - Detailed cost metrics
9. **Technical Feasibility** - Strengths and gaps
10. **Risk Assessment** - Risk matrix with mitigation

### Section 4: Business Impact
11. **Section Divider** - Business Impact
12. **Business Benefits** - Productivity and financial gains
13. **Competitive Advantage** - Market differentiation
14. **Strategic Recommendations** - Action plan

### Conclusion
15. **Closing Slide** - Q&A and contact information

## 🎨 Design Features

### Professional Typography
- **Font Family**: Inter (modern, clean, professional)
- **Title Slides**: 54pt bold
- **Content Headers**: 32pt bold
- **Body Text**: 18pt regular
- **Subtext**: 12-14pt

### Enterprise Color Palette
```
Primary:   #1a1a2e (Deep Navy)
Secondary: #16213e (Dark Blue)
Accent:    #0f3460 (Royal Blue)
Highlight: #533483 (Purple)
Success:   #2d6a4f (Forest Green)
Warning:   #f4a261 (Warm Orange)
```

### Layout Features
- **16:9 Aspect Ratio** (standard for modern displays)
- **Consistent Header Bar** on content slides
- **Slide Numbers** for easy navigation
- **Two-Column Layouts** for comparisons
- **Metric Cards** with visual hierarchy
- **Professional Tables** with alternating row colors

## 📝 Customization Guide

### 1. Edit Content
Open `pptx_generator.py` and modify the `generate_powerbi_integration_deck()` method:

```python
# Example: Add a new slide
self.add_content_slide(prs, "Your Title Here", [
    {
        'type': 'bullets',
        'items': [
            "First bullet point",
            "  Indented sub-point",
            "Second bullet point"
        ]
    }
], slide_number)
```

### 2. Change Colors
Modify the color palette in the `__init__` method:

```python
self.colors = {
    "primary": RGBColor(26, 26, 46),  # Change RGB values
    "accent": RGBColor(15, 52, 96),
    # ... other colors
}
```

### 3. Add Company Logo
```python
# In any slide creation method
logo_path = "path/to/your/logo.png"
logo = slide.shapes.add_picture(
    logo_path,
    Inches(11.5),  # Right position
    Inches(0.15),  # Top position
    height=Inches(0.5)
)
```

### 4. Create Custom Slide Types

```python
def add_custom_slide(self, prs: Presentation, title: str):
    """Your custom slide layout"""
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    
    # Add your custom elements
    # ... shapes, text boxes, images, etc.
```

## 🔧 Available Content Types

### 1. Bullet Lists
```python
{
    'type': 'bullets',
    'items': [
        "Main point",
        "  Indented point (2 spaces)",
        "Another main point"
    ]
}
```

### 2. Two-Column Layout
```python
{
    'type': 'two_column',
    'left': ["Left column item 1", "Left item 2"],
    'right': ["Right column item 1", "Right item 2"]
}
```

### 3. Metric Cards
```python
{
    'type': 'metrics',
    'metrics': [
        {'value': '$180K', 'label': 'Investment'},
        {'value': '12 weeks', 'label': 'Timeline'},
        {'value': '40%', 'label': 'ROI'}
    ]
}
```

### 4. Data Tables
```python
{
    'type': 'table',
    'headers': ['Column 1', 'Column 2', 'Column 3'],
    'rows': [
        ['Data 1A', 'Data 1B', 'Data 1C'],
        ['Data 2A', 'Data 2B', 'Data 2C']
    ]
}
```

## 📤 Export Options

### PDF Export
1. Open PPTX file in PowerPoint
2. File → Save As → PDF
3. Select quality settings
4. Save

### Google Slides
1. Upload PPTX to Google Drive
2. Right-click → Open with Google Slides
3. Automatically converts to Slides format

### Keynote (Mac)
1. Open PPTX in Keynote
2. Most formatting preserved
3. May need minor adjustments

## 🛠️ Requirements

### Python Packages
```bash
pip install python-pptx
```

### Dependencies (auto-installed)
- `python-pptx` 1.0.2+
- `Pillow` 3.3.2+ (for images)
- `lxml` 3.1.0+ (XML processing)
- `XlsxWriter` 0.5.7+ (Excel support)

## 💼 Professional Use Cases

### 1. Executive Presentations
- Board meetings
- Investor pitches
- Strategic planning sessions

### 2. Client Deliverables
- Consulting reports
- Technical proposals
- Business cases

### 3. Internal Communications
- Project updates
- Training materials
- Department reviews

### 4. Sales & Marketing
- Product demos
- Partnership proposals
- Conference presentations

## 🎓 Best Practices

### Content Guidelines
1. **One Idea Per Slide** - Keep focus clear
2. **Maximum 6 Bullets** - Avoid information overload
3. **Use Visuals** - Charts, diagrams, icons
4. **Consistent Terminology** - Use same terms throughout
5. **Action-Oriented** - Focus on recommendations

### Design Guidelines
1. **Maintain Consistency** - Same fonts, colors, layouts
2. **High Contrast** - Ensure readability
3. **White Space** - Don't overcrowd slides
4. **Professional Imagery** - High-quality photos/graphics
5. **Brand Alignment** - Match corporate identity

### Presentation Tips
1. **Rehearse** - Practice with the deck
2. **Know Your Audience** - Adjust content accordingly
3. **Time Management** - 2-3 minutes per slide
4. **Backup Plan** - PDF version ready
5. **Q&A Preparation** - Anticipate questions

## 📊 Output Structure

```
executive-presentations/
├── outputs/
│   ├── nl2q_powerbi_strategy_20251008_180646.pptx  ← Generated file
│   ├── nl2q_powerbi_strategy_20251008_174229.html  ← HTML version
│   └── ... (other presentations)
├── pptx_generator.py              ← Main generator
├── enterprise_deck_generator.py   ← HTML generator
├── PPTX_README.md                ← This file
├── README.md                      ← General docs
└── launch-pptx.bat               ← Quick launcher
```

## 🐛 Troubleshooting

### Issue: Import errors
**Solution**: Install python-pptx
```bash
pip install python-pptx
```

### Issue: Fonts not rendering correctly
**Solution**: Install Inter font family
- Download from [Google Fonts](https://fonts.google.com/specimen/Inter)
- Install on your system

### Issue: Large file size
**Solution**: Compress images before adding
```python
from PIL import Image
img = Image.open('large_image.png')
img.save('compressed.png', optimize=True, quality=85)
```

### Issue: Slides look different in PowerPoint
**Solution**: Use PowerPoint's built-in fonts
```python
p.font.name = 'Calibri'  # Instead of Inter
```

## 🔄 Version History

### Version 1.0 (October 2025)
- Initial release
- 15-slide Power BI Integration deck
- Professional styling system
- Multiple content types (bullets, tables, metrics)
- Enterprise color palette

## 📞 Support

For questions or customization requests:
- **Email**: enterprise@nl2q-analytics.com
- **Documentation**: See README.md files
- **Issues**: Check troubleshooting section

## 📄 License

Proprietary - NL2Q Analytics Team
Copyright © 2025

---

**Last Updated**: October 8, 2025  
**Version**: 1.0  
**Author**: NL2Q Analytics Team

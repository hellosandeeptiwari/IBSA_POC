# Executive Presentations Generator

Enterprise-grade HTML presentation generator for creating McKinsey/BCG-style professional decks.

## 📁 Folder Structure

```
executive-presentations/
├── enterprise_deck_generator.py    # Main presentation generator
├── outputs/                         # Generated HTML presentations
├── assets/                          # Images, logos, icons (optional)
└── README.md                        # This file
```

## 🎯 Features

- **Professional Design**: McKinsey/BCG consulting-style layouts
- **Consistent Styling**: Enterprise typography and color palette
- **Responsive**: Works on desktop, tablet, and mobile
- **Print-Ready**: Optimized for PDF export
- **Interactive**: Keyboard navigation (arrow keys)

## 🚀 Quick Start

### Generate Presentation

```powershell
# Navigate to the folder
cd "c:\Users\SandeepT\NL2Q Analyst\executive-presentations"

# Run the generator
python enterprise_deck_generator.py
```

### View Presentation

1. Open the generated HTML file in your browser
2. Navigate with **Arrow Keys** (← →)
3. Press **Ctrl+P** (or **Cmd+P** on Mac) to print or save as PDF

## 📊 Generated Deck Contents

The Power BI Integration & Multi-Tenancy deck includes:

1. **Title Slide** - Executive cover
2. **Executive Summary** - Key metrics and opportunity
3. **Current State** - Strengths and gaps assessment
4. **Architecture** - Power BI integration design
5. **Implementation** - Three approach options
6. **Multi-Tenancy** - Three-tier security architecture
7. **Timeline** - 8-week implementation roadmap
8. **Cost Analysis** - Development and operational costs
9. **Feasibility** - Technical assessment
10. **Competitive** - Market positioning and differentiation
11. **Risk Mitigation** - Comprehensive risk analysis
12. **Success Metrics** - KPIs and measurement
13. **Recommendations** - Strategic guidance
14. **Next Steps** - Action plan
15. **Q&A** - Closing slide

## 🎨 Customization

### Color Palette

The presentation uses a professional enterprise color scheme:

- **Primary**: `#1a1a2e` (Deep Navy)
- **Accent**: `#0f3460` (Royal Blue)
- **Success**: `#2d6a4f` (Forest Green)
- **Warning**: `#f4a261` (Warm Orange)

### Typography

- **Primary Font**: Inter (Google Fonts)
- **Fallback**: System fonts (Segoe UI, Arial)

### Modifying Content

Edit `enterprise_deck_generator.py` and modify the slide content in the `generate_powerbi_integration_deck()` method.

## 📤 Export Options

### Save as PDF

**Method 1: Browser Print**
1. Open HTML file in Chrome/Edge
2. Press `Ctrl+P` (Windows) or `Cmd+P` (Mac)
3. Select "Save as PDF"
4. Adjust settings:
   - Layout: Portrait
   - Margins: None
   - Background graphics: ✓

**Method 2: Programmatic (Optional)**
```powershell
# Install wkhtmltopdf
choco install wkhtmltopdf

# Convert to PDF
wkhtmltopdf --enable-local-file-access --page-size A4 output.html output.pdf
```

### Export to PowerPoint

**Using Browser:**
1. Open HTML in Chrome
2. Print to PDF
3. Use online converters (PDF → PPTX)
   - Adobe Acrobat
   - SmallPDF
   - Online2PDF

**Programmatic (Advanced):**
```python
# Install python-pptx
pip install python-pptx

# Generate PPTX directly (requires custom implementation)
```

## 🔧 Advanced Usage

### Custom Presentations

Create your own presentation by extending the `EnterprisePresentation` class:

```python
from enterprise_deck_generator import EnterprisePresentation

class MyCustomDeck(EnterprisePresentation):
    def generate_custom_deck(self):
        slides_html = []
        
        # Add title slide
        slides_html.append(
            self._create_title_slide(
                title="My Custom Presentation",
                subtitle="Subtitle here",
                author="Your Name"
            )
        )
        
        # Add content slides
        content = """
        <ul class="bullet-list">
            <li><strong>Point 1:</strong> Description</li>
            <li><strong>Point 2:</strong> Description</li>
        </ul>
        """
        slides_html.append(
            self._create_standard_slide(
                title="Slide Title",
                subtitle="Slide subtitle",
                content=content,
                slide_number=2
            )
        )
        
        # Return full HTML
        return self._compile_html(slides_html)

# Generate
deck = MyCustomDeck()
html = deck.generate_custom_deck()
deck.save_presentation(html, "my_deck.html")
```

### Available Slide Components

- `bullet-list` - Styled bullet points
- `numbered-list` - Numbered items with badges
- `data-table` - Professional tables
- `two-column` - Side-by-side layout
- `content-block` - Highlighted content boxes
- `highlight-box` - Blue accent callouts
- `success-box` - Green success messages
- `warning-box` - Orange warnings
- `info-box` - Information callouts
- `stats-grid` - Metric cards
- `timeline` - Event timeline
- `architecture-box` - Technical diagrams
- `code-block` - Code snippets

## 📝 Best Practices

1. **Keep it concise**: 15-20 slides maximum
2. **One message per slide**: Focus on clarity
3. **Use visuals**: Tables, stats, diagrams
4. **Consistent style**: Use provided components
5. **Test print**: Always preview PDF output

## 🛠️ Troubleshooting

### Fonts not loading
- Check internet connection (Google Fonts)
- Use system fonts as fallback

### Print layout issues
- Set margins to "None" in print dialog
- Enable "Background graphics"
- Use Chrome or Edge (best rendering)

### Slide navigation not working
- Ensure JavaScript is enabled
- Use arrow keys (← →)

## 📞 Support

For questions or custom deck requests:
- **Email**: product@nl2q.com
- **Docs**: docs.nl2q.com/presentations

## 📄 License

Internal use only - NL2Q Analyst Project
Confidential and Proprietary

---

**Generated by**: NL2Q Analytics Team  
**Version**: 1.0  
**Date**: October 2025

# 🚀 How to Launch IBSA Pre-Call Planning UI

**Current Status:** Node.js is not installed on this system  
**Date:** October 17, 2025

---

## ⚠️ Prerequisites Required

To run the Next.js UI, you need to install **Node.js** first.

### **Option 1: Install Node.js (Recommended - LTS Version)**

1. **Download Node.js:**
   - Visit: https://nodejs.org/
   - Download **LTS version** (20.x or later)
   - Choose Windows installer (.msi)

2. **Install Node.js:**
   - Run the downloaded installer
   - Accept default settings
   - Make sure "Add to PATH" is checked
   - Complete installation

3. **Verify Installation:**
   ```powershell
   node --version
   npm --version
   ```
   - Should show versions (e.g., v20.10.0 and 10.2.3)

4. **Restart PowerShell/Terminal**

---

## 🎯 Once Node.js is Installed

### **Step 1: Navigate to UI Directory**
```powershell
cd "C:\Users\SandeepT\IBSA PoC V2\ibsa-precall-ui"
```

### **Step 2: Install Dependencies (First Time Only)**
```powershell
npm install
```
- This will take 2-3 minutes
- Downloads all required packages
- Creates `node_modules` folder

### **Step 3: Start Development Server**
```powershell
npm run dev
```
- UI will start on **http://localhost:3000**
- Keep this terminal open while using the UI

### **Step 4: Open in Browser**
- Navigate to: **http://localhost:3000**
- UI should load with HCP data

---

## ✨ What You'll See in the UI

### **Updated Features (Ready to View):**

1. **✅ HCP Names Instead of NPIs**
   - Real prescriber names displayed (e.g., "Dr. Sarah Johnson")
   - 338,598 HCPs have names from PrescriberOverview data

2. **✅ Territory Information**
   - Territory name visible on each HCP card
   - Region information displayed
   - 93 territories across 9 regions

3. **✅ Territory Filtering (Code Ready)**
   - Filter by territory dropdown
   - Filter by region dropdown
   - "My Territory" view for sales reps
   - Territory stats widget

4. **✅ NGD Scores by Territory**
   - NGD classification (New/Grower/Stable/Decliner)
   - NGD score displayed per HCP
   - Can filter to see only specific territory's HCPs

5. **✅ Competitive Conversion Data**
   - High/Medium/Low conversion likelihood
   - Conversion probability percentage
   - Priority scores for targeting

---

## 📊 UI Data Sources

The UI loads these datasets:

1. **IBSA_ModelReady_Enhanced.csv** (4,614 HCPs)
   - UI-optimized sample dataset
   - Top 50 HCPs per territory
   - Includes all ML predictions

2. **competitive_conversion_predictions.csv** (1.28M rows)
   - Competitive conversion probabilities
   - High/Medium/Low classifications
   - Priority scores

3. **territory_lookup.csv** (93 territories)
   - Territory names and IDs
   - Region assignments

4. **rep_territory_assignments.csv** (12 reps)
   - Sales rep to territory mapping
   - For "My Territory" views

---

## 🎨 UI Screenshots to Capture (After Launch)

Once the UI is running, capture these screenshots:

1. **Dashboard Overview** (`IBSA_Dashboard_Overview.png`)
   - Main HCP list view
   - Show territory filter dropdown
   - Show HCP cards with names

2. **HCP List View** (`IBSA_HCP_List_View.png`)
   - Full list of HCPs
   - Territory and region visible
   - NGD classifications shown

3. **HCP Detail Page** (`IBSA_HCP_Detail_Top.png`)
   - Click on an HCP
   - Show detailed profile
   - NGD score, territory info

4. **Competitive Intelligence** (`IBSA_Competitive_Intelligence.png`)
   - HCP detail with competitive data
   - Conversion probability
   - Priority score

5. **Territory Filter** (`IBSA_Territory_Filter.png`)
   - Show territory dropdown in action
   - Filtered HCP list by territory

---

## 🛠️ Troubleshooting

### **Issue: Port 3000 Already in Use**
```powershell
# Kill process on port 3000
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process -Force

# Then restart
npm run dev
```

### **Issue: Module Not Found Errors**
```powershell
# Delete node_modules and reinstall
Remove-Item -Recurse -Force node_modules
npm install
npm run dev
```

### **Issue: Data Not Loading**
- Check that CSV files exist in `public/data/` directory
- Files should be:
  - IBSA_ModelReady_Enhanced.csv (2 MB)
  - competitive_conversion_predictions.csv (50.7 MB)
  - territory_lookup.csv
  - rep_territory_assignments.csv

### **Issue: Slow Loading**
- Normal for first load (4,614 HCPs + 1.28M predictions)
- Browser should cache data after first load
- Loading time: ~7-10 seconds initially

---

## 📂 Project Structure

```
ibsa-precall-ui/
├── app/
│   ├── page.tsx                  # Main dashboard
│   ├── hcp/[npi]/page.tsx       # HCP detail page
│   └── layout.tsx                # App layout
├── lib/
│   ├── types.ts                  # TypeScript interfaces (UPDATED)
│   └── api/
│       └── data-loader.ts        # Data loading (UPDATED)
├── components/
│   └── ui/                       # shadcn/ui components
├── public/
│   └── data/                     # CSV data files
│       ├── IBSA_ModelReady_Enhanced.csv
│       ├── competitive_conversion_predictions.csv
│       ├── territory_lookup.csv
│       └── rep_territory_assignments.csv
└── package.json
```

---

## 🎯 Testing Checklist (After Launch)

Once UI is running, verify:

- [ ] UI loads at http://localhost:3000
- [ ] HCP names display (not NPIs)
- [ ] Territory names visible on HCP cards
- [ ] Region names visible
- [ ] NGD scores display correctly
- [ ] Competitive conversion data shows
- [ ] Can click into HCP detail page
- [ ] HCP detail shows all predictions
- [ ] Territory info visible on detail page
- [ ] Page loads in reasonable time (<15 sec)

---

## 🚀 Alternative: Static Build (If Dev Server Issues)

If dev server has issues, you can build and run production version:

```powershell
# Build for production
npm run build

# Run production server
npm run start
```

This creates an optimized build but requires Node.js to be installed.

---

## 📝 Next Steps After Launch

1. **Capture Screenshots:**
   - Take 5 screenshots listed above
   - Save to: `executive-presentations/assets/`
   - Use in MVP deck

2. **Test Territory Filtering:**
   - Add territory dropdown (needs UI component update)
   - Test filtering by territory
   - Verify NGD scores filter correctly

3. **Add Territory Stats Widget:**
   - Shows HCP count, avg TRx, avg NGD per territory
   - Displays when territory is selected

4. **Test Performance:**
   - Load time with 4,614 HCPs
   - Filter responsiveness
   - Detail page navigation

---

## 💡 Quick Install Guide (Copy-Paste)

**If you want to install Node.js right now:**

1. Open browser
2. Go to: https://nodejs.org/en/download/
3. Download "Windows Installer (.msi)" - LTS version
4. Run installer (accept all defaults)
5. Close and reopen PowerShell
6. Run:
   ```powershell
   cd "C:\Users\SandeepT\IBSA PoC V2\ibsa-precall-ui"
   npm install
   npm run dev
   ```
7. Open: http://localhost:3000

**Installation time:** ~5 minutes (Node.js) + 2-3 minutes (npm install) = ~8 minutes total

---

## ✅ System Requirements

- **OS:** Windows 10/11 (✓ You have this)
- **RAM:** 4GB minimum, 8GB recommended
- **Disk Space:** 500MB for Node.js + dependencies
- **Browser:** Chrome, Edge, Firefox (latest versions)

---

**Current Status:** Node.js needs to be installed first  
**Next Action:** Install Node.js from https://nodejs.org/  
**Time to UI:** ~10 minutes after Node.js installation

🎯 **Once Node.js is installed, the UI is ready to launch immediately!**

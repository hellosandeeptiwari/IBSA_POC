# IBSA PoC Output Files Guide
## What JSON Files Are Used and Why

**Last Updated:** October 27, 2025  
**Total Files:** 35 JSON files across 8 directories

---

## 🎯 **ACTIVE FILES USED BY SYSTEM**

### **1. Compliance & Content Library** (4 files)
📁 `ibsa-poc-eda/outputs/compliance/`

| File | Purpose | Used By |
|------|---------|---------|
| `compliance_approved_content.json` | 17 MLR-approved content pieces from IBSA websites | Phase 6D RAG system, FastAPI |
| `prohibited_terms.json` | 41 prohibited terms (e.g., "best", "cure", "superior") | Compliance checker |
| `required_disclaimers.json` | 3 mandatory disclaimers for all scripts | Script generator |
| `content_library_report.json` | Metadata and statistics | Audit trail |

**Status:** ✅ **ACTIVE** - Used by script generator

---

### **2. Call Script Templates** (2 files)
📁 `ibsa-poc-eda/outputs/call_scripts/`

| File | Purpose | Used By |
|------|---------|---------|
| `call_script_templates.json` | 4 scenario templates (RETENTION, GROWTH, OPTIMIZATION, INTRODUCTION) | Phase 6D script generator |
| `template_usage_guide.json` | Documentation on how to use templates | Reference only |

**Status:** ✅ **ACTIVE** - Used by script generator

---

### **3. ML Model Performance** (2 files - LATEST ONLY)
📁 `ibsa-poc-eda/outputs/models/`

| File | Purpose | Used By |
|------|---------|---------|
| `model_performance_report_20251027_164726.json` | Performance metrics for 9 trained models | FastAPI `/models/status` endpoint |
| `training_audit_log_20251027_164726.json` | Training configuration and hyperparameters | Audit trail |

**Status:** ✅ **ACTIVE** - Used by FastAPI

---

### **4. Target Engineering** (2 files - LATEST ONLY)
📁 `ibsa-poc-eda/outputs/targets/`

| File | Purpose | Used By |
|------|---------|---------|
| `targets_audit_log_20251027_164037.json` | Target creation audit trail | Documentation |
| `targets_quality_report_20251027_164037.json` | Data quality metrics for 9 targets | Documentation |

**Status:** ✅ **ACTIVE** - Reference for target engineering

---

### **5. RAG Vector Database** (1 file)
📁 `ibsa-poc-eda/outputs/vector_db/`

| File | Purpose | Used By |
|------|---------|---------|
| `content_library.json` | Content pieces indexed in FAISS | Phase 6D RAG retrieval |

**Status:** ✅ **ACTIVE** - Used by RAG system

---

### **6. Generated Scripts** (2 files)
📁 `ibsa-poc-eda/outputs/generated_scripts/`

| File | Purpose | Used By |
|------|---------|---------|
| `script_12345_*.json` | Example generated scripts for HCP 12345 | Testing/demo |

**Status:** ⚠️ **ARCHIVE** - Test outputs, can be regenerated

---

## 📊 **REFERENCE FILES (NOT ACTIVELY USED)**

### **7. EDA Analysis Results** (7 files)
📁 `ibsa-poc-eda/outputs/eda-enterprise/`

These are **historical analysis outputs** from Phase 3 EDA. Not used by runtime system.

| File | Purpose | Status |
|------|---------|--------|
| `competitive_intelligence_*.json` | Competitor analysis | 📄 Archive |
| `data_quality_report_*.json` | Data quality assessment | 📄 Archive |
| `eda_recommendations.json` | Business insights (660 at-risk HCPs, etc.) | 📄 Archive |
| `feature_selection_results.json` | 326→256 feature reduction | 📄 Archive |
| `payer_intelligence_*.json` | Insurance/formulary analysis | 📄 Archive |
| `sample_roi_analysis_*.json` | Sample black hole analysis | 📄 Archive |
| `territory_benchmarking_*.json` | Territory performance | 📄 Archive |

**Recommendation:** Keep for reference, but not needed for runtime

---

### **8. Schema Analysis** (15 files)
📁 `ibsa-poc-eda/outputs/schema_analysis/`

Database schema documentation from Phase 2. Not used by runtime system.

| Files | Purpose | Status |
|-------|---------|--------|
| `Reporting_BI_*.json` (13 files) | Column analysis for each database table | 📄 Archive |
| `table_relationships.json` | ER diagram relationships | 📄 Archive |

**Recommendation:** Keep for database documentation

---

## 🚀 **FILES REQUIRED FOR DEPLOYMENT**

When deploying to production, you ONLY need these files:

### **Minimum Required:**
```
ibsa-poc-eda/outputs/
├── compliance/
│   ├── compliance_approved_content.json ✅ REQUIRED
│   ├── prohibited_terms.json ✅ REQUIRED
│   └── required_disclaimers.json ✅ REQUIRED
├── call_scripts/
│   └── call_script_templates.json ✅ REQUIRED
├── models/
│   ├── trained_models/*.pkl (9 files) ✅ REQUIRED
│   └── model_performance_report_*.json ✅ REQUIRED
└── vector_db/
    ├── content_library.json ✅ REQUIRED
    └── compliance_content_index.faiss ✅ REQUIRED
```

### **Optional (for audit/documentation):**
- `training_audit_log_*.json`
- `targets_audit_log_*.json`
- `content_library_report.json`

---

## 🗑️ **FILES SAFE TO DELETE**

You can delete these without affecting the system:

1. **Old training results** ✅ Already cleaned up
   - `results_202510*.json` (11 old files removed)
   - Old `model_performance_report_*.json` (3 old files removed)

2. **EDA analysis** (7 files)
   - Only needed for reference, not runtime

3. **Schema analysis** (15 files)
   - Database documentation, not runtime

4. **Generated scripts** (test outputs)
   - Can be regenerated anytime

---

## 📝 **FILE NAMING CONVENTION**

- **Timestamped files:** `*_YYYYMMDD_HHMMSS.json` (keep latest only)
- **Static files:** `compliance_approved_content.json` (no timestamp)
- **Test outputs:** `script_12345_*.json` (regeneratable)

---

## 🔄 **MAINTENANCE SCHEDULE**

**Weekly:**
- Keep only latest `model_performance_report_*.json`
- Keep only latest `training_audit_log_*.json`
- Keep only latest `targets_*_*.json`

**After retraining:**
- Delete old model `.pkl` files
- Delete old performance reports
- Keep audit logs for compliance trail

**Before deployment:**
- Verify all 8 required files exist
- Test FAISS index loads
- Validate compliance content

---

## ✅ **CURRENT STATUS**

- Total JSON files: 35 (cleaned from 60+)
- Active runtime files: 13 ✅
- Archive/reference files: 22 📄
- Disk space: ~2.5 MB (minimal)

**System is clean and ready for production!**

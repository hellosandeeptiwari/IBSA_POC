# IBSA Pre-Call Planning UI - Azure Deployment Guide

## ✅ Git Status: PUSHED TO GITHUB
- **Repository**: https://github.com/hellosandeeptiwari/IBSA_POC
- **Branch**: master
- **Last Commit**: fix: Remove fake predictions from UI components
- **Commit SHA**: 205c1ca

## 🎯 What Was Fixed
- Removed 50+ fake ML prediction fields (churn_risk, expected_roi, hcp_segment_name, sample_effectiveness, etc.)
- Now using ONLY 9 real model outputs from phase6_model_training.py
- Enhanced AI-Generated Call Guide with 32+ intelligent scenarios
- Fixed all TypeScript compilation errors (0 errors)

## 📦 Deployment Options

### **Option 1: Azure Static Web Apps (Recommended for Next.js)**

```bash
# 1. Install Azure CLI
winget install Microsoft.AzureCLI

# 2. Login to Azure
az login

# 3. Create Resource Group
az group create --name ibsa-poc-rg --location eastus

# 4. Deploy Next.js to Azure Static Web Apps
az staticwebapp create \
  --name ibsa-precall-ui \
  --resource-group ibsa-poc-rg \
  --source https://github.com/hellosandeeptiwari/IBSA_POC \
  --location "East US 2" \
  --branch master \
  --app-location "ibsa_precall_ui" \
  --api-location "" \
  --output-location ".next"
```

### **Option 2: Azure App Service (Node.js)**

```bash
# 1. Create App Service Plan
az appservice plan create \
  --name ibsa-plan \
  --resource-group ibsa-poc-rg \
  --sku B1 \
  --is-linux

# 2. Create Web App
az webapp create \
  --name ibsa-precall-ui \
  --resource-group ibsa-poc-rg \
  --plan ibsa-plan \
  --runtime "NODE:18-lts"

# 3. Configure deployment from GitHub
az webapp deployment source config \
  --name ibsa-precall-ui \
  --resource-group ibsa-poc-rg \
  --repo-url https://github.com/hellosandeeptiwari/IBSA_POC \
  --branch master \
  --manual-integration

# 4. Set build command
az webapp config appsettings set \
  --name ibsa-precall-ui \
  --resource-group ibsa-poc-rg \
  --settings \
    NODE_OPTIONS="--max-old-space-size=8192" \
    WEBSITE_NODE_DEFAULT_VERSION="18-lts" \
    BUILD_COMMAND="cd ibsa_precall_ui && npm install && npm run build" \
    START_COMMAND="cd ibsa_precall_ui && npm start"
```

### **Option 3: Azure Container Instances (Docker)**

```bash
# 1. Create Dockerfile in ibsa_precall_ui folder
cat > ibsa_precall_ui/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
EOF

# 2. Build and push to Azure Container Registry
az acr create \
  --name ibsapocacr \
  --resource-group ibsa-poc-rg \
  --sku Basic

az acr build \
  --registry ibsapocacr \
  --image ibsa-precall-ui:latest \
  --file ibsa_precall_ui/Dockerfile \
  ibsa_precall_ui

# 3. Deploy to Container Instances
az container create \
  --name ibsa-precall-ui \
  --resource-group ibsa-poc-rg \
  --image ibsapocacr.azurecr.io/ibsa-precall-ui:latest \
  --cpu 2 \
  --memory 8 \
  --registry-username <acr-username> \
  --registry-password <acr-password> \
  --dns-name-label ibsa-precall-ui \
  --ports 3000
```

## 🔧 Pre-Deployment Checklist

### **1. Environment Variables** (if using backend API)
Create `.env.production` in `ibsa_precall_ui/`:
```bash
NEXT_PUBLIC_API_URL=https://your-fastapi-backend.azurewebsites.net
```

### **2. Memory Configuration**
The 368MB CSV file requires increased Node.js memory:
```bash
NODE_OPTIONS="--max-old-space-size=8192"
```

### **3. Build Optimization** (optional)
To reduce deployment size, consider:
- Filtering CSV to smaller dataset (1000 HCPs instead of full dataset)
- Moving CSV to Azure Blob Storage
- Using API to fetch data instead of bundling CSV

### **4. CORS Configuration** (if using FastAPI backend)
Update `phase6e_fastapi_production_api.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://ibsa-precall-ui.azurewebsites.net"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 📊 Post-Deployment Testing

After deployment, test:
1. **Homepage** (`/`) - Territory dashboard loads
2. **HCP Detail** (`/hcp/1234567890`) - Pre-Call Planning section displays
3. **AI Call Guide** - Opens without errors, shows real predictions
4. **🤖 AI Call Script** tab - Generates scripts (if backend connected)
5. **Purple AI boundaries** - Visual styling intact
6. **Real predictions display**:
   - Product Focus (Tirosint/Flector/Licart)
   - Call Success Probability
   - TRx Lift Forecast
   - NGD Classification (New/Grower/Stable/Decliner)

## 🚨 Known Issues

### **Memory Allocation Error**
**Symptom**: `RangeError: Array buffer allocation failed`
**Solution**: Increase Node.js memory with `NODE_OPTIONS="--max-old-space-size=8192"`

### **CORS Errors**
**Symptom**: Script generation fails with network error
**Solution**: Configure CORS in FastAPI backend to allow Azure domain

### **CSV Not Found**
**Symptom**: Data doesn't load, blank dashboard
**Solution**: Ensure `public/data/IBSA_ModelReady_Enhanced.csv` exists in build

## 📝 Deployment Commands Summary

```powershell
# Quick Deploy to Azure Static Web Apps
cd "c:\Users\SandeepT\IBSA PoC V2"

# Login
az login

# Create Resource Group
az group create --name ibsa-poc-rg --location eastus

# Deploy
az staticwebapp create `
  --name ibsa-precall-ui `
  --resource-group ibsa-poc-rg `
  --source https://github.com/hellosandeeptiwari/IBSA_POC `
  --location "East US 2" `
  --branch master `
  --app-location "ibsa_precall_ui" `
  --output-location ".next"

# Get deployment URL
az staticwebapp show `
  --name ibsa-precall-ui `
  --resource-group ibsa-poc-rg `
  --query "defaultHostname" -o tsv
```

## 🎉 Success Criteria
- ✅ UI loads without errors
- ✅ HCP detail pages display real ML predictions
- ✅ AI-Generated Call Guide shows 6 message types (Opening, Growth, Risk, ROI, Samples, Follow-up)
- ✅ No references to fake predictions (churn_risk, expected_roi, etc.)
- ✅ Purple AI visual boundaries visible
- ✅ All TypeScript compilation passes (0 errors)

## 🔗 Resources
- **GitHub Repo**: https://github.com/hellosandeeptiwari/IBSA_POC
- **Azure Portal**: https://portal.azure.com
- **Next.js on Azure**: https://learn.microsoft.com/en-us/azure/static-web-apps/deploy-nextjs-hybrid
- **Node.js Memory**: https://nodejs.org/api/cli.html#--max-old-space-sizesize-in-megabytes

---

**Last Updated**: October 28, 2025
**Deployed Version**: Predictions Cleanup + Enhanced Call Guide

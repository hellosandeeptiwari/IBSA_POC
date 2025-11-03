# IBSA Pre-Call Planning UI - Package Documentation

## 📦 Node.js Packages (package.json)

### Core Framework
- **next**: `15.5.5` - React framework with server-side rendering
- **react**: `19.0.0` - UI library
- **react-dom**: `19.0.0` - React DOM bindings

### UI Components & Styling
- **@radix-ui/react-***: Accessible, unstyled UI components
  - `react-tabs`: Tab navigation
  - `react-tooltip`: Tooltips
  - `react-slot`: Component composition
- **tailwindcss**: `^3.4.1` - Utility-first CSS framework
- **class-variance-authority**: `^0.7.0` - CSS class management
- **clsx**: `^2.1.0` - Conditional CSS classes
- **tailwind-merge**: `^2.2.1` - Merge Tailwind classes

### Data Visualization
- **recharts**: `^2.12.0` - Chart library for React
- **lucide-react**: `^0.344.0` - Icon library

### Data Handling
- **papaparse**: `^5.4.1` - CSV parsing library
- **@types/papaparse**: `^5.3.14` - TypeScript types for papaparse

### State Management
- **zustand**: `^4.5.0` - Lightweight state management

### Utilities
- **date-fns**: `^3.3.1` - Date utility library

### Development Tools
- **typescript**: `^5` - TypeScript compiler
- **@types/node**: `^20` - Node.js TypeScript types
- **@types/react**: `^19` - React TypeScript types
- **@types/react-dom**: `^19` - React DOM TypeScript types
- **eslint**: `^9` - Code linting
- **eslint-config-next**: `15.5.5` - Next.js ESLint configuration
- **postcss**: `^8` - CSS transformation tool
- **autoprefixer**: `^10.4.18` - CSS vendor prefixing

## 🎯 Key Dependencies Explained

### **papaparse** (Critical for Data Loading)
- **Purpose**: Parses the 368MB CSV file (`IBSA_ModelReady_Enhanced.csv`)
- **Usage**: `lib/api/data-loader.ts` - loads HCP data with predictions
- **Note**: Requires 8GB Node.js memory allocation (`NODE_OPTIONS="--max-old-space-size=8192"`)

### **Recharts** (Data Visualization)
- **Purpose**: Territory performance charts, HCP trend graphs
- **Components Used**: LineChart, BarChart, PieChart, AreaChart
- **Pages**: Homepage dashboard, HCP detail charts

### **Radix UI** (Accessible Components)
- **Purpose**: Unstyled, accessible UI primitives
- **Why**: Better accessibility (WCAG compliance), keyboard navigation
- **Components**: Tabs (Overview/Call Script), Tooltips (data explanations)

### **Tailwind CSS** (Styling)
- **Purpose**: Utility-first CSS framework
- **Custom Theme**: Purple AI branding colors, responsive breakpoints
- **Config**: `tailwind.config.ts` - custom colors, spacing, shadows

### **Next.js 15** (Framework)
- **App Router**: New routing system (app directory)
- **Server Components**: Improved performance
- **Image Optimization**: Built-in image component
- **API Routes**: Not used (data loaded from CSV)

## 🔧 Installation Commands

```bash
# Install all dependencies
cd ibsa_precall_ui
npm install

# Development server
npm run dev

# Production build
npm run build
npm start

# Linting
npm run lint
```

## 📊 Package Sizes (Approximate)

| Package | Size | Purpose |
|---------|------|---------|
| next | ~40MB | Framework |
| react + react-dom | ~10MB | UI library |
| recharts | ~15MB | Charts |
| tailwindcss | ~5MB | Styling |
| papaparse | ~1MB | CSV parsing |
| lucide-react | ~3MB | Icons |
| **Total** | ~**180MB** | node_modules |

## ⚠️ Production Optimization

### Remove from Production Bundle:
```json
{
  "devDependencies": {
    "typescript",
    "@types/*",
    "eslint",
    "eslint-config-next"
  }
}
```

### Install production only:
```bash
npm ci --only=production
```

### Reduce Bundle Size:
1. Use Next.js Image component (auto-optimization)
2. Enable tree-shaking (automatic in Next.js 15)
3. Lazy load heavy components (React.lazy)
4. Code splitting (automatic with Next.js routing)

## 🚀 Azure Deployment Considerations

### Static Assets:
- CSV file: Move to Azure Blob Storage (not bundled)
- Images: Use Next.js Image component with CDN
- Fonts: Preload in `app/layout.tsx`

### Environment Variables:
```bash
NEXT_PUBLIC_API_URL=https://your-api.azurewebsites.net
NEXT_PUBLIC_BLOB_URL=https://ibsapocdata.blob.core.windows.net
```

### Build Configuration:
```json
{
  "scripts": {
    "build": "next build",
    "start": "next start -p $PORT"
  }
}
```

## 📝 Version Compatibility

- **Node.js**: 18.x or 20.x LTS (required)
- **npm**: 9.x or 10.x
- **TypeScript**: 5.x
- **React**: 19.x (latest)
- **Next.js**: 15.x (latest)

## 🔄 Update Commands

```bash
# Check for updates
npm outdated

# Update all to latest (within semver range)
npm update

# Update Next.js specifically
npm install next@latest react@latest react-dom@latest

# Update Tailwind
npm install tailwindcss@latest autoprefixer@latest postcss@latest
```

---

**Last Updated**: October 28, 2025  
**Dependencies Count**: 25+ packages  
**Total Install Size**: ~180MB

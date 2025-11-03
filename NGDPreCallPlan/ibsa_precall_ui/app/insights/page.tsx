'use client'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown, Activity, AlertTriangle, CheckCircle2, BarChart3, Brain, Target, Zap } from 'lucide-react'

export default function InsightsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-4xl font-bold mb-2">Model Insights & Decision Framework</h1>
        <p className="text-muted-foreground text-lg">
          Complete transparency into our AI/ML approach with 4 production models
        </p>
        <div className="mt-2 flex items-center gap-2">
          <Badge className="bg-green-600">3 Core Models + 1 Ensemble</Badge>
          <Badge variant="outline">Real Historical Outcomes Only</Badge>
        </div>
      </div>

      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="grid w-full grid-cols-3 lg:w-auto">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="models">4 Models</TabsTrigger>
          <TabsTrigger value="validation">Why Only 4?</TabsTrigger>
        </TabsList>

        {/* OVERVIEW TAB */}
        <TabsContent value="overview" className="space-y-6">
          <Card className="border-blue-200 bg-blue-50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Brain className="h-6 w-6 text-blue-600" />
                Executive Summary
              </CardTitle>
              <CardDescription>Key highlights for leadership review</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <h3 className="font-semibold text-sm text-gray-600">Data Quality</h3>
                  <ul className="space-y-1 text-sm">
                    <li className="flex items-center gap-2">
                      <CheckCircle2 className="h-4 w-4 text-green-600" />
                      <span>346,508 HCPs with 100% complete profiles</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <CheckCircle2 className="h-4 w-4 text-green-600" />
                      <span>Zero temporal leakage (pharma-grade)</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <CheckCircle2 className="h-4 w-4 text-green-600" />
                      <span>Real historical outcomes only</span>
                    </li>
                  </ul>
                </div>
                <div className="space-y-2">
                  <h3 className="font-semibold text-sm text-gray-600">Model Performance</h3>
                  <ul className="space-y-1 text-sm">
                    <li className="flex items-center gap-2">
                      <TrendingUp className="h-4 w-4 text-blue-600" />
                      <span>Call Success: 93.56% accuracy</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <TrendingUp className="h-4 w-4 text-blue-600" />
                      <span>NGD Classification: 90.51% accuracy</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <TrendingUp className="h-4 w-4 text-blue-600" />
                      <span>Prescription Lift: R² 0.253 (realistic)</span>
                    </li>
                  </ul>
                </div>
              </div>

              <div className="bg-white p-4 rounded-lg border">
                <h3 className="font-semibold mb-3 flex items-center gap-2">
                  <Zap className="h-5 w-5 text-yellow-600" />
                  Critical Achievement: Removed 5 Synthetic Targets
                </h3>
                <div className="grid md:grid-cols-2 gap-4 text-sm">
                  <div className="space-y-2">
                    <Badge variant="destructive" className="mb-1">❌ Phase 5 Initial (9 targets)</Badge>
                    <p className="text-red-700 font-semibold">R² = 0.998-1.0 (OVERFITTING!)</p>
                    <p className="text-gray-600">Included 5 synthetic/formula-based targets that caused near-perfect scores</p>
                  </div>
                  <div className="space-y-2">
                    <Badge className="mb-1 bg-green-600">✅ Phase 6 Final (4 models)</Badge>
                    <p className="text-green-700 font-semibold">93.56% call success - REALISTIC!</p>
                    <p className="text-gray-600">Only REAL historical outcomes from Prescriber Overview data</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="grid md:grid-cols-3 gap-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Data Pipeline</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Total Records</span>
                    <span className="font-semibold">1.3M</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Complete Profiles</span>
                    <span className="font-semibold">346K</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Features</span>
                    <span className="font-semibold">120</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Target Variables</span>
                    <span className="font-semibold">3</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Model Ensemble</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Total Models</span>
                    <span className="font-semibold">4</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Binary Classification</span>
                    <span className="font-semibold">1 model</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Multi-Class</span>
                    <span className="font-semibold">1 model</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Regression</span>
                    <span className="font-semibold">1 model</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Stacking Ensemble</span>
                    <span className="font-semibold">1 model</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Latest Results</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Training Date</span>
                    <span className="font-semibold">Oct 22, 2025</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Sample Size</span>
                    <span className="font-semibold">15% (200K)</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Cross-Validation</span>
                    <span className="font-semibold">5-fold</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Status</span>
                    <span className="font-semibold text-green-600">Production</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* 4 MODELS TAB */}
        <TabsContent value="models" className="space-y-6">
          <Card className="border-blue-200 bg-blue-50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="h-5 w-5 text-blue-600" />
                Model Training Philosophy: Real Outcomes Only
              </CardTitle>
            </CardHeader>
            <CardContent className="text-sm">
              <p className="mb-2"><strong>We removed 5 synthetic targets</strong> that caused near-perfect overfitting (R² = 0.998-1.0):</p>
              <ul className="list-disc ml-6 text-gray-700 space-y-1">
                <li><strong>Sample Effectiveness</strong> - Formula: trx/samples (circular logic)</li>
                <li><strong>Old NGD Score</strong> - Used same features as input (data leakage)</li>
                <li><strong>Churn Risk</strong> - Used retention_probability feature (leakage)</li>
                <li><strong>Future TRx Lift</strong> - Formula-based calculation (R²=0.9998)</li>
                <li><strong>Expected ROI</strong> - Derived from future_trx (R²=0.9998)</li>
              </ul>
              <p className="text-green-700 font-semibold mt-3">✅ Final 4 models use ONLY real historical outcomes from Prescriber Overview</p>
            </CardContent>
          </Card>

          <div className="grid md:grid-cols-2 gap-4">
            {/* Model 1 */}
            <Card className="border-blue-200">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>1. Call Success</CardTitle>
                  <Badge className="bg-blue-600">Binary</Badge>
                </div>
                <CardDescription>Will the call lead to TRx growth?</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="bg-blue-50 p-3 rounded-lg">
                  <p className="text-3xl font-bold text-blue-700">93.56%</p>
                  <p className="text-xs text-gray-600">Accuracy</p>
                </div>
                <div className="text-sm space-y-1">
                  <div className="flex justify-between">
                    <span className="text-gray-600">AUC-ROC:</span>
                    <span className="font-semibold">0.9596</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Precision:</span>
                    <span className="font-semibold">93.54%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">F1 Score:</span>
                    <span className="font-semibold">92.00%</span>
                  </div>
                </div>
                <div className="bg-gray-50 p-2 rounded text-xs">
                  <p className="font-semibold mb-1">Data Source:</p>
                  <p className="text-gray-600">Real TRx growth from Prescriber Overview</p>
                </div>
              </CardContent>
            </Card>

            {/* Model 2 */}
            <Card className="border-green-200">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>2. Prescription Lift</CardTitle>
                  <Badge className="bg-green-600">Regression</Badge>
                </div>
                <CardDescription>How much TRx increase?</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="bg-green-50 p-3 rounded-lg">
                  <p className="text-3xl font-bold text-green-700">R² 0.253</p>
                  <p className="text-xs text-gray-600">Pharma Standard</p>
                </div>
                <div className="text-sm space-y-1">
                  <div className="flex justify-between">
                    <span className="text-gray-600">MAE:</span>
                    <span className="font-semibold">0.19 Rx</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">RMSE:</span>
                    <span className="font-semibold">0.58 Rx</span>
                  </div>
                </div>
                <div className="bg-gray-50 p-2 rounded text-xs">
                  <p className="font-semibold mb-1">Data Source:</p>
                  <p className="text-gray-600">TRx(Current) - TRx(Previous) from actual data</p>
                </div>
              </CardContent>
            </Card>

            {/* Model 3 */}
            <Card className="border-orange-200">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>3. NGD Classification</CardTitle>
                  <Badge className="bg-orange-600">Multi-Class</Badge>
                </div>
                <CardDescription>NEW/GROWER/STABLE/DECLINER</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="bg-orange-50 p-3 rounded-lg">
                  <p className="text-3xl font-bold text-orange-700">90.51%</p>
                  <p className="text-xs text-gray-600">Accuracy (4 Classes)</p>
                </div>
                <div className="text-sm space-y-1">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Precision:</span>
                    <span className="font-semibold">90.71%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">F1 Score:</span>
                    <span className="font-semibold">89.30%</span>
                  </div>
                </div>
                <div className="bg-gray-50 p-2 rounded text-xs">
                  <p className="font-semibold mb-1">Data Source:</p>
                  <p className="text-gray-600">Real NGD categories from Prescriber Overview</p>
                </div>
              </CardContent>
            </Card>

            {/* Model 4 */}
            <Card className="border-purple-200">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>4. Stacked Ensemble</CardTitle>
                  <Badge className="bg-purple-600">Ensemble</Badge>
                </div>
                <CardDescription>NGD using Models 1-2 predictions</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="bg-purple-50 p-3 rounded-lg">
                  <p className="text-3xl font-bold text-purple-700">90.26%</p>
                  <p className="text-xs text-gray-600">Accuracy (Stacking)</p>
                </div>
                <div className="text-sm space-y-2">
                  <p className="font-semibold">Architecture:</p>
                  <ul className="text-xs text-gray-600 ml-4 list-disc">
                    <li>Uses Call Success probability</li>
                    <li>Uses Prescription Lift prediction</li>
                    <li>Combines with 120 base features</li>
                  </ul>
                </div>
                <div className="bg-gray-50 p-2 rounded text-xs">
                  <p className="font-semibold mb-1">Ensemble Approach:</p>
                  <p className="text-gray-600">Meta-model learns to combine predictions</p>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* VALIDATION TAB */}
        <TabsContent value="validation" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <CheckCircle2 className="h-6 w-6 text-green-600" />
                Why Only 4 Models? Quality Over Quantity
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-yellow-50 p-4 rounded-lg border border-yellow-200">
                <h3 className="font-semibold text-yellow-900 mb-2">The Problem with Synthetic Targets</h3>
                <p className="text-sm text-gray-700 mb-3">
                  In Phase 5, we initially created 9 target variables. But 5 of them achieved R² scores of 0.998-1.0 
                  (essentially perfect prediction). This is a RED FLAG for overfitting.
                </p>
                <p className="text-sm font-semibold text-red-700">
                  These models weren't learning patterns - they were predicting their own formulas!
                </p>
              </div>

              <div>
                <h3 className="font-semibold mb-3">Examples of Removed Synthetic Targets:</h3>
                <div className="space-y-3">
                  <div className="bg-red-50 p-3 rounded border border-red-200">
                    <p className="font-semibold text-sm text-red-900">Sample Effectiveness</p>
                    <p className="text-xs text-gray-700">Formula: trx_current / samples_given</p>
                    <p className="text-xs text-red-700 mt-1">Problem: Circular logic - both variables are features!</p>
                  </div>
                  
                  <div className="bg-red-50 p-3 rounded border border-red-200">
                    <p className="font-semibold text-sm text-red-900">Future TRx Lift</p>
                    <p className="text-xs text-gray-700">Formula: future_trx * growth_factor * call_success</p>
                    <p className="text-xs text-red-700 mt-1">Problem: R²=0.9998 - predicting its own calculation!</p>
                  </div>
                  
                  <div className="bg-red-50 p-3 rounded border border-red-200">
                    <p className="font-semibold text-sm text-red-900">Churn Risk</p>
                    <p className="text-xs text-gray-700">Used: retention_probability as a feature</p>
                    <p className="text-xs text-red-700 mt-1">Problem: Data leakage - retention is the outcome we're predicting!</p>
                  </div>
                </div>
              </div>

              <div className="bg-green-50 p-4 rounded-lg border border-green-200">
                <h3 className="font-semibold text-green-900 mb-2">✅ Our Solution: Real Outcomes Only</h3>
                <p className="text-sm text-gray-700 mb-3">
                  We rebuilt from scratch using ONLY real historical outcomes from Prescriber Overview data:
                </p>
                <ul className="text-sm text-gray-700 space-y-1 ml-4 list-disc">
                  <li><strong>Call Success:</strong> Did TRx actually increase after the call? (Binary outcome from data)</li>
                  <li><strong>Prescription Lift:</strong> Actual TRx change = TRx(Current QTD) - TRx(Previous QTD)</li>
                  <li><strong>NGD Classification:</strong> Real NEW/GROWER/STABLE/DECLINER flags from industry standard</li>
                </ul>
                <p className="text-sm font-semibold text-green-700 mt-3">
                  Result: Realistic performance (93.56%, R²=0.253) that will work in production!
                </p>
              </div>

              <div>
                <h3 className="font-semibold mb-3">Performance Comparison:</h3>
                <div className="grid md:grid-cols-2 gap-4">
                  <div className="bg-red-50 p-4 rounded border border-red-200">
                    <p className="font-semibold text-red-900 mb-2">❌ Synthetic Targets (Removed)</p>
                    <p className="text-2xl font-bold text-red-700">R² = 0.998</p>
                    <p className="text-xs text-gray-600 mt-1">Too perfect = overfitting</p>
                    <p className="text-xs text-gray-600">Would fail in production</p>
                  </div>
                  <div className="bg-green-50 p-4 rounded border border-green-200">
                    <p className="font-semibold text-green-900 mb-2">✅ Real Outcomes (Current)</p>
                    <p className="text-2xl font-bold text-green-700">93.56% / R²=0.25</p>
                    <p className="text-xs text-gray-600 mt-1">Realistic performance</p>
                    <p className="text-xs text-gray-600">Production-ready and trustworthy</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

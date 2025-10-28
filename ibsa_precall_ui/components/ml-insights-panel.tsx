import React from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { MLPredictions } from '@/lib/api/ml-predictions'
import {
  TrendingUp,
  TrendingDown,
  Target,
  AlertTriangle,
  CheckCircle2,
  DollarSign,
  Calendar,
  Package,
  Brain,
  Sparkles,
  Activity,
  Shield
} from 'lucide-react'

interface MLInsightsPanelProps {
  predictions: MLPredictions
  compact?: boolean
}

export function MLInsightsPanel({ predictions, compact = false }: MLInsightsPanelProps) {
  return (
    <div className="space-y-6">
      {/* AI-Powered Recommendation Card */}
      <Card className="border-2 border-blue-500 bg-gradient-to-br from-blue-50 to-indigo-50">
        <CardHeader>
          <div className="flex items-center gap-2">
            <Brain className="h-6 w-6 text-blue-600" />
            <CardTitle className="text-blue-900">AI-Powered Recommendation</CardTitle>
            <Badge variant="secondary" className="ml-auto">
              <Sparkles className="h-3 w-3 mr-1" />
              ML Ensemble Score: {Math.round(predictions.ensemble_score * 100)}%
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Primary Recommendation */}
          <div className="flex items-start gap-4 p-4 bg-white rounded-lg shadow-sm">
            <div className="flex-shrink-0">
              {predictions.call_recommended ? (
                <CheckCircle2 className="h-8 w-8 text-green-500" />
              ) : (
                <AlertTriangle className="h-8 w-8 text-amber-500" />
              )}
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-lg mb-2">
                {predictions.recommended_action}
              </h3>
              <p className="text-sm text-muted-foreground">
                Based on analysis of 93 features across 9 ML models
              </p>
            </div>
          </div>

          {/* Key Metrics Grid */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard
              icon={<Target className="h-5 w-5" />}
              label="Call Success"
              value={`${Math.round(predictions.call_success_probability * 100)}%`}
              trend={predictions.call_success_probability >= 0.7 ? 'up' : predictions.call_success_probability >= 0.4 ? 'neutral' : 'down'}
            />
            <MetricCard
              icon={<TrendingUp className="h-5 w-5" />}
              label="Forecasted Lift"
              value={`${predictions.prescription_lift_forecast >= 0 ? '+' : ''}${Math.round(predictions.prescription_lift_forecast)}`}
              trend={predictions.prescription_lift_forecast > 0 ? 'up' : predictions.prescription_lift_forecast < 0 ? 'down' : 'neutral'}
              suffix="TRx"
            />
            <MetricCard
              icon={<DollarSign className="h-5 w-5" />}
              label="Expected ROI"
              value={`$${Math.round(predictions.expected_roi)}`}
              trend={predictions.expected_roi > 100 ? 'up' : predictions.expected_roi > 0 ? 'neutral' : 'down'}
            />
            <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="NGD Score"
              value={`${predictions.ngd_decile}/10`}
              trend={predictions.ngd_decile >= 7 ? 'up' : predictions.ngd_decile >= 4 ? 'neutral' : 'down'}
              badge={predictions.ngd_classification}
            />
          </div>
        </CardContent>
      </Card>

      {/* Model-by-Model Predictions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Model 1: Call Success */}
        <ModelPredictionCard
          modelNumber={1}
          title="Call Success Predictor"
          icon={<Target className="h-5 w-5" />}
          prediction={{
            value: predictions.call_success_probability,
            format: 'percentage',
            label: predictions.call_success_prediction ? 'High Probability' : 'Low Probability'
          }}
          insights={[
            `${Math.round(predictions.call_success_probability * 100)}% probability of successful engagement`,
            `Confidence: ${Math.round(predictions.confidence_level * 100)}%`
          ]}
          color={predictions.call_success_probability >= 0.7 ? 'green' : predictions.call_success_probability >= 0.4 ? 'amber' : 'red'}
        />

        {/* Model 4: NGD Score */}
        <ModelPredictionCard
          modelNumber={4}
          title="NGD Classification"
          icon={<TrendingUp className="h-5 w-5" />}
          prediction={{
            value: predictions.ngd_decile / 10,
            format: 'decile',
            label: predictions.ngd_classification
          }}
          insights={[
            `Decile ${predictions.ngd_decile}/10 - ${predictions.ngd_classification}`,
            `Momentum Score: ${Math.round(predictions.ngd_momentum * 100)}%`
          ]}
          color={predictions.ngd_decile >= 7 ? 'green' : predictions.ngd_decile >= 4 ? 'blue' : 'gray'}
        />

        {/* Model 5: Churn Risk */}
        <ModelPredictionCard
          modelNumber={5}
          title="Churn Risk Analysis"
          icon={predictions.retention_priority ? <AlertTriangle className="h-5 w-5" /> : <Shield className="h-5 w-5" />}
          prediction={{
            value: predictions.churn_risk_probability,
            format: 'percentage',
            label: predictions.churn_risk_level
          }}
          insights={[
            `${predictions.churn_risk_level} risk of prescription decline`,
            predictions.retention_priority ? 'Retention campaign recommended' : 'Stable relationship'
          ]}
          color={predictions.churn_risk_level === 'High' ? 'red' : predictions.churn_risk_level === 'Medium' ? 'amber' : 'green'}
        />

        {/* Model 7: HCP Segment */}
        <ModelPredictionCard
          modelNumber={7}
          title="HCP Segmentation"
          icon={<Activity className="h-5 w-5" />}
          prediction={{
            value: predictions.hcp_segment_id / 5,
            format: 'segment',
            label: predictions.hcp_segment_name
          }}
          insights={[
            predictions.hcp_segment_name,
            predictions.segment_strategy
          ]}
          color={getSegmentColor(predictions.hcp_segment_name)}
        />

        {/* Model 8: Expected ROI */}
        <ModelPredictionCard
          modelNumber={8}
          title="ROI Forecast"
          icon={<DollarSign className="h-5 w-5" />}
          prediction={{
            value: predictions.expected_roi,
            format: 'currency',
            label: predictions.roi_category
          }}
          insights={[
            `Expected ROI: $${Math.round(predictions.expected_roi)} per call`,
            predictions.call_recommended ? 'Call strongly recommended' : 'Consider alternative engagement'
          ]}
          color={predictions.expected_roi > 200 ? 'green' : predictions.expected_roi > 0 ? 'blue' : 'red'}
        />

        {/* Model 6: Future TRx Lift */}
        <ModelPredictionCard
          modelNumber={6}
          title="Future Performance"
          icon={<TrendingUp className="h-5 w-5" />}
          prediction={{
            value: predictions.future_trx_lift,
            format: 'number',
            label: predictions.growth_trajectory
          }}
          insights={[
            `Next quarter forecast: ${Math.round(predictions.next_quarter_forecast)} TRx`,
            `Growth trajectory: ${predictions.growth_trajectory}`
          ]}
          color={predictions.growth_trajectory === 'Accelerating' ? 'green' : predictions.growth_trajectory === 'Steady' ? 'blue' : 'amber'}
        />
      </div>

      {/* Call Planning Recommendations */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Calendar className="h-5 w-5 text-blue-600" />
            <CardTitle>Call Planning Recommendations</CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Best Call Timing */}
            <div className="p-4 bg-blue-50 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <Calendar className="h-4 w-4 text-blue-600" />
                <h4 className="font-semibold text-sm">Optimal Timing</h4>
              </div>
              <p className="text-lg font-bold text-blue-900">{predictions.best_call_timing.day}</p>
              <p className="text-sm text-muted-foreground">{predictions.best_call_timing.time}</p>
            </div>

            {/* Sample Strategy */}
            <div className="p-4 bg-green-50 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <Package className="h-4 w-4 text-green-600" />
                <h4 className="font-semibold text-sm">Sample Strategy</h4>
              </div>
              <p className="text-lg font-bold text-green-900">
                {predictions.optimal_sample_quantity} samples
              </p>
              <p className="text-sm text-muted-foreground">
                {predictions.sample_effectiveness_score.toFixed(1)} effectiveness score
              </p>
            </div>

            {/* Priority Level */}
            <div className="p-4 bg-amber-50 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <Target className="h-4 w-4 text-amber-600" />
                <h4 className="font-semibold text-sm">Call Priority</h4>
              </div>
              <p className="text-lg font-bold text-amber-900">
                {predictions.call_recommended ? 'HIGH' : 'MEDIUM'}
              </p>
              <p className="text-sm text-muted-foreground">
                {predictions.roi_category} ROI potential
              </p>
            </div>
          </div>

          {/* Sample Strategy Details */}
          <div className="p-4 bg-gray-50 rounded-lg">
            <h4 className="font-semibold mb-2">Detailed Sample Strategy</h4>
            <p className="text-sm text-muted-foreground">{predictions.sample_strategy}</p>
          </div>
        </CardContent>
      </Card>

      {/* Key Messages */}
      <Card>
        <CardHeader>
          <CardTitle>AI-Generated Key Messages</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {predictions.key_messages.map((message, index) => (
              <div key={index} className="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
                <div className="flex-shrink-0 w-6 h-6 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
                  {index + 1}
                </div>
                <p className="text-sm flex-1">{message}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Feature Importance */}
      <Card>
        <CardHeader>
          <CardTitle>Top Predictive Features</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {predictions.top_features.map((feature, index) => (
              <div key={index}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium">{feature.feature}</span>
                  <span className="text-sm text-muted-foreground">
                    {Math.round(feature.importance * 100)}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-blue-600 h-2 rounded-full transition-all"
                    style={{ width: `${feature.importance * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

interface MetricCardProps {
  icon: React.ReactNode
  label: string
  value: string
  trend?: 'up' | 'down' | 'neutral'
  suffix?: string
  badge?: string
}

function MetricCard({ icon, label, value, trend, suffix, badge }: MetricCardProps) {
  const trendIcon = trend === 'up' ? <TrendingUp className="h-4 w-4 text-green-500" /> :
                    trend === 'down' ? <TrendingDown className="h-4 w-4 text-red-500" /> : null

  return (
    <div className="p-4 bg-white rounded-lg shadow-sm">
      <div className="flex items-center gap-2 mb-2 text-muted-foreground">
        {icon}
        <span className="text-xs font-medium">{label}</span>
      </div>
      <div className="flex items-baseline gap-2">
        <span className="text-2xl font-bold">{value}</span>
        {suffix && <span className="text-sm text-muted-foreground">{suffix}</span>}
        {trendIcon}
      </div>
      {badge && (
        <Badge variant="outline" className="mt-2 text-xs">
          {badge}
        </Badge>
      )}
    </div>
  )
}

interface ModelPredictionCardProps {
  modelNumber: number
  title: string
  icon: React.ReactNode
  prediction: {
    value: number
    format: 'percentage' | 'decile' | 'segment' | 'currency' | 'number'
    label: string
  }
  insights: string[]
  color: 'green' | 'blue' | 'amber' | 'red' | 'gray'
}

function ModelPredictionCard({ modelNumber, title, icon, prediction, insights, color }: ModelPredictionCardProps) {
  const colorClasses = {
    green: 'border-green-500 bg-green-50',
    blue: 'border-blue-500 bg-blue-50',
    amber: 'border-amber-500 bg-amber-50',
    red: 'border-red-500 bg-red-50',
    gray: 'border-gray-400 bg-gray-50'
  }

  const badgeColors = {
    green: 'bg-green-100 text-green-800',
    blue: 'bg-blue-100 text-blue-800',
    amber: 'bg-amber-100 text-amber-800',
    red: 'bg-red-100 text-red-800',
    gray: 'bg-gray-100 text-gray-800'
  }

  const formatValue = () => {
    switch (prediction.format) {
      case 'percentage':
        return `${Math.round(prediction.value * 100)}%`
      case 'decile':
        return `${Math.round(prediction.value * 10)}/10`
      case 'currency':
        return `$${Math.round(prediction.value)}`
      case 'number':
        return `${prediction.value >= 0 ? '+' : ''}${Math.round(prediction.value)}`
      case 'segment':
        return prediction.label
    }
  }

  return (
    <Card className={`border-l-4 ${colorClasses[color]}`}>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {icon}
            <div>
              <div className="text-xs text-muted-foreground">Model {modelNumber}</div>
              <CardTitle className="text-sm">{title}</CardTitle>
            </div>
          </div>
          <Badge className={badgeColors[color]}>
            {prediction.label}
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold mb-3">{formatValue()}</div>
        <div className="space-y-1">
          {insights.map((insight, index) => (
            <p key={index} className="text-xs text-muted-foreground">
              • {insight}
            </p>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}

function getSegmentColor(segment: MLPredictions['hcp_segment_name']): 'green' | 'blue' | 'amber' | 'red' | 'gray' {
  switch (segment) {
    case 'Champions':
      return 'green'
    case 'Growth Opportunities':
      return 'blue'
    case 'At-Risk':
      return 'red'
    case 'Maintain':
      return 'amber'
    case 'Deprioritize':
      return 'gray'
  }
}

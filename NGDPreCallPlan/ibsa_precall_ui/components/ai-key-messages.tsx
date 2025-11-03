'use client'

import { Predictions, HCP } from '@/lib/types'
import { Brain, MessageSquare, TrendingUp, AlertTriangle, Target, Calendar, Lightbulb, CheckCircle2 } from 'lucide-react'

interface AIKeyMessagesProps {
  hcp: HCP
  predictions: Predictions
}

/**
 * AI-Generated Key Messages Component
 * Translates ML model predictions into natural language talking points
 * for sales reps to use during HCP calls
 */
export function AIKeyMessages({ hcp, predictions }: AIKeyMessagesProps) {
  
  // Generate natural language messages based on ML predictions
  const keyMessages = generateKeyMessages(hcp, predictions)
  
  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-2 mb-4">
        <Brain className="h-5 w-5 text-purple-600" />
        <h3 className="text-lg font-semibold">AI-Generated Key Messages</h3>
        <span className="text-xs text-gray-500 ml-auto">Based on 9 ML models</span>
      </div>

      {/* Primary Recommendation */}
      <div className="bg-gradient-to-br from-purple-50 to-blue-50 dark:from-purple-950/20 dark:to-blue-950/20 rounded-lg p-4 border border-purple-200 dark:border-purple-800">
        <div className="flex items-start gap-3">
          <Target className="h-5 w-5 text-purple-600 mt-0.5" />
          <div>
            <div className="font-semibold text-purple-900 dark:text-purple-100 mb-1">
              Primary Call Objective
            </div>
            <p className="text-sm text-gray-700 dark:text-gray-300">
              {keyMessages.primary}
            </p>
          </div>
        </div>
      </div>

      {/* Talking Points Grid */}
      <div className="grid gap-3">
        
        {/* Opening Statement */}
        {keyMessages.opening && (
          <MessageCard
            icon={<MessageSquare className="h-4 w-4" />}
            title="Opening Statement"
            message={keyMessages.opening}
            color="blue"
          />
        )}

        {/* Growth Opportunity */}
        {keyMessages.growth && (
          <MessageCard
            icon={<TrendingUp className="h-4 w-4" />}
            title="Growth Opportunity"
            message={keyMessages.growth}
            color="green"
          />
        )}

        {/* Risk Alert */}
        {keyMessages.risk && (
          <MessageCard
            icon={<AlertTriangle className="h-4 w-4" />}
            title="Risk Alert"
            message={keyMessages.risk}
            color="amber"
          />
        )}

        {/* ROI Talking Point */}
        {keyMessages.roi && (
          <MessageCard
            icon={<Lightbulb className="h-4 w-4" />}
            title="Value Proposition"
            message={keyMessages.roi}
            color="purple"
          />
        )}

        {/* Sample Strategy */}
        {keyMessages.samples && (
          <MessageCard
            icon={<CheckCircle2 className="h-4 w-4" />}
            title="Sample Strategy"
            message={keyMessages.samples}
            color="indigo"
          />
        )}

        {/* Follow-up Action */}
        {keyMessages.followup && (
          <MessageCard
            icon={<Calendar className="h-4 w-4" />}
            title="Follow-up Plan"
            message={keyMessages.followup}
            color="teal"
          />
        )}

      </div>

      {/* Clinical Insights */}
      {keyMessages.clinical && keyMessages.clinical.length > 0 && (
        <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
          <div className="font-semibold text-sm mb-2 flex items-center gap-2">
            <Lightbulb className="h-4 w-4 text-yellow-600" />
            Clinical Discussion Points
          </div>
          <ul className="space-y-1.5">
            {keyMessages.clinical.map((point, idx) => (
              <li key={idx} className="text-sm text-gray-600 dark:text-gray-400 flex items-start gap-2">
                <span className="text-yellow-600 mt-0.5">•</span>
                <span>{point}</span>
              </li>
            ))}
          </ul>
        </div>
      )}

    </div>
  )
}

// Message Card Component
interface MessageCardProps {
  icon: React.ReactNode
  title: string
  message: string
  color: 'blue' | 'green' | 'amber' | 'purple' | 'indigo' | 'teal'
}

function MessageCard({ icon, title, message, color }: MessageCardProps) {
  const colorClasses = {
    blue: 'bg-blue-50 dark:bg-blue-950/20 border-blue-200 dark:border-blue-800 text-blue-900 dark:text-blue-100',
    green: 'bg-green-50 dark:bg-green-950/20 border-green-200 dark:border-green-800 text-green-900 dark:text-green-100',
    amber: 'bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-800 text-amber-900 dark:text-amber-100',
    purple: 'bg-purple-50 dark:bg-purple-950/20 border-purple-200 dark:border-purple-800 text-purple-900 dark:text-purple-100',
    indigo: 'bg-indigo-50 dark:bg-indigo-950/20 border-indigo-200 dark:border-indigo-800 text-indigo-900 dark:text-indigo-100',
    teal: 'bg-teal-50 dark:bg-teal-950/20 border-teal-200 dark:border-teal-800 text-teal-900 dark:text-teal-100',
  }

  const iconColorClasses = {
    blue: 'text-blue-600',
    green: 'text-green-600',
    amber: 'text-amber-600',
    purple: 'text-purple-600',
    indigo: 'text-indigo-600',
    teal: 'text-teal-600',
  }

  return (
    <div className={`rounded-lg p-3 border ${colorClasses[color]}`}>
      <div className="flex items-start gap-2">
        <div className={iconColorClasses[color]}>{icon}</div>
        <div className="flex-1">
          <div className="text-xs font-semibold uppercase tracking-wide mb-1 opacity-75">
            {title}
          </div>
          <p className="text-sm leading-relaxed">{message}</p>
        </div>
      </div>
    </div>
  )
}

/**
 * Generate natural language key messages based on ML predictions
 */
function generateKeyMessages(hcp: HCP, predictions: Predictions) {
  const messages: {
    primary: string
    opening?: string
    growth?: string
    risk?: string
    roi?: string
    samples?: string
    followup?: string
    clinical: string[]
  } = {
    primary: '',
    clinical: []
  }

  // Primary Objective (based on HCP Segment & Next Best Action)
  messages.primary = generatePrimaryObjective(hcp, predictions)

  // Opening Statement (based on Call Success Probability)
  messages.opening = generateOpeningStatement(hcp, predictions)

  // Growth Opportunity (based on Prescription Lift)
  if (predictions.forecasted_lift > 0) {
    messages.growth = generateGrowthMessage(hcp, predictions)
  }

  // Risk Alert (based on NGD Classification = Decliner)
  if (predictions.ngd_classification === 'Decliner') {
    messages.risk = generateRiskMessage(hcp, predictions)
  }

  // ROI Talking Point (based on Call Success + Lift)
  if (predictions.call_success_prob > 0.5 && predictions.forecasted_lift > 0) {
    messages.roi = generateROIMessage(hcp, predictions)
  }

  // Sample Strategy (based on Sample Allocation)
  if (predictions.sample_allocation > 0) {
    messages.samples = generateSampleMessage(hcp, predictions)
  }

  // Follow-up Plan (based on Best Day/Time & NGD Classification)
  messages.followup = generateFollowupMessage(hcp, predictions)

  // Clinical Discussion Points
  messages.clinical = generateClinicalPoints(hcp, predictions)

  return messages
}

function generatePrimaryObjective(hcp: HCP, predictions: Predictions): string {
  const ngd = predictions.ngd_classification
  const action = predictions.next_best_action
  const productFocus = predictions.product_focus

  // Based on NGD Classification (real model output)
  if (ngd === 'Grower') {
    return `Capitalize on growth momentum with ${hcp.name}. Recent growing prescribing patterns suggest strong receptivity to ${productFocus} messaging. Focus on maintaining momentum and expanding IBSA share (currently ${hcp.ibsa_share}%).`
  }
  
  if (ngd === 'Decliner') {
    return `Re-engage and retain this declining prescriber (${hcp.name}). Address competitive pressures and reinforce ${productFocus}'s value proposition to prevent further decline. Current IBSA share: ${hcp.ibsa_share}%.`
  }
  
  if (ngd === 'New') {
    return `Establish relationship with this new potential prescriber. Initial engagement focused on understanding patient population and introducing ${productFocus} as a treatment solution for their ${hcp.specialty} practice.`
  }
  
  if (ngd === 'Stable') {
    return `Strengthen relationship with this stable prescriber. Maintain IBSA share (${hcp.ibsa_share}%) and explore opportunities for increased prescribing across additional product lines beyond ${productFocus}.`
  }

  // Default based on action
  return `Execute ${action} strategy to optimize ${productFocus} prescribing. Call success probability: ${Math.round(predictions.call_success_prob * 100)}%.`
}

function generateOpeningStatement(hcp: HCP, predictions: Predictions): string {
  const callSuccess = predictions.call_success_prob
  const daysSinceCall = hcp.days_since_call || 0
  const productFocus = predictions.product_focus
  const ngd = predictions.ngd_classification

  // High-engagement HCPs with strong IBSA relationship
  if (callSuccess > 0.7 && hcp.trx_current > 20) {
    return `Thank you for your continued partnership with IBSA. Your patients have benefited from ${hcp.trx_current} IBSA prescriptions this quarter. Today I'd like to share new ${productFocus} clinical insights and discuss expanding our collaboration.`
  }
  
  // Growing prescribers - capitalize on momentum
  if (ngd === 'Grower' && callSuccess > 0.6) {
    return `I'm excited to see your growing confidence in IBSA products—up ${Math.abs(hcp.trx_growth)}% from last quarter. Let's discuss how ${productFocus} can continue to benefit your patients and practice.`
  }

  // Re-engagement for declining prescribers
  if (ngd === 'Decliner' && daysSinceCall > 45) {
    return `It's been ${daysSinceCall} days since we last connected, and I wanted to personally follow up. I have some compelling ${productFocus} updates that address common concerns in ${hcp.specialty} practices.`
  }
  
  // Standard engagement (moderate success probability)
  if (callSuccess > 0.5) {
    if (daysSinceCall > 60) {
      return `Thanks for taking my call after ${daysSinceCall} days. I've brought targeted ${productFocus} information that aligns with your ${hcp.specialty} patient population.`
    } else {
      return `I appreciate your time today. I have ${productFocus} clinical updates specifically relevant to your prescribing patterns in ${hcp.specialty}.`
    }
  }

  // Low-engagement approach - brief and value-focused
  return `I know you're busy, Dr. ${hcp.name.split(' ').pop()}, so I'll be brief. I have clinically differentiated ${productFocus} data that may benefit your ${hcp.specialty} patients.`
}

function generateGrowthMessage(hcp: HCP, predictions: Predictions): string {
  const lift = predictions.forecasted_lift
  const currentTrx = hcp.trx_current
  const productFocus = predictions.product_focus
  const trxGrowth = hcp.trx_growth

  // Growers with strong lift potential
  if (predictions.ngd_classification === 'Grower' && lift > 10) {
    return `🚀 Strong Growth Trajectory: This HCP increased IBSA prescribing by ${Math.round(Math.abs(trxGrowth))}% last quarter and our models predict ${Math.round(lift)} additional TRx potential with focused ${productFocus} engagement. Key opportunity to solidify IBSA as preferred brand.`
  }

  // Growers with moderate momentum
  if (predictions.ngd_classification === 'Grower') {
    return `📈 Growing Momentum Detected: Recent ${Math.round(Math.abs(trxGrowth))}% increase in prescribing (${currentTrx} TRx) signals strong receptivity. Continue clinical education on ${productFocus} to accelerate adoption across broader patient population.`
  }

  // High lift potential for stable/new prescribers
  if (lift > 20 && currentTrx < 50) {
    return `💡 Untapped Potential: With current ${currentTrx} TRx baseline, our ML models identify ${Math.round(lift)}% expansion opportunity for ${productFocus}. This HCP's specialty (${hcp.specialty}) and patient volume align perfectly with IBSA's clinical profile.`
  }

  // Moderate lift opportunity
  if (lift > 5) {
    return `⬆️ Solid Growth Opportunity: Predictive models forecast ${Math.round(lift)} additional ${productFocus} TRx over next quarter (${Math.round((lift/currentTrx)*100)}% increase from ${currentTrx} baseline). Focus on clinical differentiation and sample support.`
  }

  // Incremental growth for established prescribers
  if (currentTrx > 50) {
    return `🎯 Volume Optimization: Already prescribing ${currentTrx} IBSA TRx—focus on product mix optimization. Shift emphasis from ${productFocus} education to exploring additional IBSA products where this practice has unmet needs.`
  }

  return `📊 Incremental Opportunity: Build from ${currentTrx} TRx baseline with consistent ${productFocus} touchpoints and sample support. Track progress over 2-3 quarter timeframe.`
}

function generateRiskMessage(hcp: HCP, predictions: Predictions): string {
  const ngd = predictions.ngd_classification
  const trxGrowth = hcp.trx_growth
  const productFocus = predictions.product_focus
  const ibsaShare = hcp.ibsa_share
  const callSuccess = predictions.call_success_prob

  // Severe decline requiring immediate action
  if (ngd === 'Decliner' && trxGrowth < -20) {
    return `🚨 URGENT: Critical ${Math.round(Math.abs(trxGrowth))}% decline in ${productFocus} prescribing detected. Immediate intervention required—schedule strategic account review with District Manager. Investigate formulary changes, competitive detailing, or patient population shifts. This account is at risk.`
  }

  // Moderate decline with low engagement
  if (ngd === 'Decliner' && callSuccess < 0.5) {
    return `⚠️ CAUTION: Declining prescribing pattern (${Math.round(Math.abs(trxGrowth))}% decrease) combined with low engagement score suggests relationship strain. Probe for concerns, competitive pressures, or service gaps. Reinforce ${productFocus} clinical differentiation and IBSA support programs.`
  }

  // General decline warning
  if (ngd === 'Decliner') {
    return `⚠️ Declining Trend Alert: ${Math.round(Math.abs(trxGrowth))}% decrease in IBSA TRx indicates competitive pressure or shifting treatment preferences. Use this call to understand barriers, address objections, and demonstrate ${productFocus}'s clinical value vs. competitor alternatives.`
  }

  // Low IBSA share warning (even if not declining)
  if (ibsaShare < 10 && hcp.trx_current > 20) {
    return `⚠️ Low Share Alert: Only ${ibsaShare}% IBSA share despite high prescribing volume (${hcp.trx_current} total TRx). Significant competitive displacement opportunity. Position ${productFocus} as first-line alternative with superior clinical profile.`
  }

  // Low engagement risk for stable prescribers
  if (callSuccess < 0.4 && hcp.days_since_call && hcp.days_since_call > 90) {
    return `⚠️ Relationship Risk: ${hcp.days_since_call} days since last contact with low engagement probability. Account may be drifting toward competitors. Prioritize rebuilding rapport and demonstrating IBSA's commitment to supporting this practice.`
  }

  return `⚠️ Monitor Closely: Some prescribing instability detected. Use this call to strengthen relationship, address any formulary/access issues, and ensure awareness of IBSA's full portfolio and patient support resources.`
}

function generateROIMessage(hcp: HCP, predictions: Predictions): string {
  const callSuccess = predictions.call_success_prob
  const lift = predictions.forecasted_lift
  const productFocus = predictions.product_focus
  const tier = hcp.tier
  const currentTrx = hcp.trx_current

  // Platinum/Gold tier with high potential
  if ((tier === 'Platinum' || tier === 'Gold') && callSuccess > 0.7 && lift > 10) {
    return `💰 High-Value Investment: ${tier} tier account with ${Math.round(callSuccess * 100)}% call success probability and ${Math.round(lift)} TRx lift potential. Allocate 30-45 minutes for comprehensive ${productFocus} clinical discussion, sample provision, and relationship deepening. This interaction drives significant business impact.`
  }

  // Strong opportunity metrics
  if (callSuccess > 0.7 && lift > 10) {
    return `✨ Excellent Engagement Opportunity: ${Math.round(callSuccess * 100)}% success probability + ${Math.round(lift)} TRx forecast = high-value call. Invest adequate time (30+ min) in ${productFocus} clinical evidence, peer comparisons, and sample strategy to maximize conversion impact.`
  }

  // Solid mid-tier opportunity
  if (callSuccess > 0.5 && lift > 5) {
    return `👍 Solid Call Investment: ${Math.round(callSuccess * 100)}% engagement likelihood with ${Math.round(lift)} TRx upside justifies standard 20-30 min detail. Focus on ${productFocus} clinical differentiators and evidence most relevant to this ${hcp.specialty} practice's patient mix.`
  }

  // Moderate opportunity - efficiency focus
  if (callSuccess > 0.5) {
    return `⚡ Efficient Engagement: ${Math.round(callSuccess * 100)}% receptivity expected. Target 15-20 min focused interaction on ${productFocus} key messages. Prioritize clinical differentiation and leave comprehensive samples/literature for post-call reinforcement.`
  }

  // Low engagement - awareness maintenance
  if (currentTrx < 10) {
    return `🎯 Awareness Builder: Low baseline (${currentTrx} TRx) suggests early-stage relationship. Brief 10-15 min interaction focused on ${productFocus} clinical positioning vs. competitors. Sample drop and follow-up literature to establish IBSA mindshare.`
  }

  return `📋 Maintain Presence: Consistent touchpoints preserve IBSA awareness for ${productFocus}. Consider efficient approaches: sample drop, virtual detail, or brief check-in to maintain relationship without over-investing time.`
}

function generateSampleMessage(hcp: HCP, predictions: Predictions): string {
  const sampleAlloc = predictions.sample_allocation
  const callSuccess = predictions.call_success_prob
  const productFocus = predictions.product_focus
  const ngd = predictions.ngd_classification
  const lift = predictions.forecasted_lift

  // High-impact sample allocation strategy
  if (callSuccess > 0.7 && lift > 10) {
    return `✅ HIGH-IMPACT SAMPLING: Strong engagement (${Math.round(callSuccess * 100)}%) + high lift potential (${Math.round(lift)} TRx) = excellent sample ROI. Provide ${sampleAlloc} units of ${productFocus} with clear patient selection guidance: "Use these samples for patients who would most benefit from [specific clinical attribute]. Let's reconnect in 3-4 weeks to discuss patient outcomes."`
  }

  // Growth opportunity sampling
  if (ngd === 'Grower' && sampleAlloc > 10) {
    return `🚀 Growth Acceleration: This HCP is actively expanding IBSA use—provide ${sampleAlloc} ${productFocus} samples to capitalize on momentum. Frame samples as: "Support for your growing patient population on IBSA therapy. These will help you start additional appropriate patients while they navigate insurance coverage."`
  }

  // Moderate engagement sampling
  if (callSuccess > 0.5 && sampleAlloc > 5) {
    return `💼 Strategic Sample Provision: Allocate ${sampleAlloc} ${productFocus} units with clinical rationale: "These samples enable immediate therapy initiation and tolerability assessment before full prescription commitment. Ideal for patients with [indication] who meet [criteria]." Set expectation for follow-up on patient response.`
  }

  // Standard allocation for relationship building
  if (sampleAlloc > 0) {
    return `🤝 Relationship Builder: Provide ${sampleAlloc} ${productFocus} samples as tangible support gesture. Position as practice resource: "Keep these on hand for appropriate patients. Sample therapy often increases patient compliance and satisfaction by removing initial cost barriers."`
  }

  // No allocation - focus on clinical discussion
  return `📚 Clinical Focus: Sample allocation not prioritized this call—invest time in clinical discussion and understanding prescribing barriers instead. Address any formulary, access, or efficacy concerns that may be limiting ${productFocus} adoption.`
}

function generateFollowupMessage(hcp: HCP, predictions: Predictions): string {
  const bestDay = predictions.best_day
  const bestTime = predictions.best_time
  const ngdClass = predictions.ngd_classification
  const productFocus = predictions.product_focus
  const callSuccess = predictions.call_success_prob
  const lift = predictions.forecasted_lift

  let timing = ''
  if (bestDay && bestTime) {
    timing = `📅 Optimal timing: ${bestDay} ${bestTime} (based on historical access patterns).`
  }

  // Growers - accelerate momentum
  if (ngdClass === 'Grower' && lift > 10) {
    return `🎯 Momentum Follow-Up (3-4 weeks): Schedule next interaction to capture ${productFocus} patient starts and prescription conversions. ${timing} Agenda: Review outcomes from today's samples, discuss patient response, and identify additional opportunities to expand IBSA utilization. Bring case studies from similar ${hcp.specialty} practices.`
  }

  if (ngdClass === 'Grower') {
    return `📈 Growth Tracking (4-6 weeks): Follow up to assess ${productFocus} adoption trajectory and support continued expansion. ${timing} Goal: Document patient outcomes, address any initial concerns, and reinforce clinical confidence with peer prescriber experiences.`
  }

  // Decliners - urgent retention
  if (ngdClass === 'Decliner') {
    return `🚨 Retention Follow-Up (2 weeks): CRITICAL—schedule prompt follow-up to address concerns raised today about ${productFocus} and demonstrate IBSA's commitment to this practice. ${timing} Consider bringing clinical specialist or District Manager to strategic re-engagement meeting. Document all feedback for account planning.`
  }

  // High-value engaged accounts - maintain cadence
  if (callSuccess > 0.7 && hcp.tier === 'Platinum') {
    return `⭐ VIP Cadence (Quarterly): Maintain consistent touchpoints with this high-value, receptive prescriber. ${timing} Next call focus: Share new ${productFocus} clinical data, review patient outcomes, explore portfolio expansion opportunities, and provide priority access to IBSA resources/programs.`
  }

  if (callSuccess > 0.7) {
    return `✅ Standard Cadence (Quarterly): This receptive prescriber deserves regular engagement. ${timing} Next interaction: Review ${productFocus} patient outcomes from today's samples, introduce latest clinical evidence, and explore opportunities for increased IBSA utilization across additional indications.`
  }

  // New/low-engagement - longer cycle
  if (ngdClass === 'New' || callSuccess < 0.5) {
    return `🌱 Relationship Building (6-8 weeks): Follow up with relevant ${productFocus} clinical updates or peer case studies. ${timing} Goal: Build relationship incrementally through value-added interactions rather than frequent sales calls. Focus on becoming trusted clinical resource.`
  }

  return `📆 Standard Follow-Up (6-8 weeks): Reconnect with ${productFocus} clinical updates, new indication data, or patient support program enhancements. ${timing} Maintain consistent presence without over-saturating this account.`
}

function generateClinicalPoints(hcp: HCP, predictions: Predictions): string[] {
  const points: string[] = []
  const specialty = hcp.specialty
  const productFocus = predictions.product_focus
  const ngd = predictions.ngd_classification
  const ibsaShare = hcp.ibsa_share

  // Product-specific clinical messaging
  if (productFocus === 'Tirosint') {
    points.push('Tirosint gel caps: Only T4 therapy with proven bioequivalence across fasting/fed states—eliminates timing restrictions')
    points.push('Superior consistency vs. tablet formulations: reduced TSH variability and fewer dose adjustments in clinical studies')
    if (specialty.includes('Endocrin') || specialty.includes('Internal Medicine')) {
      points.push('Ideal for patients with absorption issues, GI comorbidities, or bariatric surgery history')
    }
  } else if (productFocus === 'Flector') {
    points.push('Flector Patch: Targeted topical NSAID delivery with 12-hour continuous diclofenac release')
    points.push('Minimizes systemic exposure vs. oral NSAIDs—better GI/CV safety profile for at-risk patients')
    if (specialty.includes('Orthopedic') || specialty.includes('Pain') || specialty.includes('Sports Medicine')) {
      points.push('Excellent for acute musculoskeletal injuries, post-procedure pain, and active patients who need mobility')
    }
  } else if (productFocus === 'Licart') {
    points.push('Licart: Lidocaine topical system for localized neuropathic pain management')
    points.push('Non-opioid alternative with minimal systemic absorption—important in current prescribing environment')
    if (specialty.includes('Neurology') || specialty.includes('Pain') || specialty.includes('Anesthesiology')) {
      points.push('Effective for postherpetic neuralgia, diabetic neuropathy, and other localized neuropathic conditions')
    }
  }

  // NGD-specific clinical points
  if (ngd === 'New' || ibsaShare < 15) {
    points.push(`Provide comprehensive product education: mechanism of action, clinical trial data, and head-to-head comparisons vs. competitors`)
    points.push(`Share peer testimonials from similar ${specialty} practices who have successfully integrated ${productFocus} into their protocols`)
  }

  if (ngd === 'Grower') {
    points.push(`Reinforce clinical confidence: Share real-world evidence and registry data supporting expanded ${productFocus} use`)
    points.push(`Discuss patient selection optimization: which subpopulations benefit most from ${productFocus} vs. alternatives`)
  }

  if (ngd === 'Decliner') {
    points.push(`Address competitive messaging: Clarify ${productFocus} clinical differentiation vs. recent competitor claims`)
    points.push(`Overcome objections with evidence: Review any concerns about efficacy, safety, or cost-effectiveness`)
  }

  // High-engagement call success strategy
  if (predictions.call_success_prob > 0.6) {
    points.push(`Encourage immediate trial: Provide samples with clear patient selection criteria to drive first prescriptions`)
  }

  // Low IBSA share - competitive displacement
  if (ibsaShare < 20 && hcp.trx_current > 20) {
    points.push(`Competitive displacement strategy: Position ${productFocus} as superior first-line alternative with clinical evidence`)
  }

  return points
}

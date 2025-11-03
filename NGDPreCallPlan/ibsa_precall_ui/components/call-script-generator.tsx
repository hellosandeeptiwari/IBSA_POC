'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
  FileText, 
  Sparkles, 
  CheckCircle2, 
  AlertTriangle, 
  Copy, 
  Download,
  RefreshCw,
  Loader2,
  Bot,
  Shield,
  Zap
} from 'lucide-react'

interface CallScriptGeneratorProps {
  hcpId: string
  hcpName: string
  specialty: string
}

interface ScriptSection {
  title: string
  content: string
  mlr_ids?: string[]
}

interface ComplianceViolation {
  type: string
  severity: string
  details: string
}

interface GeneratedScript {
  scenario: string
  priority: string
  opening: string
  talking_points: ScriptSection[]
  objection_handlers: ScriptSection[]
  call_to_action: string
  next_steps: string[]
  disclaimers: string[]
  mlr_content_used: string[]
}

interface ScriptResponse {
  hcp_id: string
  scenario: string
  priority: string
  script: GeneratedScript
  compliance: {
    is_compliant: boolean
    violations: ComplianceViolation[]
    total_violations: number
    severity_breakdown: { [key: string]: number }
  }
  metadata: {
    generated_at: string
    generated_by: string
    gpt4_used: boolean
    generation_time_ms: number
  }
  generation_time_seconds: number
  cost_usd: number
}

const API_URL = 'http://localhost:8000'
const API_KEY = 'ibsa-ai-script-generator-2025'

export function CallScriptGenerator({ hcpId, hcpName, specialty }: CallScriptGeneratorProps) {
  const [loading, setLoading] = useState(false)
  const [script, setScript] = useState<ScriptResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)

  const generateScript = async (includeGpt4: boolean = true) => {
    setLoading(true)
    setError(null)
    
    try {
      const response = await fetch(`${API_URL}/generate-call-script`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': API_KEY
        },
        body: JSON.stringify({
          hcp_id: hcpId,
          include_gpt4: includeGpt4
        })
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.detail || 'Failed to generate script')
      }

      const data: ScriptResponse = await response.json()
      setScript(data)
    } catch (err) {
      console.error('Error generating script:', err)
      setError(err instanceof Error ? err.message : 'Failed to generate script')
    } finally {
      setLoading(false)
    }
  }

  const copyToClipboard = () => {
    if (!script) return
    
    const text = formatScriptAsText(script.script)
    navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const downloadScript = () => {
    if (!script) return
    
    const text = formatScriptAsText(script.script)
    const blob = new Blob([text], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `call-script-${hcpId}-${Date.now()}.txt`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  const formatScriptAsText = (scriptData: GeneratedScript): string => {
    let text = `CALL SCRIPT FOR ${hcpName.toUpperCase()}\n`
    text += `Specialty: ${specialty}\n`
    text += `Scenario: ${scriptData.scenario}\n`
    text += `Priority: ${scriptData.priority}\n`
    text += `\n${'='.repeat(80)}\n\n`

    text += `OPENING:\n${scriptData.opening}\n\n`

    text += `${'='.repeat(80)}\n`
    text += `TALKING POINTS:\n`
    text += `${'='.repeat(80)}\n\n`
    scriptData.talking_points.forEach((point, idx) => {
      text += `${idx + 1}. ${point.title}\n`
      text += `${point.content}\n`
      if (point.mlr_ids) {
        text += `   [MLR IDs: ${point.mlr_ids.join(', ')}]\n`
      }
      text += `\n`
    })

    text += `${'='.repeat(80)}\n`
    text += `OBJECTION HANDLERS:\n`
    text += `${'='.repeat(80)}\n\n`
    scriptData.objection_handlers.forEach((handler, idx) => {
      text += `${idx + 1}. ${handler.title}\n`
      text += `${handler.content}\n\n`
    })

    text += `${'='.repeat(80)}\n`
    text += `CALL TO ACTION:\n`
    text += `${'='.repeat(80)}\n\n`
    text += `${scriptData.call_to_action}\n\n`

    text += `${'='.repeat(80)}\n`
    text += `NEXT STEPS:\n`
    text += `${'='.repeat(80)}\n\n`
    scriptData.next_steps.forEach((step, idx) => {
      text += `${idx + 1}. ${step}\n`
    })

    text += `\n${'='.repeat(80)}\n`
    text += `REQUIRED DISCLAIMERS:\n`
    text += `${'='.repeat(80)}\n\n`
    scriptData.disclaimers.forEach((disclaimer, idx) => {
      text += `⚠️ ${disclaimer}\n\n`
    })

    text += `${'='.repeat(80)}\n`
    text += `MLR-APPROVED CONTENT USED:\n`
    text += `${'='.repeat(80)}\n\n`
    scriptData.mlr_content_used.forEach((id, idx) => {
      text += `• ${id}\n`
    })

    return text
  }

  return (
    <div className="space-y-6">
      {/* Header with Actions */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Sparkles className="h-6 w-6 text-blue-600" />
              <div>
                <h2 className="text-2xl font-bold">AI Call Script Generator</h2>
                <p className="text-sm text-gray-600">
                  Generate MLR-compliant, personalized call scripts powered by AI
                </p>
              </div>
            </div>
            
            {script && (
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={copyToClipboard}
                  disabled={loading}
                >
                  {copied ? <CheckCircle2 className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                  {copied ? 'Copied!' : 'Copy'}
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={downloadScript}
                  disabled={loading}
                >
                  <Download className="h-4 w-4" />
                  Download
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => generateScript(true)}
                  disabled={loading}
                >
                  <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
                  Regenerate
                </Button>
              </div>
            )}
          </div>
        </CardHeader>
        
        <CardContent>
          {/* Generate Buttons */}
          {!script && (
            <div className="flex gap-4">
              <Button
                onClick={() => generateScript(true)}
                disabled={loading}
                size="lg"
                className="flex-1"
              >
                {loading ? (
                  <>
                    <Loader2 className="h-5 w-5 animate-spin mr-2" />
                    Generating Script...
                  </>
                ) : (
                  <>
                    <Sparkles className="h-5 w-5 mr-2" />
                    Generate with AI Enhancement
                  </>
                )}
              </Button>
              
              <Button
                onClick={() => generateScript(false)}
                disabled={loading}
                variant="outline"
                size="lg"
              >
                <FileText className="h-5 w-5 mr-2" />
                Template Only
              </Button>
            </div>
          )}

          {/* Error Display */}
          {error && (
            <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-red-900">Error Generating Script</p>
                <p className="text-sm text-red-700">{error}</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Generated Script Display */}
      {script && (
        <>
          {/* Compliance Status */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold">Compliance Status</h3>
                {script.compliance.is_compliant ? (
                  <div className="flex items-center gap-2 text-green-600">
                    <CheckCircle2 className="h-5 w-5" />
                    <span className="font-semibold">MLR Compliant</span>
                  </div>
                ) : (
                  <div className="flex items-center gap-2 text-red-600">
                    <AlertTriangle className="h-5 w-5" />
                    <span className="font-semibold">{script.compliance.total_violations} Violations</span>
                  </div>
                )}
              </div>
            </CardHeader>
            
            {!script.compliance.is_compliant && (
              <CardContent>
                <div className="space-y-2">
                  {script.compliance.violations.map((violation, idx) => (
                    <div key={idx} className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                      <p className="font-semibold text-yellow-900">
                        {violation.type} ({violation.severity})
                      </p>
                      <p className="text-sm text-yellow-700">{violation.details}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            )}
          </Card>

          {/* Script Content */}
          <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-blue-50">
            <CardHeader className="bg-gradient-to-r from-purple-600 to-blue-600 text-white">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-white/20 rounded-lg backdrop-blur">
                    <Bot className="h-6 w-6" />
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold flex items-center gap-2">
                      AI-Generated Call Script
                      <span className="px-2 py-0.5 bg-white/20 rounded-full text-xs font-medium">
                        {script.metadata.gpt4_used ? '🤖 GPT-4 Enhanced' : '📄 Template Based'}
                      </span>
                    </h3>
                    <p className="text-sm text-white/80">
                      Scenario: <strong>{script.scenario}</strong> | Priority: <strong>{script.priority}</strong> | Generated in: <strong>{script.generation_time_seconds.toFixed(2)}s</strong>
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2 px-3 py-1 bg-white/20 rounded-full backdrop-blur">
                  <Shield className="h-4 w-4" />
                  <span className="text-xs font-medium">MLR Compliant</span>
                </div>
              </div>
            </CardHeader>
            
            <CardContent className="space-y-6 mt-4">
              {/* Opening */}
              <div className="relative border-2 border-dashed border-purple-300 rounded-lg p-4 bg-white">
                <div className="absolute -top-3 left-4 px-2 bg-purple-100 rounded-full flex items-center gap-1">
                  <Sparkles className="h-3 w-3 text-purple-600" />
                  <span className="text-xs font-semibold text-purple-700">AI Generated</span>
                </div>
                <h4 className="font-semibold text-lg mb-2 text-blue-600 flex items-center gap-2">
                  Opening
                </h4>
                <p className="text-gray-700 whitespace-pre-line">{script.script.opening}</p>
              </div>

              {/* Talking Points */}
              <div className="relative border-2 border-dashed border-purple-300 rounded-lg p-4 bg-white">
                <div className="absolute -top-3 left-4 px-2 bg-purple-100 rounded-full flex items-center gap-1">
                  <Sparkles className="h-3 w-3 text-purple-600" />
                  <span className="text-xs font-semibold text-purple-700">AI Generated</span>
                </div>
                <h4 className="font-semibold text-lg mb-3 text-blue-600">Talking Points</h4>
                <div className="space-y-4">
                  {script.script.talking_points.map((point, idx) => (
                    <div key={idx} className="pl-4 border-l-4 border-blue-300">
                      <h5 className="font-semibold text-gray-900 mb-1">{idx + 1}. {point.title}</h5>
                      <p className="text-gray-700 whitespace-pre-line">{point.content}</p>
                      {point.mlr_ids && point.mlr_ids.length > 0 && (
                        <p className="text-xs text-gray-500 mt-1">MLR IDs: {point.mlr_ids.join(', ')}</p>
                      )}
                    </div>
                  ))}
                </div>
              </div>

              {/* Objection Handlers */}
              <div className="relative border-2 border-dashed border-purple-300 rounded-lg p-4 bg-white">
                <div className="absolute -top-3 left-4 px-2 bg-purple-100 rounded-full flex items-center gap-1">
                  <Sparkles className="h-3 w-3 text-purple-600" />
                  <span className="text-xs font-semibold text-purple-700">AI Generated</span>
                </div>
                <h4 className="font-semibold text-lg mb-3 text-blue-600">Objection Handlers</h4>
                <div className="space-y-4">
                  {script.script.objection_handlers.map((handler, idx) => (
                    <div key={idx} className="p-4 bg-gray-50 rounded-lg">
                      <h5 className="font-semibold text-gray-900 mb-2">{handler.title}</h5>
                      <p className="text-gray-700 whitespace-pre-line">{handler.content}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Call to Action */}
              <div className="relative border-2 border-dashed border-purple-300 rounded-lg p-4 bg-white">
                <div className="absolute -top-3 left-4 px-2 bg-purple-100 rounded-full flex items-center gap-1">
                  <Zap className="h-3 w-3 text-purple-600" />
                  <span className="text-xs font-semibold text-purple-700">AI Generated</span>
                </div>
                <h4 className="font-semibold text-lg mb-2 text-blue-600">Call to Action</h4>
                <p className="text-gray-700 whitespace-pre-line bg-green-50 p-4 rounded-lg border border-green-200">
                  {script.script.call_to_action}
                </p>
              </div>

              {/* Next Steps */}
              <div className="relative border-2 border-dashed border-purple-300 rounded-lg p-4 bg-white">
                <div className="absolute -top-3 left-4 px-2 bg-purple-100 rounded-full flex items-center gap-1">
                  <Sparkles className="h-3 w-3 text-purple-600" />
                  <span className="text-xs font-semibold text-purple-700">AI Generated</span>
                </div>
                <h4 className="font-semibold text-lg mb-2 text-blue-600">Next Steps</h4>
                <ul className="space-y-2">
                  {script.script.next_steps.map((step, idx) => (
                    <li key={idx} className="flex items-start gap-2">
                      <CheckCircle2 className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-700">{step}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Disclaimers */}
              <div className="bg-yellow-50 border-2 border-yellow-300 rounded-lg p-4 relative">
                <div className="absolute -top-3 left-4 px-2 bg-yellow-200 rounded-full flex items-center gap-1">
                  <Shield className="h-3 w-3 text-yellow-700" />
                  <span className="text-xs font-semibold text-yellow-800">MLR Approved</span>
                </div>
                <h4 className="font-semibold text-lg mb-3 text-yellow-900 flex items-center gap-2">
                  <AlertTriangle className="h-5 w-5" />
                  Required Disclaimers
                </h4>
                <div className="space-y-2">
                  {script.script.disclaimers.map((disclaimer, idx) => (
                    <p key={idx} className="text-sm text-yellow-800">⚠️ {disclaimer}</p>
                  ))}
                </div>
              </div>

              {/* MLR Content Used */}
              <div>
                <h4 className="font-semibold text-sm mb-2 text-gray-600">MLR-Approved Content Used</h4>
                <div className="flex flex-wrap gap-2">
                  {script.script.mlr_content_used.map((id, idx) => (
                    <span key={idx} className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded-full">
                      {id}
                    </span>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  )
}

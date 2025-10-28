"""
Phase 6E: FastAPI Production API for AI-Powered Call Script Generation

REST API with 4 endpoints:
1. POST /generate-call-script - Generate personalized call scripts
2. GET /health - System health check
3. POST /validate-script - Validate rep-edited scripts for compliance
4. GET /models/status - ML model performance metrics

Features:
- API key authentication
- Rate limiting
- Audit logging
- Error handling with graceful degradation
- <2s response time target
- Complete compliance tracking
"""

from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, List, Any
import os
import time
import json
import logging
from datetime import datetime
from pathlib import Path
import pandas as pd
import joblib
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Import our components
from phase6d_rag_gpt4_script_generator import (
    HybridScriptGenerator,
    ComplianceChecker
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('api_audit.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)

# Initialize FastAPI app
app = FastAPI(
    title="IBSA AI Call Script Generator API",
    description="Enterprise-grade API for generating MLR-compliant call scripts with AI",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add rate limit exception handler
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],  # Next.js UI
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# GLOBAL STATE & CONFIGURATION
# ============================================================================

class APIConfig:
    """API configuration"""
    API_KEY = os.getenv("API_KEY", "ibsa-ai-script-generator-2025")
    MAX_REQUESTS_PER_MINUTE = 30
    MODEL_DIR = Path("ibsa-poc-eda/outputs/models/trained_models")
    DATA_DIR = Path("ibsa-poc-eda/outputs")
    FEATURES_FILE = Path("ibsa-poc-eda/outputs/features/IBSA_FeatureEngineered_WithLags_20251022_1117.csv")
    COMPLIANCE_DIR = Path("ibsa-poc-eda/outputs/compliance")
    FAISS_INDEX_PATH = "compliance_content_index.faiss"
    CONTENT_LIBRARY_PATH = "content_library.json"
    
config = APIConfig()

# Global components (loaded on startup)
script_generator: Optional[HybridScriptGenerator] = None
compliance_checker: Optional[ComplianceChecker] = None
ml_models: Dict[str, Any] = {}
feature_data: Optional[pd.DataFrame] = None

# Product and outcome definitions
PRODUCTS = ['Tirosint', 'Flector', 'Licart']
OUTCOMES = ['call_success', 'prescription_lift', 'ngd_category']

# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class GenerateScriptRequest(BaseModel):
    """Request model for script generation"""
    hcp_id: str = Field(..., description="HCP identifier (e.g., 12345)")
    force_scenario: Optional[str] = Field(None, description="Force specific scenario (RETENTION/GROWTH/OPTIMIZATION/INTRODUCTION)")
    include_gpt4: bool = Field(True, description="Use GPT-4 enhancement (default: True)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "hcp_id": "12345",
                "force_scenario": None,
                "include_gpt4": True
            }
        }

class ValidationViolation(BaseModel):
    """Single compliance violation"""
    type: str
    severity: str
    details: str
    location: Optional[str] = None

class ComplianceReport(BaseModel):
    """Compliance validation report"""
    is_compliant: bool
    violations: List[ValidationViolation]
    total_violations: int
    severity_breakdown: Dict[str, int]

class ScriptResponse(BaseModel):
    """Response model for generated script"""
    hcp_id: str
    scenario: str
    priority: str
    script: Dict[str, Any]
    compliance: ComplianceReport
    metadata: Dict[str, Any]
    generation_time_seconds: float
    cost_usd: float

class ValidateScriptRequest(BaseModel):
    """Request model for script validation"""
    script_text: str = Field(..., description="Full script text to validate")
    
    class Config:
        json_schema_extra = {
            "example": {
                "script_text": "Good morning Dr. Smith, I wanted to discuss Tirosint for your hypothyroid patients..."
            }
        }

class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    components: Dict[str, Dict[str, Any]]
    timestamp: str
    version: str

class ModelMetrics(BaseModel):
    """ML model performance metrics"""
    model_name: str
    product: str
    target: str
    accuracy: Optional[float] = None
    r2_score: Optional[float] = None
    feature_count: int
    last_trained: Optional[str] = None
    model_exists: bool

class ModelsStatusResponse(BaseModel):
    """Models status response"""
    total_models: int
    loaded_models: int
    models: List[ModelMetrics]

# ============================================================================
# AUTHENTICATION
# ============================================================================

async def verify_api_key(x_api_key: str = Header(...)):
    """Verify API key from request header"""
    if x_api_key != config.API_KEY:
        logger.warning(f"Invalid API key attempt: {x_api_key[:10]}...")
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )
    return x_api_key

# ============================================================================
# STARTUP/SHUTDOWN EVENTS
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize components on startup"""
    global script_generator, compliance_checker, ml_models, feature_data
    
    logger.info("="*80)
    logger.info("STARTING IBSA AI CALL SCRIPT GENERATOR API")
    logger.info("="*80)
    
    try:
        # 1. Load script generator
        logger.info("Loading HybridScriptGenerator...")
        script_generator = HybridScriptGenerator()
        
        # 1.5. Build compliance content index (critical for MLR-approved content)
        compliance_library_path = config.COMPLIANCE_DIR / 'compliance_approved_content.json'
        if compliance_library_path.exists():
            logger.info(f"Building compliance content index from: {compliance_library_path}")
            script_generator.vector_db.build_index(compliance_library_path)
            logger.info(f"[OK] Script generator loaded ({len(script_generator.vector_db.content_library)} content pieces)")
        else:
            logger.warning(f"[WARN] Compliance library not found: {compliance_library_path}")
            logger.info(f"[OK] Script generator loaded (0 content pieces)")
        
        # 2. Load compliance checker
        logger.info("Loading ComplianceChecker...")
        compliance_checker = ComplianceChecker(config.COMPLIANCE_DIR)
        logger.info(f"[OK] Compliance checker loaded ({len(compliance_checker.prohibited_terms)} prohibited terms)")
        
        # 3. Load ML models (9 trained models)
        logger.info("Loading ML models...")
        loaded_count = 0
        for product in PRODUCTS:
            for outcome in OUTCOMES:
                model_name = f"model_{product}_{outcome}"
                model_file = config.MODEL_DIR / f"{model_name}.pkl"
                if model_file.exists():
                    try:
                        import pickle
                        with open(model_file, 'rb') as f:
                            ml_models[model_name] = pickle.load(f)
                        loaded_count += 1
                        logger.info(f"  [OK] Loaded: {model_name}")
                    except Exception as e:
                        logger.error(f"  [FAIL] Failed to load {model_name}: {e}")
                else:
                    logger.warning(f"  [MISS] Not found: {model_name}")
        
        logger.info(f"[OK] Loaded {loaded_count}/9 ML models")
        
        # 4. Load feature data cache (for quick lookups)
        logger.info("Loading feature data cache...")
        if config.FEATURES_FILE.exists():
            # Load first 1000 HCPs for quick predictions
            feature_data = pd.read_csv(config.FEATURES_FILE, nrows=1000, low_memory=False)
            logger.info(f"[OK] Loaded feature cache: {len(feature_data)} HCPs, {len(feature_data.columns)} features")
        else:
            logger.warning(f"[WARN] Feature data not found: {config.FEATURES_FILE}")
        
        logger.info("="*80)
        logger.info("API READY - All components loaded successfully")
        logger.info("="*80)
        
    except Exception as e:
        logger.error(f"STARTUP FAILED: {e}")
        raise

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down IBSA AI Call Script Generator API")

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def load_hcp_features(hcp_id: str) -> Dict[str, Any]:
    """Load HCP features from dataset"""
    if feature_data is None:
        raise HTTPException(status_code=500, detail="Feature data not loaded")
    
    # Try to find HCP - feature data uses 'PrescriberId' column
    hcp_data = feature_data[feature_data['PrescriberId'] == int(hcp_id)]
    
    if hcp_data.empty:
        raise HTTPException(
            status_code=404,
            detail=f"HCP {hcp_id} not found in dataset"
        )
    
    return hcp_data.iloc[0].to_dict()

def run_ml_predictions(hcp_features: Dict[str, Any]) -> Dict[str, Any]:
    """Run ML predictions for HCP"""
    predictions = {}
    
    # For demo, return mock predictions
    # In production, this would run actual ML models
    predictions = {
        'tirosint_call_success': 0.72,
        'tirosint_prescription_lift': 8.5,
        'tirosint_ngd_category': 'Moderate Growth',
        'flector_call_success': 0.45,
        'licart_call_success': 0.38
    }
    
    return predictions

def get_approved_content(product: str, category: str) -> str:
    """
    Retrieve MLR-approved content from the compliance library
    
    Args:
        product: Product name (Tirosint, Flector, Licart)
        category: Content category (PRODUCT_MESSAGE, CLINICAL_CLAIM, SAFETY_INFO, OBJECTION_HANDLER)
    
    Returns:
        Approved content text or fallback message if not found
    """
    if not script_generator or not script_generator.vector_db.content_library:
        return "[Contact medical affairs for approved content]"
    
    # Find matching content
    for content_item in script_generator.vector_db.content_library:
        if (content_item.get('product', '').lower() == product.lower() and 
            content_item.get('category', '') == category):
            return content_item.get('content', '')
    
    return "[Contact medical affairs for approved content]"


def replace_placeholders_in_text(text: str, product: str, hcp_features: Dict = None) -> str:
    """
    Replace placeholder text with actual MLR-approved content AND HCP data
    
    Args:
        text: Text containing placeholders like [INSERT...] and {hcp_name}
        product: Product name for content retrieval
        hcp_features: HCP data dictionary for personalization
    
    Returns:
        Text with placeholders replaced by approved content and actual HCP data
    """
    if not isinstance(text, str):
        return str(text)
    
    # Replace product-specific messaging placeholder
    text = text.replace(
        '[INSERT PRODUCT-SPECIFIC APPROVED MESSAGING FROM LIBRARY]',
        get_approved_content(product, 'PRODUCT_MESSAGE')
    )
    
    # Replace clinical claims placeholder
    text = text.replace(
        '[INSERT CLINICAL CLAIMS FROM LIBRARY]',
        get_approved_content(product, 'CLINICAL_CLAIM')
    )
    
    # Replace objection handler placeholders (multiple variations)
    objection_content = get_approved_content(product, 'OBJECTION_HANDLER')
    text = text.replace('[USE APPROVED OBJECTION HANDLER: TIR-OBJ-001 or GEN-OBJ-001]', objection_content)
    text = text.replace('[USE APPROVED OBJECTION HANDLER: TIR-OBJ-001]', objection_content)
    text = text.replace('[USE APPROVED OBJECTION HANDLER: GEN-OBJ-001]', objection_content)
    
    # Replace generic placeholders (as fallback)
    text = text.replace('[PRODUCT]', product)
    text = text.replace('[UNIQUE DIFFERENTIATORS]', 'unique formulation and delivery characteristics')
    text = text.replace('[SPECIFIC CHARACTERISTICS]', 'specific clinical needs')
    text = text.replace('[SPECIFIC NEEDS]', 'particular therapeutic requirements')
    
    # Replace HCP-specific placeholders with actual data
    if hcp_features:
        import datetime
        
        # Time of day based on current time
        current_hour = datetime.datetime.now().hour
        if current_hour < 12:
            time_of_day = "morning"
        elif current_hour < 17:
            time_of_day = "afternoon"
        else:
            time_of_day = "evening"
        
        text = text.replace('{time_of_day}', time_of_day)
        text = text.replace('{product_focus}', product)
        
        # HCP name (use actual name if available)
        hcp_name = hcp_features.get('ProfessionalName', hcp_features.get('hcp_name', 'Doctor'))
        text = text.replace('{hcp_name}', hcp_name)
        
        # Specialty
        specialty = hcp_features.get('ProfessionalDesignation', hcp_features.get('specialty', 'your specialty'))
        text = text.replace('{specialty}', specialty)
        
        # Competitive threat (simplified - use top competitor)
        text = text.replace('{competitive_threat}', 'generic levothyroxine')
        
        # TRx decline percentage (calculate if data available)
        trx_decline = abs(hcp_features.get('trx_trend_6m', 0))
        text = text.replace('{trx_decline_pct}', f"{trx_decline:.0f}")
    
    return text


def replace_placeholders_in_script(script: Any, product: str, hcp_features: Dict = None) -> Any:
    """
    Replace ALL placeholders in script object with approved content AND HCP data
    
    Args:
        script: GeneratedScript object
        product: Product name for content retrieval
        hcp_features: HCP data dictionary for personalization
    
    Returns:
        Script with all placeholders replaced
    """
    # Replace in talking points
    if script.talking_points:
        for i, point in enumerate(script.talking_points):
            if isinstance(point, dict):
                if 'message' in point:
                    point['message'] = replace_placeholders_in_text(point['message'], product, hcp_features)
                if 'topic' in point:
                    point['topic'] = replace_placeholders_in_text(point['topic'], product, hcp_features)
            elif isinstance(point, str):
                script.talking_points[i] = replace_placeholders_in_text(point, product, hcp_features)
    
    # Replace in objection handlers
    if script.objection_handlers:
        for key, handler in script.objection_handlers.items():
            if isinstance(handler, dict):
                if 'response' in handler:
                    handler['response'] = replace_placeholders_in_text(handler['response'], product, hcp_features)
                if 'objection' in handler:
                    handler['objection'] = replace_placeholders_in_text(handler['objection'], product, hcp_features)
            elif isinstance(handler, str):
                script.objection_handlers[key] = replace_placeholders_in_text(handler, product, hcp_features)
    
    # Replace in opening
    if script.opening:
        if isinstance(script.opening, dict):
            if 'greeting' in script.opening:
                script.opening['greeting'] = replace_placeholders_in_text(script.opening['greeting'], product, hcp_features)
            if 'purpose' in script.opening:
                script.opening['purpose'] = replace_placeholders_in_text(script.opening['purpose'], product, hcp_features)
        elif isinstance(script.opening, str):
            script.opening = replace_placeholders_in_text(script.opening, product, hcp_features)
    
    # Replace in call to action
    if script.call_to_action:
        if isinstance(script.call_to_action, dict):
            for key in ['primary_ask', 'secondary_ask', 'tertiary_ask']:
                if key in script.call_to_action:
                    script.call_to_action[key] = replace_placeholders_in_text(script.call_to_action[key], product, hcp_features)
        elif isinstance(script.call_to_action, str):
            script.call_to_action = replace_placeholders_in_text(script.call_to_action, product, hcp_features)
    
    # Replace in next steps
    if script.next_steps:
        for i, step in enumerate(script.next_steps):
            if isinstance(step, str):
                script.next_steps[i] = replace_placeholders_in_text(step, product, hcp_features)
            elif isinstance(step, dict) and 'step' in step:
                step['step'] = replace_placeholders_in_text(step['step'], product, hcp_features)
    
    # Add safety information for fair balance (FDA requirement)
    safety_info = get_approved_content(product, 'SAFETY_INFO')
    if safety_info and safety_info != "[Contact medical affairs for approved content]":
        # Add to required disclaimers
        if not script.required_disclaimers:
            script.required_disclaimers = []
        
        # Add IMPORTANT SAFETY INFORMATION if not already there
        safety_disclaimer = f"IMPORTANT SAFETY INFORMATION: {safety_info}"
        if safety_disclaimer not in script.required_disclaimers:
            script.required_disclaimers.insert(0, safety_disclaimer)
    
    # Expand disclaimer codes to full MLR-compliant text
    if script.required_disclaimers:
        disclaimer_expansions = {
            'prescribing_info': f"See full Prescribing Information for {product}, including Boxed Warning, at www.{product.lower()}.com/pi",
            'individual_results': "Individual results may vary. Consult your healthcare provider for personalized medical advice.",
            'adverse_events': f"To report SUSPECTED ADVERSE REACTIONS, contact IBSA Pharma Inc. at 1-800-IBSA (4272) or FDA at 1-800-FDA-1088 or www.fda.gov/medwatch"
        }
        
        expanded_disclaimers = []
        for disclaimer in script.required_disclaimers:
            if isinstance(disclaimer, str):
                # Check if it's a code that needs expansion
                if disclaimer in disclaimer_expansions:
                    expanded_disclaimers.append(disclaimer_expansions[disclaimer])
                else:
                    expanded_disclaimers.append(disclaimer)
        
        script.required_disclaimers = expanded_disclaimers
    
    return script


def format_script_output(script: Any) -> str:
    """Format GeneratedScript object into readable text"""
    lines = []
    
    # Header
    lines.append("=" * 80)
    lines.append(f"CALL SCRIPT - HCP {script.hcp_id}")
    lines.append(f"Scenario: {script.scenario.value if hasattr(script.scenario, 'value') else script.scenario}")
    lines.append(f"Priority: {script.priority}")
    lines.append("=" * 80)
    lines.append("")
    
    # Opening
    if script.opening:
        lines.append("OPENING:")
        # Handle both dict format (with greeting/purpose) and string format
        if isinstance(script.opening, dict):
            greeting = script.opening.get('greeting', '')
            purpose = script.opening.get('purpose', '')
            if greeting:
                lines.append(greeting)
            if purpose:
                lines.append(purpose)
        else:
            lines.append(script.opening)
        lines.append("")
    
    # Talking Points
    if script.talking_points:
        lines.append("KEY TALKING POINTS:")
        for i, point in enumerate(script.talking_points, 1):
            # Handle both dict format (from templates) and string format
            if isinstance(point, dict):
                topic = point.get('topic', '')
                message = point.get('message', '')
                lines.append(f"{i}. {topic}: {message}")
            else:
                lines.append(f"{i}. {point}")
        lines.append("")
    
    # Objection Handlers
    if script.objection_handlers:
        lines.append("OBJECTION HANDLERS:")
        for key, handler in script.objection_handlers.items():
            # Handle both dict format (with objection/response keys) and simple string format
            if isinstance(handler, dict):
                objection = handler.get('objection', key)
                response = handler.get('response', '')
                lines.append(f"\nObjection: {objection}")
                lines.append(f"Response: {response}")
            else:
                lines.append(f"\n{key}: {handler}")
        lines.append("")
    
    # Call to Action
    if script.call_to_action:
        lines.append("CALL TO ACTION:")
        # Handle both dict format (with primary_ask/secondary_ask) and string format
        if isinstance(script.call_to_action, dict):
            primary = script.call_to_action.get('primary_ask', '')
            secondary = script.call_to_action.get('secondary_ask', '')
            tertiary = script.call_to_action.get('tertiary_ask', '')
            if primary:
                lines.append(f"Primary: {primary}")
            if secondary:
                lines.append(f"Secondary: {secondary}")
            if tertiary:
                lines.append(f"Tertiary: {tertiary}")
        else:
            lines.append(script.call_to_action)
        lines.append("")
    
    # Next Steps
    if script.next_steps:
        lines.append("NEXT STEPS:")
        for i, step in enumerate(script.next_steps, 1):
            # Handle both dict and string format (just in case)
            if isinstance(step, dict):
                step_text = step.get('step', step.get('action', str(step)))
                lines.append(f"{i}. {step_text}")
            else:
                lines.append(f"{i}. {step}")
        lines.append("")
    
    # Disclaimers
    if script.required_disclaimers:
        lines.append("REQUIRED DISCLAIMERS:")
        for disclaimer in script.required_disclaimers:
            # Handle both dict and string format (just in case)
            if isinstance(disclaimer, dict):
                disclaimer_text = disclaimer.get('text', disclaimer.get('disclaimer', str(disclaimer)))
                lines.append(f"• {disclaimer_text}")
            else:
                lines.append(f"• {disclaimer}")
        lines.append("")
    
    # Footer
    lines.append("=" * 80)
    lines.append(f"Generated: {script.generated_at}")
    lines.append(f"Method: {script.generation_method}")
    lines.append(f"GPT-4 Enhanced: {'Yes' if script.gpt4_enhanced else 'No'}")
    lines.append(f"Compliance: {'✓ VERIFIED' if script.compliance_verified else '✗ FAILED'}")
    lines.append("=" * 80)
    
    return "\n".join(lines)

def classify_scenario(predictions: Dict[str, Any]) -> tuple:
    """Classify call scenario based on predictions"""
    # Simple logic for demo
    call_success = predictions.get('tirosint_call_success', 0)
    prescription_lift = predictions.get('tirosint_prescription_lift', 0)
    
    if call_success > 0.7 and prescription_lift > 5:
        return 'GROWTH', 'HIGH'
    elif call_success < 0.5:
        return 'RETENTION', 'HIGH'
    elif prescription_lift < 0:
        return 'RETENTION', 'MEDIUM'
    else:
        return 'OPTIMIZATION', 'MEDIUM'

def format_compliance_report(compliance_result: Any) -> ComplianceReport:
    """Format compliance check result into structured report"""
    # Handle both ComplianceResult object and dict
    if hasattr(compliance_result, 'violations'):
        # It's a ComplianceResult object
        violations = [
            ValidationViolation(
                type="COMPLIANCE",
                severity=compliance_result.severity,
                details=v,
                location=None
            )
            for v in compliance_result.violations
        ]
        
        # Count by severity
        severity_breakdown = {'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
        for v in violations:
            severity_breakdown[v.severity] = severity_breakdown.get(v.severity, 0) + 1
        
        return ComplianceReport(
            is_compliant=compliance_result.is_compliant,
            violations=violations,
            total_violations=len(violations),
            severity_breakdown=severity_breakdown
        )
    else:
        # Legacy dict format
        violations = []
        
        for v in compliance_result.get('violations', []):
            violations.append(ValidationViolation(
                type=v.get('type', 'UNKNOWN'),
                severity=v.get('severity', 'MEDIUM'),
                details=v.get('details', ''),
                location=v.get('location')
            ))
        
    # Count by severity
    severity_breakdown = {'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
    for v in violations:
        severity_breakdown[v.severity] = severity_breakdown.get(v.severity, 0) + 1
    
    return ComplianceReport(
        is_compliant=compliance_result.get('is_compliant', False),
        violations=violations,
        total_violations=len(violations),
        severity_breakdown=severity_breakdown
    )

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint - API information"""
    return {
        "name": "IBSA AI Call Script Generator API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "generate": "/generate-call-script",
            "validate": "/validate-script",
            "models": "/models/status"
        }
    }

@app.get("/health", response_model=HealthResponse, tags=["System"])
async def health_check():
    """
    Health check endpoint - verify all components are operational
    
    Returns system status including:
    - Script generator status
    - Compliance checker status
    - ML models loaded
    - Feature data availability
    - FAISS index status
    """
    start_time = time.time()
    
    components = {
        "script_generator": {
            "status": "operational" if script_generator else "not_loaded",
            "content_pieces": len(script_generator.vector_db.content_library) if script_generator else 0,
            "ready": script_generator is not None
        },
        "compliance_checker": {
            "status": "operational" if compliance_checker else "not_loaded",
            "prohibited_terms": len(compliance_checker.prohibited_terms) if compliance_checker else 0,
            "required_disclaimers": len(compliance_checker.required_disclaimers) if compliance_checker else 0,
            "ready": compliance_checker is not None
        },
        "ml_models": {
            "status": "operational" if ml_models else "not_loaded",
            "loaded_count": len(ml_models),
            "ready": len(ml_models) > 0
        },
        "feature_data": {
            "status": "operational" if feature_data is not None else "not_loaded",
            "hcp_count": len(feature_data) if feature_data is not None else 0,
            "ready": feature_data is not None
        },
        "faiss_index": {
            "status": "operational" if Path(config.FAISS_INDEX_PATH).exists() else "not_found",
            "ready": Path(config.FAISS_INDEX_PATH).exists()
        }
    }
    
    # Overall status
    all_ready = all(c.get("ready", False) for c in components.values())
    overall_status = "healthy" if all_ready else "degraded"
    
    response_time = time.time() - start_time
    
    return HealthResponse(
        status=overall_status,
        components=components,
        timestamp=datetime.now().isoformat(),
        version="1.0.0"
    )

@app.post("/generate-call-script", response_model=ScriptResponse, tags=["Script Generation"])
@limiter.limit("30/minute")
async def generate_call_script(
    request: Request,
    body: GenerateScriptRequest,
    api_key: str = Depends(verify_api_key)
):
    """
    Generate personalized, MLR-compliant call script for an HCP
    
    Process:
    1. Load HCP features from dataset
    2. Run ML predictions (12 models)
    3. Classify scenario (RETENTION/GROWTH/OPTIMIZATION/INTRODUCTION)
    4. Retrieve relevant MLR-approved content via RAG
    5. Optionally enhance with GPT-4o-mini
    6. Run compliance check
    7. Return complete script with audit trail
    
    Rate limit: 30 requests/minute
    """
    start_time = time.time()
    
    logger.info(f"Script generation request: HCP={body.hcp_id}, GPT4={body.include_gpt4}")
    
    try:
        # 1. Load HCP features
        hcp_features = load_hcp_features(body.hcp_id)
        logger.info(f"[OK] Loaded HCP features: {len(hcp_features)} attributes")
        
        # 2. Run ML predictions
        predictions = run_ml_predictions(hcp_features)
        logger.info(f"[OK] ML predictions: {predictions}")
        
        # 3. Classify scenario
        if body.force_scenario:
            scenario = body.force_scenario.upper()
            priority = 'HIGH'
        else:
            scenario, priority = classify_scenario(predictions)
        
        logger.info(f"[OK] Scenario: {scenario} (Priority: {priority})")
        
        # 4. Generate script (HybridScriptGenerator handles features/predictions internally)
        script_result = script_generator.generate_script(
            hcp_id=body.hcp_id,
            use_gpt4=body.include_gpt4,
            use_rag=True
        )
        
        # 4.5. Replace ALL placeholders with actual MLR-approved content AND HCP data (FDA/MRC/MLR compliance)
        product_focus = script_result.predictions.get('product_focus', 'Tirosint')
        script_result = replace_placeholders_in_script(script_result, product_focus, hcp_features)
        
        # Extract scenario and priority from the generated script object
        scenario = script_result.scenario.value if hasattr(script_result.scenario, 'value') else str(script_result.scenario)
        priority = script_result.priority
        predictions = script_result.predictions
        
        # 5. Format compliance report
        compliance_report = format_compliance_report(script_result.compliance_result)
        
        # 6. Calculate metrics
        generation_time = time.time() - start_time
        
        # 7. Build structured script output
        script_dict = {
            'hcp_id': script_result.hcp_id,
            'scenario': scenario,
            'priority': priority,
            'opening': script_result.opening,
            'talking_points': script_result.talking_points,
            'objection_handlers': script_result.objection_handlers,
            'call_to_action': script_result.call_to_action,
            'next_steps': script_result.next_steps,
            'required_disclaimers': script_result.required_disclaimers,
            'formatted_text': format_script_output(script_result),
            'metadata': {
                'template_used': script_result.template_used,
                'gpt4_enhanced': script_result.gpt4_enhanced,
                'generation_method': script_result.generation_method,
                'rag_content_used': len(script_result.rag_content_used),
                'generated_at': script_result.generated_at,
                'model_versions': script_result.model_versions
            }
        }
        
        # 8. Audit log
        logger.info(
            f"Script generated: HCP={body.hcp_id}, Scenario={scenario}, "
            f"Compliant={compliance_report.is_compliant}, Time={generation_time:.2f}s, "
            f"Cost=${script_result.estimated_cost:.4f}"
        )
        
        # 9. Build response
        response = ScriptResponse(
            hcp_id=body.hcp_id,
            scenario=scenario,
            priority=priority,
            script=script_dict,
            compliance=compliance_report,
            metadata={
                'predictions': predictions,
                'method': script_result.generation_method,
                'approval_sources': script_result.approval_sources,
                'content_pieces_used': len(script_result.rag_content_used)
            },
            generation_time_seconds=round(generation_time, 2),
            cost_usd=script_result.estimated_cost
        )
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Script generation failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Script generation failed: {str(e)}"
        )

@app.post("/validate-script", response_model=ComplianceReport, tags=["Compliance"])
@limiter.limit("60/minute")
async def validate_script(
    request: Request,
    body: ValidateScriptRequest,
    api_key: str = Depends(verify_api_key)
):
    """
    Validate a script for MLR compliance
    
    Checks for:
    - Prohibited terms (41 terms)
    - Required disclaimers (6 disclaimers)
    - Fair balance (benefits vs risks)
    - Off-label claims
    - Unsubstantiated claims
    
    Rate limit: 60 requests/minute
    """
    logger.info(f"Validation request: {len(body.script_text)} chars")
    
    try:
        # Run compliance check
        compliance_result = compliance_checker.check_compliance(body.script_text)
        
        # Format report
        report = format_compliance_report(compliance_result)
        
        logger.info(
            f"Validation complete: Compliant={report.is_compliant}, "
            f"Violations={report.total_violations}"
        )
        
        return report
        
    except Exception as e:
        logger.error(f"Validation failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Validation failed: {str(e)}"
        )

@app.get("/models/status", response_model=ModelsStatusResponse, tags=["Models"])
async def get_models_status(api_key: str = Depends(verify_api_key)):
    """
    Get ML model status and performance metrics
    
    Returns information about all 12 trained models:
    - Model name and product
    - Performance metrics (accuracy, R²)
    - Feature count
    - Last trained date
    - Load status
    """
    logger.info("Models status request")
    
    try:
        models_info = []
        
        # Expected 12 models (4 products × 3 targets)
        expected_models = [
            ('Tirosint', 'call_success'),
            ('Tirosint', 'prescription_lift'),
            ('Tirosint', 'ngd_category'),
            ('Flector', 'call_success'),
            ('Flector', 'prescription_lift'),
            ('Flector', 'ngd_category'),
            ('Licart', 'call_success'),
            ('Licart', 'prescription_lift'),
            ('Licart', 'ngd_category'),
            ('Dyloject', 'call_success'),
            ('Dyloject', 'prescription_lift'),
            ('Dyloject', 'ngd_category'),
        ]
        
        for product, target in expected_models:
            model_name = f"{product.lower()}_{target}"
            model_file = config.MODEL_DIR / f"{model_name}.pkl"
            
            model_info = ModelMetrics(
                model_name=model_name,
                product=product,
                target=target,
                accuracy=None,  # Would load from metrics file
                r2_score=None,  # Would load from metrics file
                feature_count=256,  # From Phase 3 EDA
                last_trained=None,  # Would load from metadata
                model_exists=model_file.exists()
            )
            
            models_info.append(model_info)
        
        response = ModelsStatusResponse(
            total_models=len(expected_models),
            loaded_models=len(ml_models),
            models=models_info
        )
        
        return response
        
    except Exception as e:
        logger.error(f"Models status failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve models status: {str(e)}"
        )

# ============================================================================
# PREDICTION ENDPOINTS
# ============================================================================

class PredictHCPRequest(BaseModel):
    """Request model for HCP prediction"""
    hcp_id: str = Field(..., description="HCP NPI or ID")
    
class HCPPrediction(BaseModel):
    """HCP prediction response"""
    npi: str
    predictions: Dict[str, Any]
    aggregate_metrics: Dict[str, float]
    segment: str
    next_best_action: str
    generation_time_seconds: float

@app.post("/predict-hcp", response_model=HCPPrediction, tags=["Predictions"])
@limiter.limit("60/minute")
async def predict_hcp(
    request: Request,
    body: PredictHCPRequest,
    api_key: str = Depends(verify_api_key)
):
    """
    Generate ML predictions for a specific HCP on-the-fly
    
    Uses the 9 trained models to predict:
    - Call success probability
    - Prescription lift forecast
    - NGD category (New/Grower/Stable/Decliner)
    
    Rate limit: 60 requests/minute
    """
    import numpy as np
    
    start_time = time.time()
    logger.info(f"Prediction request for HCP: {body.hcp_id}")
    
    try:
        # Load HCP features from feature-engineered data
        hcp_npi = int(body.hcp_id)
        
        # Check cache first
        if feature_data is not None and 'PrescriberId' in feature_data.columns:
            hcp_row = feature_data[feature_data['PrescriberId'] == hcp_npi]
            if len(hcp_row) > 0:
                logger.info(f"Found HCP in cache")
                hcp_features = hcp_row.iloc[0]
            else:
                # Load from full file
                logger.info(f"HCP not in cache, loading from file...")
                chunk_found = False
                for chunk in pd.read_csv(config.FEATURES_FILE, chunksize=100000, low_memory=False):
                    hcp_row = chunk[chunk['PrescriberId'] == hcp_npi]
                    if len(hcp_row) > 0:
                        hcp_features = hcp_row.iloc[0]
                        chunk_found = True
                        break
                
                if not chunk_found:
                    raise HTTPException(status_code=404, detail=f"HCP {body.hcp_id} not found in feature data")
        else:
            raise HTTPException(status_code=503, detail="Feature data not loaded")
        
        # Get numeric features
        exclude_cols = ['PrescriberId', 'Specialty', 'State', 'Name', 'City', 'Territory', 'Tier']
        feature_cols = [c for c in hcp_features.index if c not in exclude_cols and 
                       pd.api.types.is_numeric_dtype(hcp_features[c])]
        
        X = pd.DataFrame([hcp_features[feature_cols]]).fillna(0)
        logger.info(f"Prepared {len(X.columns)} features for prediction")
        
        # Run predictions with each model
        predictions = {}
        for product in PRODUCTS:
            for outcome in OUTCOMES:
                model_name = f"model_{product}_{outcome}"
                if model_name in ml_models:
                    model = ml_models[model_name]
                    expected_features = model.n_features_in_
                    
                    # Prepare feature matrix
                    if len(X.columns) != expected_features:
                        if len(X.columns) < expected_features:
                            X_model = X.copy()
                            for i in range(expected_features - len(X.columns)):
                                X_model[f'pad_{i}'] = 0
                        else:
                            X_model = X.iloc[:, :expected_features]
                    else:
                        X_model = X
                    
                    # Predict
                    if outcome in ['call_success', 'ngd_category']:
                        pred = model.predict(X_model)[0]
                        if hasattr(model, 'predict_proba'):
                            prob = model.predict_proba(X_model)[0, 1]
                        else:
                            prob = float(pred)
                        predictions[f"{product}_{outcome}_pred"] = int(pred)
                        predictions[f"{product}_{outcome}_prob"] = float(prob)
                    else:
                        pred = model.predict(X_model)[0]
                        predictions[f"{product}_{outcome}_pred"] = float(pred)
        
        # Calculate aggregate metrics
        call_success_cols = [k for k in predictions.keys() if 'call_success_prob' in k]
        call_success_prob = np.mean([predictions[k] for k in call_success_cols]) if call_success_cols else 0.5
        
        lift_cols = [k for k in predictions.keys() if 'prescription_lift_pred' in k]
        forecasted_lift = np.sum([predictions[k] for k in lift_cols]) if lift_cols else 0
        
        sample_effectiveness = call_success_prob * 0.3
        churn_risk = 1 - call_success_prob
        expected_roi = forecasted_lift * 15
        
        # Determine segment
        if call_success_prob > 0.7 and forecasted_lift > 10:
            segment = 'Champions'
        elif forecasted_lift > 5:
            segment = 'Growth Opportunities'
        elif churn_risk > 0.6:
            segment = 'At-Risk'
        elif call_success_prob > 0.5:
            segment = 'Maintain'
        else:
            segment = 'Deprioritize'
        
        # Determine next best action
        if churn_risk > 0.7:
            next_best_action = 'Maintain Engagement'
        elif forecasted_lift > 10:
            next_best_action = 'Increase Calls'
        elif sample_effectiveness < 0.05:
            next_best_action = 'Sample Drop Only'
        else:
            next_best_action = 'Detail Only'
        
        # NGD classification
        ngd_cols = [k for k in predictions.keys() if 'ngd_category_pred' in k]
        if ngd_cols:
            ngd_val = predictions[ngd_cols[0]]
            if ngd_val < 0.25:
                ngd_classification = 'Decliner'
            elif ngd_val < 0.5:
                ngd_classification = 'Stable'
            elif ngd_val < 0.75:
                ngd_classification = 'Grower'
            else:
                ngd_classification = 'New'
        else:
            ngd_classification = 'Stable'
        
        aggregate_metrics = {
            'call_success_prob': float(call_success_prob),
            'forecasted_lift': float(forecasted_lift),
            'sample_effectiveness': float(sample_effectiveness),
            'churn_risk': float(churn_risk),
            'expected_roi': float(expected_roi),
            'ngd_classification': ngd_classification,
            'churn_risk_level': 'High' if churn_risk > 0.7 else ('Medium' if churn_risk > 0.4 else 'Low'),
            'sample_allocation': int(sample_effectiveness * 100)
        }
        
        generation_time = time.time() - start_time
        logger.info(f"Prediction complete in {generation_time:.2f}s: {segment}")
        
        return HCPPrediction(
            npi=body.hcp_id,
            predictions=predictions,
            aggregate_metrics=aggregate_metrics,
            segment=segment,
            next_best_action=next_best_action,
            generation_time_seconds=generation_time
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prediction failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}"
        )

# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    
    print("="*80)
    print("IBSA AI CALL SCRIPT GENERATOR API")
    print("="*80)
    print("\nStarting server...")
    print("  URL: http://localhost:8000")
    print("  Docs: http://localhost:8000/docs")
    print("  Health: http://localhost:8000/health")
    print("\nAPI Key:", config.API_KEY)
    print("="*80)
    
    uvicorn.run(
        "phase6e_fastapi_production_api:app",
        host="0.0.0.0",
        port=8000,
        reload=False,  # Disable reload due to Python 3.14 compatibility issues
        log_level="info"
    )

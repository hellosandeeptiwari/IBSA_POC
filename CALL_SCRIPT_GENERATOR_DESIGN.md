# CALL SCRIPT GENERATOR - AI-Powered Territory Sales Assistant
**Model 13: From Predictions to Action**

## 🎯 **Vision**
Transform predictive insights into **actionable call scripts** that Territory Sales reps can use immediately. Not just "Call this HCP" but "Say THIS to this HCP".

---

## 📊 **Architecture: 3-Tier Approach**

### **Tier 1: Predictive Models (Models 1-12)**
- **Input:** HCP features (256 selected features)
- **Output:** Predictions for call_success, prescription_lift, NGD category
- **Purpose:** Understand HCP behavior and needs

### **Tier 2: Scenario Classification (Rule Engine)**
- **Input:** Predictions + HCP profile
- **Output:** Scenario label (Retention, Growth, Optimization, Introduction)
- **Purpose:** Identify WHY this HCP should be called

### **Tier 3: Script Generation (Model 13)**
- **Input:** Scenario + HCP context
- **Output:** Personalized talking points, objection handlers, next steps
- **Purpose:** Tell rep WHAT to say

---

## 🔥 **Call Script Generator - Three Approaches**

### **Approach 1: Template-Based (Recommended for MVP)**
**Pros:**
- ✅ Fast (< 100ms response time)
- ✅ Fully explainable (no black box)
- ✅ No training data needed
- ✅ Easy to update/maintain
- ✅ Regulatory compliant (no AI hallucination risk)

**Cons:**
- ❌ Less natural language
- ❌ Fixed template structure
- ❌ Limited personalization

**Implementation:**
```python
def generate_call_script(hcp_profile, predictions, scenario):
    """
    Template-based script generation
    """
    template = SCRIPT_TEMPLATES[scenario]  # e.g., 'retention', 'growth'
    
    # Fill template slots with HCP data
    script = template.format(
        name=hcp_profile['name'],
        specialty=hcp_profile['specialty'],
        current_trx=hcp_profile['trx_c4wk'],
        ibsa_share=hcp_profile['ibsa_share'],
        share_trend=calculate_trend(hcp_profile),
        competitive_threat=identify_threat(hcp_profile),
        sample_roi=hcp_profile['sample_roi'],
        # ... more context
    )
    
    return script
```

**Example Templates:**

#### **Retention Script (At-Risk HCP)**
```
Opening:
"Hi Dr. {name}, I wanted to touch base because I noticed your Tirosint 
prescriptions have {trend_description} over the past quarter."

Talking Points:
1. "Your current {current_trx} TRx represents {ibsa_share}% of your thyroid 
   prescriptions - we value this partnership."

2. "I see {competitive_threat} may be approaching your practice. Let's discuss 
   how Tirosint's unique formulation addresses patient needs better."

3. "Based on your patient population ({payer_mix_description}), I have some 
   clinical data that might be helpful."

Objection Handler:
IF objection == "price concerns":
   "Let me share our patient assistance program and coverage data for your 
    top payers ({top_payers})."

Next Steps:
- Schedule follow-up in 2 weeks
- Send clinical studies via email
- Arrange lunch-and-learn if interested
```

#### **Growth Script (Opportunity HCP)**
```
Opening:
"Hi Dr. {name}, I'm following up on our previous discussions about Tirosint. 
I noticed you're prescribing {current_trx} TRx, and I believe we can help 
more of your patients."

Talking Points:
1. "You're currently at {ibsa_share}% IBSA share - there's an opportunity to 
   expand to patients who might benefit from Tirosint's superior absorption."

2. "I have samples available for {sample_recommendation} patients. Would you 
   like to try Tirosint Sol for patients with swallowing difficulties?"

3. "Specialists in your area average {territory_avg_trx} TRx - I'd love to 
   help you reach that level with the right patients."

Call to Action:
"Can we identify 3-5 patients this month who might be good candidates?"

Next Steps:
- Drop off samples next week
- Schedule case discussion
- Share patient selection criteria
```

#### **Optimization Script (Sample Black Hole)**
```
Opening:
"Hi Dr. {name}, I wanted to discuss our sampling strategy. You've received 
{total_samples} samples, and I'd like to ensure we're targeting the right 
patients for the best outcomes."

Talking Points:
1. "Our data shows {sample_roi}% conversion rate. Let's work together to 
   improve patient selection for better results."

2. "The ideal Tirosint patient profile is: {ideal_patient_criteria}. 
   Does this match who you're currently sampling?"

3. "I'd like to redirect samples to where they'll have the most impact. 
   Can we discuss which patients are responding best?"

Goal:
Improve sample ROI from {current_roi}% to {target_roi}% over next quarter.

Next Steps:
- Review patient selection criteria together
- Adjust sample allocation
- Follow up on sample patients in 4 weeks
```

---

### **Approach 2: Fine-Tuned Small LLM (Future Enhancement)**
**Pros:**
- ✅ Natural, conversational language
- ✅ Can learn from historical call notes
- ✅ More personalized and context-aware
- ✅ Can handle unexpected scenarios

**Cons:**
- ❌ Requires training data (call notes + outcomes)
- ❌ Slower (1-2 seconds response time)
- ❌ Harder to explain (less transparent)
- ❌ Regulatory risk (AI hallucination)
- ❌ Requires GPU for inference

**Recommended Model:**
- **Phi-3-mini (3.8B params)** - Microsoft's efficient small LLM
- Or **GPT-2-medium (355M params)** - Smaller, faster

**Training Data:**
```python
# Format for fine-tuning
{
    "prompt": "Generate call script for: [HCP Profile] Scenario: Retention",
    "completion": "[Generated talking points from template or historical data]"
}
```

**Implementation:**
```python
from transformers import AutoModelForCausalLM, AutoTokenizer

# Load fine-tuned model
model = AutoModelForCausalLM.from_pretrained("ibsa-call-script-generator")
tokenizer = AutoTokenizer.from_pretrained("ibsa-call-script-generator")

def generate_call_script_llm(hcp_profile, predictions, scenario):
    prompt = f"""
    Generate a professional call script for the following HCP:
    
    Name: Dr. {hcp_profile['name']}
    Specialty: {hcp_profile['specialty']}
    Current TRx: {hcp_profile['trx_c4wk']}
    IBSA Share: {hcp_profile['ibsa_share']}%
    Scenario: {scenario}
    
    Include:
    1. Opening statement
    2. 3-5 data-driven talking points
    3. Call to action
    4. Next steps
    
    Script:
    """
    
    inputs = tokenizer(prompt, return_tensors="pt")
    outputs = model.generate(**inputs, max_length=500, temperature=0.7)
    script = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    return script
```

---

### **Approach 3: RAG (Retrieval-Augmented Generation)**
**Pros:**
- ✅ Combines template reliability with LLM flexibility
- ✅ Uses historical success patterns
- ✅ Can cite similar HCP cases
- ✅ More trustworthy (grounded in data)

**Cons:**
- ❌ Most complex to implement
- ❌ Requires vector database
- ❌ Slower than template-only

**Implementation:**
```python
from sentence_transformers import SentenceTransformer
import faiss

# Index historical successful call scripts
embeddings_model = SentenceTransformer('all-MiniLM-L6-v2')
vector_db = faiss.IndexFlatL2(384)  # 384 = embedding dimension

def generate_call_script_rag(hcp_profile, predictions, scenario):
    # 1. Embed HCP profile
    profile_embedding = embeddings_model.encode([
        f"{hcp_profile['specialty']} {hcp_profile['trx_c4wk']} {scenario}"
    ])
    
    # 2. Retrieve similar successful calls
    D, I = vector_db.search(profile_embedding, k=3)  # Top 3 similar
    similar_scripts = [historical_scripts[i] for i in I[0]]
    
    # 3. Generate script using template + similar examples
    script = template_with_examples(hcp_profile, similar_scripts, scenario)
    
    return script
```

---

## 📋 **Recommended Implementation Plan**

### **Phase 1: MVP (Template-Based) - Week 1-2**
1. ✅ Create 4 scenario templates (Retention, Growth, Optimization, Introduction)
2. ✅ Build slot-filling engine with HCP data
3. ✅ Create rule-based scenario classifier
4. ✅ Test with 100 sample HCPs
5. ✅ Deploy as FastAPI endpoint

**Deliverable:** Working call script generator (100ms response time)

### **Phase 2: Enhancement (Add LLM) - Week 3-4**
1. Collect historical call notes from field team
2. Fine-tune Phi-3-mini on IBSA call data
3. A/B test: Template vs LLM-generated scripts
4. Measure: Call success rate, rep satisfaction
5. Iterate based on feedback

**Deliverable:** Hybrid system (template + LLM fallback)

### **Phase 3: Optimization (RAG) - Week 5-6**
1. Build vector database of successful call scripts
2. Implement retrieval system
3. Test RAG-enhanced generation
4. Production deployment
5. Monitoring and continuous improvement

**Deliverable:** Production-ready generative AI system

---

## 🎯 **Script Output Format (JSON)**

```json
{
  "hcp_id": "12345",
  "hcp_name": "Dr. John Smith",
  "specialty": "Endocrinology",
  "scenario": "retention",
  "call_objective": "Retain high-value HCP with declining share",
  "priority": "HIGH",
  "predictions": {
    "call_success_probability": 0.78,
    "prescription_lift_expected": 12.5,
    "ngd_category": "GROWER"
  },
  "script": {
    "opening": "Hi Dr. Smith, I wanted to touch base because I noticed your Tirosint prescriptions decreased 10% this quarter from 45 to 40 TRx.",
    "talking_points": [
      {
        "point": "Your 85% IBSA share represents strong partnership - we value this relationship.",
        "data_source": "ibsa_share from PrescriberOverview"
      },
      {
        "point": "I see competitive activity may be increasing. Let's discuss how Tirosint's gel cap formulation provides superior consistency vs competitors.",
        "data_source": "competitive_intelligence_analysis"
      },
      {
        "point": "Based on your 70% Medicare patient mix, I have coverage updates that might help with prior authorizations.",
        "data_source": "payer_intelligence_features"
      },
      {
        "point": "Would you like samples for 5-10 patients to reinforce Tirosint's benefits?",
        "data_source": "sample_roi_analysis"
      }
    ],
    "objection_handlers": {
      "price_concerns": "Let me share our patient assistance program and your current coverage rates (92% approval for Medicare).",
      "competitor_advantages": "Happy to provide head-to-head clinical data showing Tirosint's superior absorption and consistency.",
      "no_time": "I understand - can I send you a 1-page summary and schedule a brief 10-minute call next week?"
    },
    "call_to_action": "Can we schedule a lunch-and-learn next month to review Tirosint updates with your staff?",
    "next_steps": [
      "Drop off samples this week",
      "Email clinical studies on absorption",
      "Follow up in 2 weeks to check sample patient progress",
      "Schedule lunch-and-learn for next month"
    ],
    "success_metrics": {
      "target_trx_next_quarter": 50,
      "target_share_improvement": "+5%",
      "sample_allocation": 20
    }
  },
  "generated_at": "2025-10-27T11:15:00Z",
  "model_version": "1.0-template",
  "confidence_score": 0.92
}
```

---

## 🔧 **Technical Implementation**

### **File Structure:**
```
phase6b_call_script_templates.py      # Template library
phase6c_call_script_generator_api.py  # FastAPI endpoint
phase6d_scenario_classifier.py        # Rule engine for scenario detection
phase6e_slot_filler.py                # Template slot filling logic
```

### **API Endpoint:**
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class HCPScriptRequest(BaseModel):
    hcp_id: str
    include_predictions: bool = True
    script_style: str = "professional"  # or "casual", "technical"

@app.post("/generate-call-script")
async def generate_call_script(request: HCPScriptRequest):
    # 1. Load HCP features
    hcp_profile = load_hcp_profile(request.hcp_id)
    
    # 2. Run predictive models (1-12)
    predictions = run_predictive_models(hcp_profile)
    
    # 3. Classify scenario
    scenario = classify_scenario(hcp_profile, predictions)
    
    # 4. Generate script
    script = generate_script_from_template(hcp_profile, predictions, scenario)
    
    return {
        "status": "success",
        "script": script,
        "metadata": {
            "hcp_id": request.hcp_id,
            "scenario": scenario,
            "generated_at": datetime.now().isoformat()
        }
    }
```

---

## 📊 **Success Metrics**

### **For Script Quality:**
- Rep satisfaction score (1-5 scale)
- Script usage rate (% of reps using generated scripts)
- Edit rate (% of scripts edited before use)
- Time saved per call (vs manual preparation)

### **For Business Impact:**
- Call success rate (generated script vs manual)
- Prescription lift (before vs after using scripts)
- Rep productivity (calls per day with scripts)
- Revenue impact ($ value of influenced prescriptions)

**Target:** 80%+ rep satisfaction, 30% time savings, 15% call success improvement

---

## 🚀 **Integration with Existing Pipeline**

```
Phase 3 (EDA) → Phase 4B (Features) → Phase 4C (Integration) → 
Phase 5 (Targets) → Phase 6 (Models 1-12) → Phase 6B-E (Model 13) → 
UI Integration
```

**UI Workflow:**
1. Rep searches for HCP in pre-call planning UI
2. Clicks "Generate Call Script" button
3. API calls Model 13 (< 2 seconds)
4. Script displayed in UI with editable sections
5. Rep customizes if needed
6. Prints or saves to mobile device
7. Makes call using script as guide
8. Logs call outcome (feeds back to model training)

---

## 🎯 **Next Steps**

**Immediate (This Week):**
1. Create Phase 5 with target engineering
2. Build Phase 6 with 12 predictive models
3. Design script templates for 4 scenarios

**Short-Term (Next 2 Weeks):**
4. Implement template-based generator (Phase 6B-E)
5. Create FastAPI endpoint
6. Integrate with UI

**Long-Term (Month 2):**
7. Collect call outcome data
8. Fine-tune LLM on IBSA call scripts
9. Implement RAG for better personalization
10. A/B test and optimize

---

## ✅ **Decision Point**

**Choose approach for MVP:**

**Option A: Template-Only (Recommended)**
- Fastest to deploy (1 week)
- No AI risk, fully compliant
- Good enough for 80% of scenarios

**Option B: Template + LLM Hybrid**
- Best of both worlds
- 2-3 weeks to deploy
- More flexible but requires training data

**Option C: Full LLM + RAG**
- Most advanced
- 4-6 weeks to deploy
- Requires significant ML infrastructure

**Recommendation:** Start with **Option A** (template), measure adoption, then enhance with **Option B** if needed.

---

**Want me to start building Phase 5 (Target Engineering) now?** 🚀

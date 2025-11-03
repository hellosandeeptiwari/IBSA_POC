#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PHASE 6C: CALL SCRIPT TEMPLATES
================================
Scenario-based call script templates for territory sales reps

BUSINESS INTELLIGENCE FROM EDA:
-------------------------------
- 660 at-risk HCPs (high volume + declining share) → RETENTION scenario
- 264 opportunity HCPs (high volume + low IBSA share) → GROWTH scenario  
- 48.5% sample black holes (ROI < 5%) → OPTIMIZATION scenario
- New HCPs / first calls → INTRODUCTION scenario

TEMPLATE FEATURES:
-----------------
- Dynamic slot filling: {hcp_name}, {specialty}, {current_trx}, etc.
- Compliance-approved content only (from Phase 6B library)
- Required disclaimers automatically included
- Structured format: Opening, Talking Points, Objection Handlers, Call-to-Action, Next Steps
- Product-specific variations (Tirosint, Flector, Licart)

TEMPLATE STRUCTURE:
------------------
1. Opening: Personalized greeting + visit purpose
2. Key Talking Points: 3-5 MLR-approved messages
3. Objection Handlers: Pre-approved responses to common objections
4. Call-to-Action: Specific ask (trial, samples, prescription)
5. Next Steps: Follow-up plan
6. Required Disclaimers: Compliance statements

OUTPUT:
-------
- call_script_templates.json (4 scenario templates)
- template_usage_guide.json (how to use templates)
- sample_scripts.json (example filled scripts)
"""

import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any
from enum import Enum

# Directories
COMPLIANCE_DIR = Path(r'c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\compliance')
OUTPUT_DIR = Path(r'c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\call_scripts')
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


class ScenarioType(Enum):
    """Call scenario types based on HCP intelligence"""
    RETENTION = "retention"  # At-risk HCPs (660 identified)
    GROWTH = "growth"  # Opportunity HCPs (264 identified)
    OPTIMIZATION = "optimization"  # Sample black holes (48.5%)
    INTRODUCTION = "introduction"  # New HCPs / first calls


class CallScriptTemplateEngine:
    """
    Generate scenario-based call script templates
    
    Features:
    - 4 scenario templates based on business intelligence
    - Dynamic slot filling
    - Compliance-approved content integration
    - Automatic disclaimer inclusion
    """
    
    def __init__(self):
        self.output_dir = OUTPUT_DIR
        self.templates = {}
        self.approved_content = {}
        self.required_disclaimers = {}
        
        # Load compliance library
        self._load_compliance_library()
    
    def _load_compliance_library(self):
        """Load approved content and disclaimers from Phase 6B"""
        # Load approved content
        content_file = COMPLIANCE_DIR / 'compliance_approved_content.json'
        if content_file.exists():
            with open(content_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.approved_content = data
                print(f"✓ Loaded {data['total_content']} approved content pieces")
        
        # Load required disclaimers
        disclaimers_file = COMPLIANCE_DIR / 'required_disclaimers.json'
        if disclaimers_file.exists():
            with open(disclaimers_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.required_disclaimers = data['disclaimers']
                print(f"✓ Loaded {len(self.required_disclaimers)} required disclaimers")
    
    def create_retention_template(self) -> Dict[str, Any]:
        """
        RETENTION TEMPLATE
        
        Target: 660 at-risk HCPs identified in EDA
        Goal: Address declining IBSA share, prevent churn
        Strategy: Data-driven discussion, competitive insights, value reinforcement
        """
        template = {
            "scenario": ScenarioType.RETENTION.value,
            "target_segment": "At-risk HCPs (high volume + declining IBSA share)",
            "identified_count": 660,
            "goal": "Prevent churn and regain market share",
            "priority": "HIGH",
            
            "dynamic_slots": [
                "{hcp_name}",
                "{specialty}",
                "{current_trx}",
                "{trx_decline_pct}",
                "{ibsa_share}",
                "{competitive_threat}",
                "{product_focus}"
            ],
            
            "script_structure": {
                "opening": {
                    "greeting": "Good {time_of_day}, Dr. {hcp_name}. Thank you for taking the time to meet with me today.",
                    "purpose": "I wanted to discuss {product_focus} and understand how we can better support your practice. I noticed your {product_focus} prescriptions have declined by approximately {trx_decline_pct}% recently, and I'd like to learn more about your current treatment approach.",
                    "tone": "Professional, data-driven, consultative"
                },
                
                "key_talking_points": [
                    {
                        "point_id": 1,
                        "topic": "Acknowledge Change & Seek Understanding",
                        "message": "I see that you've been prescribing {competitive_threat} more frequently. Could you share what's driving this change? Understanding your perspective helps me ensure we're addressing your patients' needs.",
                        "approved_content_refs": []
                    },
                    {
                        "point_id": 2,
                        "topic": "Reinforce Value Proposition",
                        "message": "Based on your specialty in {specialty}, {product_focus} may offer specific benefits for certain patient populations. [INSERT PRODUCT-SPECIFIC APPROVED MESSAGING FROM LIBRARY]",
                        "approved_content_refs": ["TIR-MSG-001", "TIR-MSG-002", "FLE-MSG-001", "LIC-MSG-001"]
                    },
                    {
                        "point_id": 3,
                        "topic": "Clinical Evidence",
                        "message": "Recent studies have demonstrated [INSERT CLINICAL CLAIMS FROM LIBRARY]. This may be relevant for patients who are not optimally controlled on current therapy.",
                        "approved_content_refs": ["TIR-CLI-001", "TIR-CLI-002", "FLE-CLI-001", "LIC-CLI-001"]
                    },
                    {
                        "point_id": 4,
                        "topic": "Address Competitive Positioning",
                        "message": "I understand {competitive_threat} may have certain advantages. However, {product_focus} offers [UNIQUE DIFFERENTIATORS]. For patients with [SPECIFIC NEEDS], this could make a meaningful difference.",
                        "approved_content_refs": []
                    }
                ],
                
                "objection_handlers": {
                    "price_objection": {
                        "objection": "Your product is more expensive than generics/competitors",
                        "response": "[USE APPROVED OBJECTION HANDLER: TIR-OBJ-001 or GEN-OBJ-001]",
                        "approved_content_refs": ["TIR-OBJ-001", "GEN-OBJ-001"]
                    },
                    "efficacy_question": {
                        "objection": "I'm not seeing better results with your product",
                        "response": "I appreciate that feedback. Could you tell me more about the patient population you're treating? [PRODUCT] may be particularly beneficial for patients with [SPECIFIC CHARACTERISTICS]. Let's discuss whether there might be select patients where [PRODUCT] could be a good fit.",
                        "approved_content_refs": ["TIR-CLI-001", "TIR-CLI-002"]
                    },
                    "satisfied_with_current": {
                        "objection": "I'm satisfied with current therapy options",
                        "response": "That's great to hear your patients are doing well. I'm not suggesting changing all patients, but rather keeping [PRODUCT] as an option for those who may not be optimally controlled or have specific needs. Would you be open to considering it for select cases?",
                        "approved_content_refs": []
                    }
                },
                
                "call_to_action": {
                    "primary_ask": "Would you be willing to try {product_focus} for 3-5 patients who might benefit from [SPECIFIC BENEFIT]?",
                    "secondary_ask": "Can I provide you with samples to have available for appropriate patients?",
                    "tertiary_ask": "May I schedule a follow-up call in 30 days to discuss your experience?"
                },
                
                "next_steps": [
                    "Leave product samples and dosing information",
                    "Send clinical study reprints via email",
                    "Schedule follow-up call/visit in 30 days",
                    "Provide direct contact for questions",
                    "Monitor TRx data for changes"
                ],
                
                "required_disclaimers": [
                    "prescribing_info",
                    "individual_results",
                    "adverse_events"
                ]
            },
            
            "success_metrics": {
                "primary": "Halt TRx decline (stop negative trend)",
                "secondary": "Increase sample utilization by 20%",
                "tertiary": "Schedule follow-up meeting within 30 days"
            }
        }
        
        return template
    
    def create_growth_template(self) -> Dict[str, Any]:
        """
        GROWTH TEMPLATE
        
        Target: 264 opportunity HCPs identified in EDA
        Goal: Expand IBSA share in high-volume prescribers
        Strategy: Education, samples, trial-based approach
        """
        template = {
            "scenario": ScenarioType.GROWTH.value,
            "target_segment": "Opportunity HCPs (high volume + low IBSA share ~12.9%)",
            "identified_count": 264,
            "goal": "Increase IBSA market share from ~12.9% to 25%+",
            "priority": "HIGH",
            
            "dynamic_slots": [
                "{hcp_name}",
                "{specialty}",
                "{total_market_trx}",
                "{current_ibsa_share}",
                "{target_ibsa_share}",
                "{product_focus}",
                "{patient_volume}"
            ],
            
            "script_structure": {
                "opening": {
                    "greeting": "Good {time_of_day}, Dr. {hcp_name}. I appreciate you taking the time to see me.",
                    "purpose": "I'm here to discuss how {product_focus} might benefit some of your patients. I see you write approximately {total_market_trx} prescriptions in this category, and I'd like to explore whether {product_focus} could be a valuable addition to your treatment options.",
                    "tone": "Collaborative, educational, patient-focused"
                },
                
                "key_talking_points": [
                    {
                        "point_id": 1,
                        "topic": "Product Education",
                        "message": "{product_focus} is [INSERT PRODUCT DESCRIPTION FROM LIBRARY]. For your {specialty} practice, this may offer advantages for certain patient populations.",
                        "approved_content_refs": ["TIR-MSG-001", "TIR-MSG-002", "FLE-MSG-001", "LIC-MSG-001"]
                    },
                    {
                        "point_id": 2,
                        "topic": "Clinical Evidence",
                        "message": "Clinical studies have shown [INSERT CLINICAL DATA FROM LIBRARY]. This may be particularly relevant for patients who [SPECIFIC PATIENT CHARACTERISTICS].",
                        "approved_content_refs": ["TIR-CLI-001", "TIR-CLI-002", "FLE-CLI-001", "LIC-CLI-001"]
                    },
                    {
                        "point_id": 3,
                        "topic": "Patient Selection Guidance",
                        "message": "Based on your patient population, {product_focus} may be especially suitable for patients with: [LIST APPROPRIATE PATIENT CHARACTERISTICS]. Would you have patients fitting this profile?",
                        "approved_content_refs": []
                    },
                    {
                        "point_id": 4,
                        "topic": "Trial Offer",
                        "message": "I'd like to offer samples so you can trial {product_focus} with 3-5 appropriate patients. This allows both you and your patients to evaluate the therapy without financial commitment.",
                        "approved_content_refs": ["GEN-OBJ-002"]
                    }
                ],
                
                "objection_handlers": {
                    "unfamiliar_with_product": {
                        "objection": "I'm not familiar with your product",
                        "response": "That's completely understandable, and I appreciate your honesty. Let me provide a brief overview: [PRODUCT SUMMARY]. Would you like me to leave educational materials and samples for you to review?",
                        "approved_content_refs": ["TIR-MSG-001", "FLE-MSG-001", "LIC-MSG-001"]
                    },
                    "happy_with_current_portfolio": {
                        "objection": "I have enough options already",
                        "response": "I understand you have established therapies that work well. I'm not suggesting replacing what's working, but rather adding {product_focus} as another option for patients who may have specific needs or preferences. Could I leave samples for those situations?",
                        "approved_content_refs": ["GEN-OBJ-001"]
                    },
                    "need_more_information": {
                        "objection": "I need to review more data before trying",
                        "response": "Absolutely, that's a prudent approach. Let me provide you with [CLINICAL STUDIES, PRESCRIBING INFORMATION]. Would you be open to a brief follow-up call after you've had a chance to review the materials?",
                        "approved_content_refs": ["TIR-CLI-001", "TIR-CLI-002"]
                    }
                },
                
                "call_to_action": {
                    "primary_ask": "Would you be willing to try {product_focus} for 3-5 appropriate patients over the next month?",
                    "secondary_ask": "Can I provide samples and patient education materials today?",
                    "tertiary_ask": "May I follow up with you in 4-6 weeks to discuss your experience?"
                },
                
                "next_steps": [
                    "Provide product samples (sufficient for 5-10 patients)",
                    "Leave patient education materials",
                    "Send clinical reprints and prescribing information",
                    "Schedule 4-6 week follow-up",
                    "Add to priority call list",
                    "Monitor new TRx data"
                ],
                
                "required_disclaimers": [
                    "prescribing_info",
                    "individual_results",
                    "contraindications",
                    "adverse_events"
                ]
            },
            
            "success_metrics": {
                "primary": "Generate 3+ new TRx within 60 days",
                "secondary": "Increase IBSA share to 20%+ within 90 days",
                "tertiary": "Establish regular call schedule (every 6-8 weeks)"
            }
        }
        
        return template
    
    def create_optimization_template(self) -> Dict[str, Any]:
        """
        OPTIMIZATION TEMPLATE
        
        Target: 48.5% of HCPs identified as sample black holes (ROI < 5%)
        Goal: Improve sample ROI and efficiency
        Strategy: Data-driven sample allocation, conversion improvement
        """
        template = {
            "scenario": ScenarioType.OPTIMIZATION.value,
            "target_segment": "Sample Black Holes (receiving samples but low ROI < 5%)",
            "identified_percentage": "48.5%",
            "goal": "Improve sample-to-TRx conversion from <5% to >20%",
            "priority": "MEDIUM",
            
            "dynamic_slots": [
                "{hcp_name}",
                "{specialty}",
                "{samples_provided}",
                "{trx_generated}",
                "{current_roi}",
                "{target_roi}",
                "{product_focus}"
            ],
            
            "script_structure": {
                "opening": {
                    "greeting": "Good {time_of_day}, Dr. {hcp_name}. Thank you for seeing me today.",
                    "purpose": "I wanted to discuss our sampling strategy and make sure we're providing you with resources that truly benefit your patients. I've reviewed our records and want to ensure we're aligned on the best use of samples.",
                    "tone": "Collaborative, efficiency-focused, value-optimization"
                },
                
                "key_talking_points": [
                    {
                        "point_id": 1,
                        "topic": "Sample Usage Review",
                        "message": "Over the past quarter, we've provided approximately {samples_provided} samples of {product_focus}. I want to make sure these are reaching the right patients and being used effectively. How have samples been working in your practice?",
                        "approved_content_refs": []
                    },
                    {
                        "point_id": 2,
                        "topic": "Ideal Patient Profile",
                        "message": "To maximize benefit for your patients, {product_focus} is most appropriate for patients with [SPECIFIC CHARACTERISTICS FROM APPROVED CONTENT]. Are these the types of patients receiving samples?",
                        "approved_content_refs": ["TIR-MSG-001", "TIR-CLI-002", "FLE-MSG-001"]
                    },
                    {
                        "point_id": 3,
                        "topic": "Conversion Strategy",
                        "message": "When patients respond well to samples, transitioning to a paid prescription ensures continuity of therapy. What's your typical process for converting patients from samples to prescriptions?",
                        "approved_content_refs": []
                    },
                    {
                        "point_id": 4,
                        "topic": "Optimized Sample Allocation",
                        "message": "Rather than providing large quantities upfront, let's try a more strategic approach: samples for specific patients who are likely to benefit and continue therapy. This ensures better outcomes for your patients and more efficient use of resources.",
                        "approved_content_refs": []
                    }
                ],
                
                "objection_handlers": {
                    "patients_cant_afford": {
                        "objection": "My patients can't afford the medication after samples run out",
                        "response": "I understand cost is a significant concern. Let me share information about patient assistance programs and co-pay cards that may help. Also, let's focus samples on patients more likely to have coverage, so they can continue therapy.",
                        "approved_content_refs": []
                    },
                    "samples_for_trial_only": {
                        "objection": "I use samples just for short-term trials",
                        "response": "That's a valid use case. For trial purposes, could we identify patients most likely to respond and continue therapy? This helps us provide samples where they'll have the greatest impact.",
                        "approved_content_refs": []
                    },
                    "prefer_other_products": {
                        "objection": "I prefer other products for long-term therapy",
                        "response": "I respect that. Perhaps we can identify the specific patient population where {product_focus} would be your preferred option, and focus our sampling there. That way, samples are used for patients you'd actually prescribe it to.",
                        "approved_content_refs": ["GEN-OBJ-001"]
                    }
                },
                
                "call_to_action": {
                    "primary_ask": "Can we agree on a target of converting at least {target_roi}% of sampled patients to paid prescriptions?",
                    "secondary_ask": "Would you be willing to try a more focused sampling approach - smaller quantities for specifically identified patients?",
                    "tertiary_ask": "May I check in with you in 6-8 weeks to see how the revised strategy is working?"
                },
                
                "next_steps": [
                    "Reduce sample drop quantity by 30-50%",
                    "Provide patient assistance program information",
                    "Share ideal patient profile criteria",
                    "Schedule 6-8 week follow-up",
                    "Monitor sample-to-TRx conversion rate",
                    "Redirect excess samples to high-ROI prescribers"
                ],
                
                "required_disclaimers": [
                    "prescribing_info",
                    "individual_results"
                ]
            },
            
            "success_metrics": {
                "primary": "Improve sample-to-TRx conversion to >20%",
                "secondary": "Reduce wasted samples by 40%",
                "tertiary": "Maintain or increase total TRx despite fewer samples"
            }
        }
        
        return template
    
    def create_introduction_template(self) -> Dict[str, Any]:
        """
        INTRODUCTION TEMPLATE
        
        Target: New HCPs or first-time calls
        Goal: Establish relationship and introduce IBSA portfolio
        Strategy: Professional introduction, needs assessment, value proposition
        """
        template = {
            "scenario": ScenarioType.INTRODUCTION.value,
            "target_segment": "New HCPs or first-time territory calls",
            "goal": "Establish professional relationship and introduce IBSA products",
            "priority": "MEDIUM",
            
            "dynamic_slots": [
                "{hcp_name}",
                "{specialty}",
                "{practice_name}",
                "{years_in_practice}",
                "{patient_volume}",
                "{territory_name}"
            ],
            
            "script_structure": {
                "opening": {
                    "greeting": "Good {time_of_day}, Dr. {hcp_name}. My name is {rep_name}, and I'm the IBSA Pharma territory representative for {territory_name}.",
                    "purpose": "Thank you for taking the time to meet with me today. This is my first opportunity to introduce myself and learn more about your practice. I'd like to understand your patient population and discuss how IBSA products might support your treatment goals.",
                    "tone": "Professional, respectful, relationship-building"
                },
                
                "key_talking_points": [
                    {
                        "point_id": 1,
                        "topic": "Professional Introduction",
                        "message": "I cover {territory_name} for IBSA Pharma. IBSA focuses on specialty pharmaceutical products, including Tirosint for thyroid disorders, Flector Patch for acute pain, and Licart for angina prevention. Given your {specialty} practice, [ONE OR MORE] may be relevant for your patients.",
                        "approved_content_refs": []
                    },
                    {
                        "point_id": 2,
                        "topic": "Needs Assessment",
                        "message": "To make sure our discussions are valuable for you, could you share a bit about your practice? What are your most common conditions or patient populations? What challenges do you face with current therapies?",
                        "approved_content_refs": []
                    },
                    {
                        "point_id": 3,
                        "topic": "Product Portfolio Overview",
                        "message": "Based on your {specialty} practice, let me highlight [RELEVANT PRODUCT]: [INSERT APPROVED PRODUCT MESSAGING]. Would this be of interest for your patient population?",
                        "approved_content_refs": ["TIR-MSG-001", "FLE-MSG-001", "LIC-MSG-001"]
                    },
                    {
                        "point_id": 4,
                        "topic": "Value Proposition",
                        "message": "My goal is to be a resource for you - whether that's providing clinical information, samples for appropriate patients, or connecting you with our medical science liaisons for detailed questions. How can I best support your practice?",
                        "approved_content_refs": []
                    }
                ],
                
                "objection_handlers": {
                    "too_busy": {
                        "objection": "I'm very busy and don't have time for rep calls",
                        "response": "I completely understand - your time is valuable. I'll be brief today and respect your schedule. Perhaps we could establish a regular cadence that works for you - maybe 15 minutes once a quarter? I can also communicate via email if that's more convenient.",
                        "approved_content_refs": []
                    },
                    "dont_see_reps": {
                        "objection": "I have a policy of not seeing pharmaceutical representatives",
                        "response": "I respect your policy. Would you be open to receiving educational materials and product information by email? I can also arrange for you to speak with our medical science liaison if you have clinical questions that would benefit from a deeper scientific discussion.",
                        "approved_content_refs": []
                    },
                    "satisfied_with_current_options": {
                        "objection": "I'm satisfied with my current treatment approach",
                        "response": "That's excellent to hear. I'm not here to change what's working well. My goal is simply to make you aware of our products as additional options for those situations where your current approach may not be optimal. May I leave information for your reference?",
                        "approved_content_refs": ["GEN-OBJ-001"]
                    }
                },
                
                "call_to_action": {
                    "primary_ask": "Would you be open to learning more about [MOST RELEVANT PRODUCT] at our next meeting?",
                    "secondary_ask": "May I leave product information and samples for your review?",
                    "tertiary_ask": "What would be the best way to schedule future visits with you?"
                },
                
                "next_steps": [
                    "Leave business card and contact information",
                    "Provide product portfolio overview brochure",
                    "Offer samples of most relevant product",
                    "Determine preferred contact method and frequency",
                    "Add to territory call routing",
                    "Send follow-up email with resources"
                ],
                
                "required_disclaimers": [
                    "prescribing_info",
                    "indication"
                ]
            },
            
            "success_metrics": {
                "primary": "Establish regular call schedule",
                "secondary": "Identify 1-2 products of potential interest",
                "tertiary": "Generate first TRx within 90 days"
            }
        }
        
        return template
    
    def generate_all_templates(self):
        """Generate all 4 scenario templates"""
        print("\n" + "="*100)
        print("📝 GENERATING CALL SCRIPT TEMPLATES")
        print("="*100)
        
        print("\n🎯 Creating RETENTION template (660 at-risk HCPs)...")
        self.templates[ScenarioType.RETENTION.value] = self.create_retention_template()
        print("   ✓ Retention template created")
        
        print("\n📈 Creating GROWTH template (264 opportunity HCPs)...")
        self.templates[ScenarioType.GROWTH.value] = self.create_growth_template()
        print("   ✓ Growth template created")
        
        print("\n⚡ Creating OPTIMIZATION template (48.5% sample black holes)...")
        self.templates[ScenarioType.OPTIMIZATION.value] = self.create_optimization_template()
        print("   ✓ Optimization template created")
        
        print("\n👋 Creating INTRODUCTION template (new HCPs)...")
        self.templates[ScenarioType.INTRODUCTION.value] = self.create_introduction_template()
        print("   ✓ Introduction template created")
        
        print(f"\n✅ All 4 templates generated successfully")
    
    def save_templates(self):
        """Save templates to JSON file"""
        print("\n" + "="*100)
        print("💾 SAVING CALL SCRIPT TEMPLATES")
        print("="*100)
        
        # Save templates
        templates_file = self.output_dir / 'call_script_templates.json'
        templates_data = {
            "created_at": datetime.now().isoformat(),
            "total_templates": len(self.templates),
            "templates": self.templates
        }
        
        with open(templates_file, 'w', encoding='utf-8') as f:
            json.dump(templates_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n✓ Templates saved: {templates_file.name}")
        print(f"   • Total templates: {len(self.templates)}")
        
        # Save usage guide
        usage_guide = {
            "created_at": datetime.now().isoformat(),
            "overview": "Guide for using call script templates",
            "template_selection": {
                "retention": "Use for HCPs with declining IBSA share (660 identified in EDA)",
                "growth": "Use for high-volume HCPs with low IBSA share (264 identified)",
                "optimization": "Use for HCPs receiving samples with low ROI (48.5% of HCPs)",
                "introduction": "Use for new HCPs or first-time calls"
            },
            "dynamic_slot_filling": {
                "description": "Replace placeholder slots with actual HCP data",
                "example": "{hcp_name} → Dr. John Smith",
                "required_data_sources": [
                    "HCP profile (name, specialty, practice)",
                    "Prescription data (current TRx, trends)",
                    "Sample data (quantity provided, ROI)",
                    "Market intelligence (IBSA share, competitive threats)",
                    "Model predictions (from Phase 6 ML models)"
                ]
            },
            "compliance_integration": {
                "approved_content": "Always use approved content from compliance library (Phase 6B)",
                "required_disclaimers": "Include all relevant disclaimers at end of script",
                "prohibited_terms": "Never use terms from prohibited_terms.json",
                "approval_tracking": "Log content used for audit trail"
            },
            "personalization_options": {
                "manual": "Rep manually fills slots with HCP data",
                "semi_automated": "CRM system pre-fills known data fields",
                "fully_automated": "RAG + GPT-4 system generates complete script (Phase 6D)"
            }
        }
        
        guide_file = self.output_dir / 'template_usage_guide.json'
        with open(guide_file, 'w', encoding='utf-8') as f:
            json.dump(usage_guide, f, indent=2, ensure_ascii=False)
        
        print(f"\n✓ Usage guide saved: {guide_file.name}")
        
        print(f"\n✅ All files saved to: {self.output_dir}")


if __name__ == '__main__':
    print("""
    ╔════════════════════════════════════════════════════════════════════════════╗
    ║                                                                            ║
    ║  CALL SCRIPT TEMPLATES - SCENARIO-BASED APPROACH                          ║
    ║                                                                            ║
    ║  4 Intelligent Scenarios:                                                 ║
    ║  • RETENTION - 660 at-risk HCPs (halt decline)                            ║
    ║  • GROWTH - 264 opportunity HCPs (expand share)                           ║
    ║  • OPTIMIZATION - 48.5% sample black holes (improve ROI)                  ║
    ║  • INTRODUCTION - New HCPs (build relationships)                          ║
    ║                                                                            ║
    ║  Features:                                                                ║
    ║  • Dynamic slot filling with HCP data                                     ║
    ║  • MLR-approved content integration                                       ║
    ║  • Required disclaimers                                                   ║
    ║  • Structured format (Opening → CTA → Next Steps)                         ║
    ║                                                                            ║
    ╚════════════════════════════════════════════════════════════════════════════╝
    """.replace('╔', '=').replace('║', '|').replace('╚', '=').replace('═', '='))
    
    # Create template engine
    engine = CallScriptTemplateEngine()
    
    # Generate all templates
    engine.generate_all_templates()
    
    # Save templates
    engine.save_templates()
    
    print("\n" + "="*100)
    print("✅ PHASE 6C COMPLETE - CALL SCRIPT TEMPLATES READY!")
    print("="*100)
    print("\n📦 Outputs:")
    print("  • call_script_templates.json (4 scenario templates)")
    print("  • template_usage_guide.json (implementation guide)")
    print("\n🎯 Templates are ready for:")
    print("  • Manual use by territory reps")
    print("  • Semi-automated CRM integration")
    print("  • Full automation with RAG + GPT-4 (Phase 6D)")
    print("="*100)

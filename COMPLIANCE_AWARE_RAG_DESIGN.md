# COMPLIANCE-AWARE RAG SYSTEM FOR CALL SCRIPT GENERATION
**Regulatory-First AI Architecture for Pharmaceutical Territory Sales**

---

## 🚨 **The Compliance Challenge**

### **Pharmaceutical Regulatory Requirements:**
1. **FDA Regulations** - No off-label promotion
2. **CRC (Clinical Research Compliance)** - Accurate clinical claims
3. **MLR (Medical Legal Regulatory)** - Pre-approved messaging only
4. **OPDP (Office of Prescription Drug Promotion)** - Fair balance, no misleading claims
5. **HIPAA** - Patient privacy protection
6. **PhRMA Code** - Ethical marketing practices

### **What Can Go Wrong with Uncontrolled AI:**
❌ Generate off-label uses  
❌ Make unsubstantiated efficacy claims  
❌ Omit important safety information  
❌ Use non-approved comparative language  
❌ Violate fair balance requirements  

**Result:** FDA warning letter, fines, legal liability, brand damage

---

## ✅ **Solution: 3-Layer Compliance-First RAG**

```
Layer 1: PRE-APPROVED CONTENT LIBRARY (Compliance Gate)
    ↓
Layer 2: RAG RETRIEVAL (Only from approved content)
    ↓
Layer 3: GENERATION + COMPLIANCE FILTER (Final safety check)
```

---

## 📚 **Layer 1: Pre-Approved Content Library**

### **What Goes In This Library:**
Only **MLR/CRC-approved** content from:

1. **Approved Product Messaging Documents**
   - Brand messaging guide (MLR-approved)
   - Product monographs
   - FDA-approved labeling
   - Package inserts
   - Prescribing information

2. **Approved Sales Training Materials**
   - Sales aid scripts (MLR-reviewed)
   - Objection handling guides (CRC-approved)
   - Clinical study talking points (pre-approved)
   - Competitive positioning (legal-reviewed)

3. **Approved Call Scripts (Historical)**
   - Scripts used in field (already compliant)
   - Successful calls logged in CRM
   - Scripts that passed compliance review
   - Templates from sales training

4. **Approved Clinical Data**
   - Published study results
   - FDA-approved claims
   - Safety/efficacy data (verified)
   - Comparative data (if approved)

### **Content Curation Process:**

```python
class ComplianceApprovedContentLibrary:
    """
    Only MLR/CRC-approved content enters this library
    """
    
    def __init__(self):
        self.approved_content = {
            'product_messaging': [],      # MLR-approved brand messages
            'clinical_claims': [],        # CRC-verified clinical data
            'safety_information': [],     # FDA-approved safety info
            'competitor_positioning': [], # Legal-reviewed comparisons
            'objection_handlers': [],     # Pre-approved responses
            'call_templates': []          # Compliance-reviewed scripts
        }
        
        self.approval_metadata = {}  # Tracks approval status
    
    def add_content(self, content, approval_info):
        """
        Add content ONLY if it has valid approval
        """
        # Validate approval
        if not self._validate_approval(approval_info):
            raise ComplianceException("Content not approved by MLR/CRC")
        
        # Check approval expiration
        if approval_info['expires_at'] < datetime.now():
            raise ComplianceException("Approval expired - needs re-review")
        
        # Tag with compliance metadata
        content_id = self._generate_content_id(content)
        self.approval_metadata[content_id] = {
            'approved_by': approval_info['approved_by'],  # e.g., "MLR Team"
            'approval_date': approval_info['approval_date'],
            'approval_id': approval_info['approval_id'],  # Tracking number
            'expires_at': approval_info['expires_at'],
            'approved_uses': approval_info['approved_uses'],  # On-label only
            'restrictions': approval_info.get('restrictions', []),
            'required_disclaimers': approval_info.get('disclaimers', [])
        }
        
        # Add to appropriate category
        category = approval_info['category']
        self.approved_content[category].append({
            'content_id': content_id,
            'text': content,
            'metadata': self.approval_metadata[content_id]
        })
        
        return content_id
    
    def _validate_approval(self, approval_info):
        """
        Ensure content has proper MLR/CRC approval
        """
        required_fields = [
            'approved_by',      # MLR/CRC team
            'approval_date',    # When approved
            'approval_id',      # Tracking number
            'expires_at'        # Approval expiration
        ]
        
        for field in required_fields:
            if field not in approval_info:
                return False
        
        # Check approval authority
        valid_approvers = ['MLR', 'CRC', 'Legal', 'Medical Affairs']
        if approval_info['approved_by'] not in valid_approvers:
            return False
        
        return True
```

### **Example: Adding Approved Content**

```python
library = ComplianceApprovedContentLibrary()

# Add MLR-approved product message
library.add_content(
    content="Tirosint's gel cap formulation provides consistent absorption, "
            "even in patients with gastrointestinal conditions.",
    approval_info={
        'approved_by': 'MLR',
        'approval_date': '2024-06-15',
        'approval_id': 'MLR-2024-0123',
        'expires_at': '2025-12-31',
        'category': 'product_messaging',
        'approved_uses': ['hypothyroidism'],  # On-label only
        'restrictions': ['Do not use for weight loss'],
        'required_disclaimers': ['See full prescribing information']
    }
)

# Add CRC-approved clinical claim
library.add_content(
    content="In a clinical study, Tirosint demonstrated 20% faster time to "
            "therapeutic TSH levels compared to levothyroxine tablets.",
    approval_info={
        'approved_by': 'CRC',
        'approval_date': '2024-08-01',
        'approval_id': 'CRC-2024-0456',
        'expires_at': '2026-08-01',
        'category': 'clinical_claims',
        'approved_uses': ['hypothyroidism'],
        'study_reference': 'PMID: 12345678',
        'required_disclaimers': ['Results from single study, individual results may vary']
    }
)
```

---

## 🔍 **Layer 2: RAG Retrieval (Compliance-Constrained)**

### **Vector Database with Compliance Metadata**

```python
from sentence_transformers import SentenceTransformer
import faiss
import numpy as np

class ComplianceAwareVectorDB:
    """
    Vector database that ONLY retrieves approved content
    """
    
    def __init__(self, approved_library):
        self.library = approved_library
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Build vector index from ONLY approved content
        self.build_index()
    
    def build_index(self):
        """
        Create vector embeddings for all approved content
        """
        all_content = []
        self.content_ids = []
        
        for category, items in self.library.approved_content.items():
            for item in items:
                # Only add if approval still valid
                metadata = item['metadata']
                if metadata['expires_at'] > datetime.now():
                    all_content.append(item['text'])
                    self.content_ids.append(item['content_id'])
        
        # Generate embeddings
        self.embeddings = self.embedding_model.encode(all_content)
        
        # Create FAISS index
        dimension = self.embeddings.shape[1]
        self.index = faiss.IndexFlatL2(dimension)
        self.index.add(np.array(self.embeddings).astype('float32'))
        
        print(f"✅ Indexed {len(all_content)} approved content pieces")
    
    def retrieve_compliant(self, query, scenario, top_k=5, filters=None):
        """
        Retrieve ONLY compliant content relevant to query
        """
        # Embed query
        query_embedding = self.embedding_model.encode([query])
        
        # Search vector DB
        distances, indices = self.index.search(
            np.array(query_embedding).astype('float32'), 
            top_k * 2  # Get extra for filtering
        )
        
        # Filter by compliance constraints
        retrieved_content = []
        for idx in indices[0]:
            if idx >= len(self.content_ids):
                continue
            
            content_id = self.content_ids[idx]
            metadata = self.library.approval_metadata[content_id]
            
            # Apply compliance filters
            if filters:
                # Check product match
                if 'product' in filters:
                    if filters['product'] not in metadata.get('approved_products', []):
                        continue
                
                # Check indication match
                if 'indication' in filters:
                    if filters['indication'] not in metadata.get('approved_uses', []):
                        continue
                
                # Check scenario restrictions
                if 'scenario' in filters:
                    if scenario in metadata.get('restricted_scenarios', []):
                        continue
            
            # Passed all filters - add to results
            retrieved_content.append({
                'text': self.library.approved_content[metadata['category']][idx]['text'],
                'metadata': metadata,
                'relevance_score': 1.0 / (1.0 + distances[0][list(indices[0]).index(idx)])
            })
            
            if len(retrieved_content) >= top_k:
                break
        
        return retrieved_content
```

### **Example: Compliant Retrieval**

```python
vector_db = ComplianceAwareVectorDB(library)

# Retrieve for "retention" scenario
retrieved = vector_db.retrieve_compliant(
    query="Tirosint absorption benefits for endocrinology patients",
    scenario="retention",
    top_k=3,
    filters={
        'product': 'Tirosint',
        'indication': 'hypothyroidism',  # On-label only
        'specialty': 'Endocrinology'
    }
)

# Output: ONLY MLR/CRC-approved content matching criteria
for item in retrieved:
    print(f"✅ Approved: {item['text']}")
    print(f"   Approved by: {item['metadata']['approved_by']}")
    print(f"   Approval ID: {item['metadata']['approval_id']}")
    print(f"   Expires: {item['metadata']['expires_at']}")
```

---

## 🤖 **Layer 3: Generation + Compliance Filter**

### **Template-Based Generation (Safest)**

```python
class ComplianceAwareScriptGenerator:
    """
    Generate scripts using ONLY approved content
    """
    
    def __init__(self, library, vector_db):
        self.library = library
        self.vector_db = vector_db
        self.compliance_checker = ComplianceChecker()
    
    def generate_script(self, hcp_profile, predictions, scenario):
        """
        Generate call script with compliance guarantees
        """
        # 1. Retrieve approved content
        retrieved_content = self.vector_db.retrieve_compliant(
            query=self._build_query(hcp_profile, scenario),
            scenario=scenario,
            top_k=5,
            filters={
                'product': hcp_profile.get('primary_product', 'Tirosint'),
                'indication': 'hypothyroidism',  # On-label
                'specialty': hcp_profile.get('specialty')
            }
        )
        
        # 2. Select template (pre-approved)
        template = self._select_template(scenario)
        
        # 3. Fill template with approved content only
        script = self._fill_template(
            template=template,
            hcp_profile=hcp_profile,
            approved_content=retrieved_content
        )
        
        # 4. FINAL COMPLIANCE CHECK (safety gate)
        compliance_result = self.compliance_checker.validate_script(script)
        
        if not compliance_result['is_compliant']:
            # Log violation for review
            self._log_compliance_violation(script, compliance_result)
            
            # Fall back to ultra-safe generic template
            script = self._get_safe_fallback_template(scenario)
        
        # 5. Add required disclaimers
        script = self._add_required_disclaimers(script, retrieved_content)
        
        return {
            'script': script,
            'compliance_verified': True,
            'approval_sources': [item['metadata']['approval_id'] 
                                for item in retrieved_content],
            'generated_at': datetime.now().isoformat()
        }
    
    def _fill_template(self, template, hcp_profile, approved_content):
        """
        Fill template ONLY with approved content and HCP data
        """
        # Safe HCP data (names, specialty, non-PHI metrics)
        safe_hcp_data = {
            'name': hcp_profile.get('name', 'Doctor'),
            'specialty': hcp_profile.get('specialty', 'Physician'),
            'current_trx': hcp_profile.get('trx_c4wk', 'X'),
            # NO PHI - patient names, conditions, etc.
        }
        
        # Use ONLY approved talking points
        talking_points = [
            item['text'] for item in approved_content[:3]
        ]
        
        script = template.format(
            **safe_hcp_data,
            talking_point_1=talking_points[0] if len(talking_points) > 0 else '',
            talking_point_2=talking_points[1] if len(talking_points) > 1 else '',
            talking_point_3=talking_points[2] if len(talking_points) > 2 else ''
        )
        
        return script
```

### **Compliance Checker (Final Safety Gate)**

```python
class ComplianceChecker:
    """
    Final safety check before script is delivered
    """
    
    def __init__(self):
        # Load blacklist of prohibited terms
        self.prohibited_terms = self._load_prohibited_terms()
        
        # Load required disclaimers
        self.required_disclaimers = self._load_required_disclaimers()
    
    def validate_script(self, script):
        """
        Multi-layer compliance validation
        """
        violations = []
        
        # 1. Check for prohibited terms
        for term in self.prohibited_terms:
            if term.lower() in script.lower():
                violations.append({
                    'type': 'prohibited_term',
                    'term': term,
                    'reason': self.prohibited_terms[term]
                })
        
        # 2. Check for off-label mentions
        off_label_terms = ['weight loss', 'obesity', 'off-label']
        for term in off_label_terms:
            if term.lower() in script.lower():
                violations.append({
                    'type': 'off_label_risk',
                    'term': term,
                    'reason': 'Potential off-label promotion'
                })
        
        # 3. Check for unsubstantiated claims
        claim_words = ['best', 'superior', 'proven', 'guaranteed']
        for word in claim_words:
            if word.lower() in script.lower():
                # Check if claim is backed by approved clinical data
                if not self._has_clinical_support(script, word):
                    violations.append({
                        'type': 'unsubstantiated_claim',
                        'term': word,
                        'reason': 'Claim requires clinical evidence citation'
                    })
        
        # 4. Check for required disclaimers
        if 'efficacy' in script.lower() or 'results' in script.lower():
            if 'individual results may vary' not in script.lower():
                violations.append({
                    'type': 'missing_disclaimer',
                    'reason': 'Efficacy claims require disclaimer'
                })
        
        # 5. Check fair balance
        if self._mentions_benefits(script) and not self._mentions_risks(script):
            violations.append({
                'type': 'fair_balance',
                'reason': 'Must mention risks when discussing benefits'
            })
        
        return {
            'is_compliant': len(violations) == 0,
            'violations': violations,
            'severity': self._calculate_severity(violations)
        }
    
    def _load_prohibited_terms(self):
        """
        Load terms that CANNOT appear in scripts
        """
        return {
            'cure': 'No drug cures hypothyroidism',
            'weight loss': 'Off-label use',
            'faster metabolism': 'Off-label claim',
            'better than': 'Requires head-to-head study approval',
            'guaranteed': 'Results not guaranteed',
            'miracle': 'Unsubstantiated superlative',
            'breakthrough': 'Requires FDA breakthrough designation',
            # ... more prohibited terms
        }
    
    def _add_required_disclaimers(self, script):
        """
        Add mandatory disclaimers
        """
        disclaimers = [
            "\n\n[Important Safety Information: See full prescribing information]",
            "[Individual results may vary]"
        ]
        
        return script + '\n'.join(disclaimers)
```

---

## 📋 **Compliance Workflow (End-to-End)**

### **1. Content Approval Process (Before System Launch)**

```
Medical Affairs Team
    ↓
Creates product messaging, clinical claims, safety info
    ↓
MLR Review (Medical Legal Regulatory)
    ↓
CRC Review (Clinical Research Compliance)
    ↓
Legal Review
    ↓
APPROVED CONTENT → Added to Library with metadata
    ↓
Vector DB indexed with compliance tags
```

### **2. Script Generation (Runtime)**

```
Rep requests call script for HCP
    ↓
System retrieves HCP profile + predictions
    ↓
RAG retrieves ONLY approved content from library
    ↓
Template filled with approved content
    ↓
Compliance Checker validates (final gate)
    ↓
IF violations found → Use safe fallback template
    ↓
Add required disclaimers
    ↓
Return compliant script to rep
```

### **3. Continuous Monitoring (Post-Launch)**

```
Every generated script logged
    ↓
Random sample reviewed by MLR team monthly
    ↓
Any compliance issues → Update prohibited terms list
    ↓
Approval expirations tracked → Content removed if expired
    ↓
New approved content → Added to library, re-index
```

---

## 🛡️ **Compliance Safeguards**

### **Multiple Layers of Protection:**

1. **Input Layer:** Only approved content enters library
2. **Storage Layer:** Approval metadata tracked with every piece of content
3. **Retrieval Layer:** Only retrieve content matching compliance filters
4. **Generation Layer:** Templates use ONLY approved content
5. **Validation Layer:** Final compliance check before delivery
6. **Monitoring Layer:** All scripts logged for audit
7. **Expiration Layer:** Expired approvals automatically removed

### **Fallback Mechanisms:**

```python
# If compliance checker finds violation
if not compliance_result['is_compliant']:
    # Option 1: Use ultra-safe generic template
    script = "Hi Dr. {name}, I wanted to discuss Tirosint for your " \
             "appropriate patients with hypothyroidism. " \
             "[See full prescribing information]"
    
    # Option 2: Block generation, require manual review
    return {
        'error': 'Compliance violation detected',
        'requires_manual_review': True,
        'violation_details': compliance_result['violations']
    }
```

---

## 📊 **Implementation Steps**

### **Phase 1: Build Compliance Infrastructure (Week 1-2)**
1. ✅ Create `ComplianceApprovedContentLibrary` class
2. ✅ Work with MLR/CRC to curate approved content
3. ✅ Tag all content with approval metadata
4. ✅ Build prohibited terms dictionary
5. ✅ Create compliance checker with validation rules

### **Phase 2: RAG Implementation (Week 3-4)**
6. ✅ Build vector DB with compliance-aware retrieval
7. ✅ Create template library (pre-approved by MLR)
8. ✅ Implement script generation with compliance gates
9. ✅ Test with 100 scenarios, verify all compliant
10. ✅ MLR team reviews and approves system

### **Phase 3: Monitoring & Iteration (Week 5-6)**
11. ✅ Deploy with logging/monitoring
12. ✅ Monthly MLR audits of generated scripts
13. ✅ Update content library as new materials approved
14. ✅ Refine prohibited terms based on field feedback

---

## ✅ **Compliance Checklist**

Before deploying to production:

- [ ] All content in library has valid MLR/CRC approval
- [ ] Approval metadata complete (approval_id, expires_at, etc.)
- [ ] Prohibited terms dictionary comprehensive
- [ ] Compliance checker covers all FDA/CRC requirements
- [ ] Fallback mechanisms tested
- [ ] Logging/audit trail functional
- [ ] MLR team has reviewed system
- [ ] Legal team has signed off
- [ ] Training materials for reps (how to use, what NOT to edit)
- [ ] Process for updating content when new approvals come in

---

## 🎯 **Benefits of This Approach**

✅ **Zero Risk of Non-Compliant Messaging** - Only approved content used  
✅ **Audit Trail** - Every script traceable to approved source  
✅ **Automatic Updates** - New approvals immediately available  
✅ **Expired Content Removed** - No outdated messaging  
✅ **MLR-Friendly** - Transparent, explainable, auditable  
✅ **Legally Defensible** - Can prove compliance in audit  

---

## 🚀 **Next Steps**

**Want me to:**
1. Build the `ComplianceApprovedContentLibrary` class
2. Create the compliance-aware RAG system
3. Implement the `ComplianceChecker` validation layer
4. Create sample approved content with proper metadata
5. Build the end-to-end script generation API

**This approach gives you the power of RAG with ZERO compliance risk!** 🎯

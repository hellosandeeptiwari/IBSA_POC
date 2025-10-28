"""
Test FastAPI with a real HCP ID from the dataset
"""
import requests
import json

API_BASE = "http://localhost:8000"
API_KEY = "ibsa-ai-script-generator-2025"

# Real HCP ID from feature data
HCP_ID = "7269747"

print("="*80)
print("TESTING FASTAPI WITH REAL HCP")
print("="*80)
print(f"\n🎯 Testing with HCP ID: {HCP_ID}")
print(f"📍 API: {API_BASE}")

# Test 1: Generate call script (Template only - faster)
print("\n" + "="*80)
print("TEST 1: Generate Call Script (Template Only)")
print("="*80)

payload = {
    "hcp_id": HCP_ID,
    "include_gpt4": False  # Template only for faster testing
}

headers = {
    "X-API-Key": API_KEY,
    "Content-Type": "application/json"
}

try:
    response = requests.post(
        f"{API_BASE}/generate-call-script",
        json=payload,
        headers=headers,
        timeout=30
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\n✅ SUCCESS!")
        print(f"\n📄 Script Details:")
        print(f"  - HCP ID: {data.get('hcp_id', 'N/A')}")
        print(f"  - Scenario: {data.get('scenario', 'N/A')}")
        print(f"  - Priority: {data.get('priority', 'N/A')}")
        
        # Extract script - it's now a dict with 'formatted_text' field
        script_data = data.get('script', {})
        if isinstance(script_data, dict):
            script_text = script_data.get('formatted_text', '')
            gpt4_enhanced = script_data.get('metadata', {}).get('gpt4_enhanced', False)
        else:
            script_text = str(script_data)
            gpt4_enhanced = False
        
        # Extract compliance info
        compliance = data.get('compliance', {})
        compliance_score = 100 if compliance.get('is_compliant', False) else 0
        
        print(f"  - GPT-4 Enhanced: {gpt4_enhanced}")
        print(f"  - Compliance: {'✓ PASSED' if compliance.get('is_compliant') else '✗ FAILED'}")
        print(f"  - Violations: {compliance.get('total_violations', 0)}")
        
        # Show first 500 chars of script
        print(f"\n📝 Script Preview (first 500 chars):")
        print("-" * 80)
        if script_text:
            print(script_text[:500])
            if len(script_text) > 500:
                print(f"\n... ({len(script_text) - 500} more characters)")
        else:
            print("⚠️  No script text found in response")
        print("-" * 80)
        
        # Save full script
        with open("test_generated_script.txt", "w", encoding="utf-8") as f:
            f.write(f"HCP ID: {HCP_ID}\n")
            f.write(f"Scenario: {data.get('scenario', 'N/A')}\n")
            f.write(f"Priority: {data.get('priority', 'N/A')}\n")
            f.write(f"GPT-4 Enhanced: {gpt4_enhanced}\n")
            f.write(f"Compliance: {compliance_score}%\n")
            f.write(f"Violations: {compliance.get('total_violations', 0)}\n")
            f.write("\n" + "="*80 + "\n\n")
            f.write(script_text)
        
        print(f"\n💾 Full script saved to: test_generated_script.txt")
        
    else:
        print(f"\n❌ ERROR!")
        print(response.json())
        
except requests.exceptions.ConnectionError:
    print(f"\n❌ ERROR: Cannot connect to API at {API_BASE}")
    print("   Make sure FastAPI is running: python phase6e_fastapi_production_api.py")
except requests.exceptions.Timeout:
    print(f"\n❌ ERROR: Request timeout after 30 seconds")
except Exception as e:
    print(f"\n❌ ERROR: {e}")

# Test 2: Generate with GPT-4 enhancement
print("\n" + "="*80)
print("TEST 2: Generate Call Script (With GPT-4 Enhancement)")
print("="*80)
print("\nℹ️  This will take 5-10 seconds and uses OpenAI API...")

user_input = input("\nRun GPT-4 enhanced test? (y/n): ").strip().lower()

if user_input == 'y':
    payload_gpt4 = {
        "hcp_id": HCP_ID,
        "include_gpt4": True
    }
    
    try:
        response = requests.post(
            f"{API_BASE}/generate-call-script",
            json=payload_gpt4,
            headers=headers,
            timeout=30
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n✅ SUCCESS!")
            
            # Extract script - it's now a dict with 'formatted_text' field
            script_data = data.get('script', {})
            if isinstance(script_data, dict):
                script_text = script_data.get('formatted_text', '')
                gpt4_enhanced = script_data.get('metadata', {}).get('gpt4_enhanced', False)
            else:
                script_text = str(script_data)
                gpt4_enhanced = False
            
            # Extract compliance info
            compliance = data.get('compliance', {})
            compliance_score = 100 if compliance.get('is_compliant', False) else 0
            
            print(f"\n📄 Script Details:")
            print(f"  - HCP ID: {data.get('hcp_id', 'N/A')}")
            print(f"  - Scenario: {data.get('scenario', 'N/A')}")
            print(f"  - Priority: {data.get('priority', 'N/A')}")
            print(f"  - GPT-4 Enhanced: {gpt4_enhanced}")
            print(f"  - Compliance: {'✓ PASSED' if compliance.get('is_compliant') else '✗ FAILED'}")
            print(f"  - Violations: {compliance.get('total_violations', 0)}")
            print(f"  - Generation Time: {data.get('generation_time_seconds', 0)}s")
            print(f"  - Cost: ${data.get('cost_usd', 0):.4f}")
            
            # Show first 500 chars
            print(f"\n📝 GPT-4 Enhanced Script Preview (first 500 chars):")
            print("-" * 80)
            if script_text:
                print(script_text[:500])
                if len(script_text) > 500:
                    print(f"\n... ({len(script_text) - 500} more characters)")
            else:
                print("⚠️  No script text found in response")
            print("-" * 80)
            
            # Save GPT-4 script
            with open("test_generated_script_gpt4.txt", "w", encoding="utf-8") as f:
                f.write(f"HCP ID: {HCP_ID}\n")
                f.write(f"Scenario: {data.get('scenario', 'N/A')}\n")
                f.write(f"Priority: {data.get('priority', 'N/A')}\n")
                f.write(f"GPT-4 Enhanced: YES\n")
                f.write(f"Compliance: {compliance_score}%\n")
                f.write(f"Violations: {compliance.get('total_violations', 0)}\n")
                f.write("\n" + "="*80 + "\n\n")
                f.write(script_text)
            
            print(f"\n💾 GPT-4 script saved to: test_generated_script_gpt4.txt")
            
        else:
            print(f"\n❌ ERROR!")
            print(response.json())
            
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
else:
    print("\nSkipped GPT-4 test")

print("\n" + "="*80)
print("✅ TESTING COMPLETE")
print("="*80)
print("\nNext Steps:")
print("1. Review generated scripts in test_generated_script*.txt")
print("2. Compare Template vs GPT-4 Enhanced versions")
print("3. Verify compliance checking (100% expected)")
print("4. Start UI: cd ibsa_precall_ui && npm run dev")

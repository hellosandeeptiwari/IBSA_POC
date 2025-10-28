"""
Test FastAPI Call Script Generator
Quick test to verify backend is working before testing UI
"""

import requests
import json

API_URL = "http://localhost:8000"
API_KEY = "ibsa-ai-script-generator-2025"

def test_health():
    """Test health endpoint"""
    print("=" * 80)
    print("TEST 1: Health Check")
    print("=" * 80)
    
    response = requests.get(f"{API_URL}/health")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
    print()

def test_generate_script():
    """Test script generation"""
    print("=" * 80)
    print("TEST 2: Generate Call Script for HCP 12345")
    print("=" * 80)
    
    payload = {
        "hcp_id": "12345",
        "include_gpt4": False  # Use template only for faster test
    }
    
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": API_KEY
    }
    
    print(f"Request: POST {API_URL}/generate-call-script")
    print(f"Payload: {json.dumps(payload, indent=2)}")
    print()
    
    response = requests.post(
        f"{API_URL}/generate-call-script",
        json=payload,
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\n✅ SUCCESS!")
        print(f"Scenario: {data['scenario']}")
        print(f"Priority: {data['priority']}")
        print(f"Generation Time: {data['generation_time_seconds']:.2f}s")
        print(f"Cost: ${data['cost_usd']:.4f}")
        print(f"Compliant: {data['compliance']['is_compliant']}")
        print(f"\nScript Preview:")
        print(f"Opening: {data['script']['opening'][:100]}...")
        print(f"Talking Points: {len(data['script']['talking_points'])} points")
        print(f"Objection Handlers: {len(data['script']['objection_handlers'])} handlers")
    else:
        print(f"\n❌ ERROR!")
        print(response.text)
    print()

def test_models_status():
    """Test models status endpoint"""
    print("=" * 80)
    print("TEST 3: Models Status")
    print("=" * 80)
    
    headers = {"X-API-Key": API_KEY}
    
    response = requests.get(
        f"{API_URL}/models/status",
        headers=headers
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\nModels Loaded: {data['loaded_models']}")
        print(f"Total Models: {data['total_models']}")
        print(f"\nModel Details:")
        for model in data['models'][:3]:  # Show first 3
            print(f"  {model['model_name']}:")
            print(f"    Product: {model['product']}")
            print(f"    Target: {model['target']}")
            print(f"    Exists: {model['model_exists']}")
    else:
        print(f"\n❌ ERROR!")
        print(response.text)
    print()

if __name__ == "__main__":
    print("\n" + "=" * 80)
    print("FASTAPI CALL SCRIPT GENERATOR - TEST SUITE")
    print("=" * 80)
    print()
    
    try:
        # Test 1: Health check
        test_health()
        
        # Test 2: Generate script
        test_generate_script()
        
        # Test 3: Models status
        test_models_status()
        
        print("=" * 80)
        print("✅ ALL TESTS COMPLETE")
        print("=" * 80)
        print()
        print("Next Steps:")
        print("1. Start Next.js UI: cd ibsa_precall_ui && npm run dev")
        print("2. Open: http://localhost:3000")
        print("3. Click any HCP → Click 'AI Call Script' tab")
        print("4. Click 'Generate with AI Enhancement'")
        print()
        
    except requests.exceptions.ConnectionError:
        print("=" * 80)
        print("❌ ERROR: Cannot connect to FastAPI server")
        print("=" * 80)
        print()
        print("Please start the FastAPI server first:")
        print("  python start_api.py")
        print()

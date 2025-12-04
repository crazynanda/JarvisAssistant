"""
Test script for J.A.R.V.I.S Server API
Run this to test the server endpoints
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_health_check():
    """Test the health check endpoint"""
    print("Testing health check...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}\n")

def test_ask_endpoint(user_input: str):
    """Test the /ask endpoint"""
    print(f"Testing /ask with input: '{user_input}'")
    
    payload = {
        "user_input": user_input
    }
    
    response = requests.post(
        f"{BASE_URL}/ask",
        json=payload,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"Response: {data['response']}\n")
    else:
        print(f"Error: {response.text}\n")

def main():
    print("=" * 60)
    print("J.A.R.V.I.S Server API Test")
    print("=" * 60 + "\n")
    
    # Test health check
    try:
        test_health_check()
    except Exception as e:
        print(f"Health check failed: {e}\n")
        print("Make sure the server is running: python main.py")
        return
    
    # Test various queries
    test_queries = [
        "Hello JARVIS",
        "What's the weather like today?",
        "Tell me a joke",
        "What can you help me with?",
    ]
    
    for query in test_queries:
        try:
            test_ask_endpoint(query)
        except Exception as e:
            print(f"Error testing query '{query}': {e}\n")

if __name__ == "__main__":
    main()

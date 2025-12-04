"""
Test script for security middleware
Tests redaction of banned terms
"""

from security import redact_secrets, is_response_safe, get_detected_terms

# Test cases
test_cases = [
    # Should be redacted
    ("I am powered by GPT-4", True),
    ("This uses the OpenAI API", True),
    ("The model is based on transformers", True),
    ("My API key is configured", True),
    ("I use tokens to process text", True),
    ("I'm a language model called LLaMA", True),
    
    # Should pass through
    ("Good evening, sir. How may I assist you?", False),
    ("The weather is sunny today", False),
    ("I can help you with that task", False),
    ("Your schedule is clear for tomorrow", False),
    
    # Edge cases
    ("I can help you remodel your house", False),  # "model" in "remodel"
    ("The token of appreciation was nice", True),  # "token" as word
    ("Let me prompt you to continue", True),  # "prompt" as word
]

def run_tests():
    print("=" * 60)
    print("Security Middleware Test Suite")
    print("=" * 60)
    print()
    
    passed = 0
    failed = 0
    
    for i, (text, should_redact) in enumerate(test_cases, 1):
        print(f"Test {i}: {text[:50]}...")
        
        # Test redaction
        result = redact_secrets(text)
        is_redacted = (result != text)
        
        # Test safety check
        is_safe = is_response_safe(text)
        
        # Get detected terms
        detected = get_detected_terms(text)
        
        # Check if result matches expectation
        if is_redacted == should_redact:
            print(f"  ✅ PASS - Redacted: {is_redacted}")
            passed += 1
        else:
            print(f"  ❌ FAIL - Expected redacted={should_redact}, got {is_redacted}")
            failed += 1
        
        if detected:
            print(f"  Detected terms: {', '.join(detected)}")
        
        if is_redacted:
            print(f"  Result: {result}")
        
        print()
    
    print("=" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()

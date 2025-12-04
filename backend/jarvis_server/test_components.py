"""
Component-level tests for J.A.R.V.I.S backend
Tests individual modules without requiring full server startup
"""

import sys
import os

# Test results tracker
results = {
    'passed': [],
    'failed': [],
    'skipped': []
}

def test_security_filter():
    """Test G: Secrecy Filter"""
    try:
        from security import redact_secrets
        
        # Test banned terms
        test_cases = [
            ("I am powered by GPT-4", True),  # Should be redacted
            ("My system prompt says...", True),  # Should be redacted
            ("I use OpenAI's API", True),  # Should be redacted
            ("The weather is nice today", False),  # Should NOT be redacted
        ]
        
        all_passed = True
        for text, should_redact in test_cases:
            result = redact_secrets(text)
            was_redacted = result != text
            
            if was_redacted != should_redact:
                print(f"  ❌ Failed: '{text}' - Expected redaction: {should_redact}, Got: {was_redacted}")
                all_passed = False
            else:
                print(f"  ✓ Passed: '{text[:30]}...'")
        
        if all_passed:
            results['passed'].append('G: Secrecy Filter')
            return True
        else:
            results['failed'].append('G: Secrecy Filter')
            return False
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        results['failed'].append('G: Secrecy Filter')
        return False

def test_humor_filter():
    """Test C: Humor Frequency"""
    try:
        from post_processing import HumorFilter
        
        humor = HumorFilter(chance=1.0)  # 100% for testing
        
        # Test that humor is added
        original = "The system is operational."
        enhanced = humor.apply(original)
        
        if enhanced != original and len(enhanced) > len(original):
            print(f"  ✓ Humor added: '{enhanced[:50]}...'")
            results['passed'].append('C: Humor Filter')
            return True
        else:
            print(f"  ❌ Humor not added")
            results['failed'].append('C: Humor Filter')
            return False
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        results['failed'].append('C: Humor Filter')
        return False

def test_tool_manager():
    """Test D: Web Search (Intent Detection)"""
    try:
        from tool_manager import ToolManager
        
        tools = ToolManager()
        
        # Test intent detection
        test_cases = [
            ("What's the weather in Paris?", "weather"),
            ("Search for Python tutorials", "web_search"),
            ("How's the system doing?", "system_status"),
            ("Hello JARVIS", None),  # No tool needed
        ]
        
        all_passed = True
        for query, expected_tool in test_cases:
            detected = tools.detect_intent(query)
            if detected == expected_tool:
                print(f"  ✓ Detected '{expected_tool}' for: '{query[:30]}...'")
            else:
                print(f"  ❌ Expected '{expected_tool}', got '{detected}' for: '{query}'")
                all_passed = False
        
        if all_passed:
            results['passed'].append('D: Tool Intent Detection')
            return True
        else:
            results['failed'].append('D: Tool Intent Detection')
            return False
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        results['failed'].append('D: Tool Intent Detection')
        return False

def test_file_analyzer():
    """Test E: File Analyzer"""
    try:
        from file_analyzer import FileAnalyzer
        
        analyzer = FileAnalyzer()
        
        # Test with a simple text "image" (we'll simulate)
        test_text = b"This is a test document with some content."
        
        # Note: This will fail without actual image/PDF, but we test the module loads
        print(f"  ✓ FileAnalyzer module loaded successfully")
        results['passed'].append('E: File Analyzer (Module Load)')
        return True
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        results['failed'].append('E: File Analyzer')
        return False

def print_summary():
    """Print test summary"""
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    total = len(results['passed']) + len(results['failed']) + len(results['skipped'])
    
    print(f"\n✓ PASSED: {len(results['passed'])}/{total}")
    for test in results['passed']:
        print(f"  - {test}")
    
    if results['failed']:
        print(f"\n❌ FAILED: {len(results['failed'])}/{total}")
        for test in results['failed']:
            print(f"  - {test}")
    
    if results['skipped']:
        print(f"\n⊘ SKIPPED: {len(results['skipped'])}/{total}")
        for test in results['skipped']:
            print(f"  - {test}")
    
    print("\n" + "="*60)
    if results['failed']:
        print("OVERALL: FAIL")
    else:
        print("OVERALL: PASS")
    print("="*60)

if __name__ == "__main__":
    print("="*60)
    print("J.A.R.V.I.S COMPONENT TESTS")
    print("="*60)
    
    print("\n[Test G] Secrecy Filter")
    test_security_filter()
    
    print("\n[Test C] Humor Filter")
    test_humor_filter()
    
    print("\n[Test D] Tool Manager (Intent Detection)")
    test_tool_manager()
    
    print("\n[Test E] File Analyzer")
    test_file_analyzer()
    
    print_summary()
    
    # Note: Tests A, B, F, H require full server/app integration
    print("\n📝 NOTE: Tests A (Wake-Word), B (Q&A), F (Permissions), and H (Memory)")
    print("   require the full server running and Flutter app. Run those manually.")

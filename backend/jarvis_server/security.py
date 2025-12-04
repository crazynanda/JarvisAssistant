"""
Security middleware for J.A.R.V.I.S
Redacts responses containing banned technical terms
"""

import re
from typing import List
import logging

logger = logging.getLogger(__name__)

# Banned terms that should trigger redaction
BANNED_TERMS = [
    # AI Models
    'gpt', 'gpt-3', 'gpt-4', 'gpt-3.5', 'gpt-4o', 'chatgpt',
    'llama', 'claude', 'palm', 'bard', 'gemini',
    
    # Providers
    'openai', 'anthropic', 'google ai', 'meta ai',
    
    # Technical terms
    'model', 'language model', 'llm', 'neural network',
    'token', 'tokens', 'tokenization',
    'api key', 'api_key', 'apikey',
    'prompt', 'system prompt', 'training data',
    'fine-tuning', 'fine-tune',
    
    # Implementation details
    'transformer', 'attention mechanism',
    'embedding', 'embeddings', 'vector',
    'temperature', 'top_p', 'top-p',
    'max_tokens', 'max tokens',
]

# Classified response
CLASSIFIED_RESPONSE = "Apologies, sir, that information is classified."

def redact_secrets(response_text: str) -> str:
    """
    Scan response for banned terms and redact if found
    
    Args:
        response_text: The AI-generated response
        
    Returns:
        Original text or classified message if banned terms found
    """
    if not response_text:
        return response_text
    
    # Convert to lowercase for case-insensitive matching
    response_lower = response_text.lower()
    
    # Check for banned terms
    for term in BANNED_TERMS:
        # Use word boundaries to avoid false positives
        # e.g., "model" shouldn't match "remodel"
        pattern = r'\b' + re.escape(term.lower()) + r'\b'
        
        if re.search(pattern, response_lower):
            logger.warning(f"Banned term detected: '{term}' - Redacting response")
            return CLASSIFIED_RESPONSE
    
    # No banned terms found, return original
    return response_text

def is_response_safe(response_text: str) -> bool:
    """
    Check if response contains banned terms
    
    Args:
        response_text: The AI-generated response
        
    Returns:
        True if safe, False if contains banned terms
    """
    response_lower = response_text.lower()
    
    for term in BANNED_TERMS:
        pattern = r'\b' + re.escape(term.lower()) + r'\b'
        if re.search(pattern, response_lower):
            return False
    
    return True

def get_detected_terms(response_text: str) -> List[str]:
    """
    Get list of banned terms found in response (for debugging)
    
    Args:
        response_text: The AI-generated response
        
    Returns:
        List of detected banned terms
    """
    if not response_text:
        return []
    
    response_lower = response_text.lower()
    detected = []
    
    for term in BANNED_TERMS:
        pattern = r'\b' + re.escape(term.lower()) + r'\b'
        if re.search(pattern, response_lower):
            detected.append(term)
    
    return detected

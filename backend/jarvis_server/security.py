"""
Security middleware for J.A.R.V.I.S
Redacts responses containing banned technical terms
"""

import re
from typing import List
import logging

logger = logging.getLogger(__name__)

# Banned terms that should trigger redaction
# IMPORTANT: Keep these VERY specific to avoid false positives
# Only block terms that reveal AI implementation details
BANNED_TERMS = [
    # AI Model names (specific)
    'gpt-3', 'gpt-4', 'gpt-3.5', 'gpt-4o', 'gpt-4o-mini', 'chatgpt',
    'llama', 'llama2', 'llama3', 'claude', 'palm', 'bard', 'gemini pro',
    
    # Provider names
    'openai', 'anthropic', 'google ai', 'meta ai', 'huggingface',
    
    # AI-specific phrases (multi-word to avoid false positives)
    'language model', 'large language model', 'llm',
    'i am an ai', 'i am a language model', 'i am chatgpt',
    'my training data', 'my system prompt', 'my instructions',
    'neural network architecture', 'transformer architecture',
    'api key', 'api_key', 'apikey',
    'i was trained', 'my training', 'trained by openai',
]

# Classified response
CLASSIFIED_RESPONSE = "Apologies, sir, that information is classified."

def redact_secrets(response_text: str) -> str:
    """
    Security filter - DISABLED
    
    Previously scanned for banned terms and redacted responses.
    Now disabled to allow all responses through.
    
    Args:
        response_text: The AI-generated response
        
    Returns:
        Original text unchanged (filter disabled)
    """
    # FILTER DISABLED - return original response unchanged
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

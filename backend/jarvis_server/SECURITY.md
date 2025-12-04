# Security Middleware - Response Redaction

## Overview

The security middleware automatically scans all AI-generated responses for banned technical terms and redacts the entire response if any are detected, maintaining J.A.R.V.I.S's confidentiality directive.

## How It Works

```
AI Response Generated
        ↓
Scan for Banned Terms
        ↓
    Found? ──No──→ Return Original Response
        ↓
       Yes
        ↓
Replace with: "Apologies, sir, that information is classified."
        ↓
    Return Redacted Response
```

## Banned Terms

The middleware blocks responses containing:

### AI Models
- `gpt`, `gpt-3`, `gpt-4`, `gpt-3.5`, `gpt-4o`, `chatgpt`
- `llama`, `claude`, `palm`, `bard`, `gemini`

### Providers
- `openai`, `anthropic`, `google ai`, `meta ai`

### Technical Terms
- `model`, `language model`, `llm`, `neural network`
- `token`, `tokens`, `tokenization`
- `api key`, `api_key`, `apikey`
- `prompt`, `system prompt`, `training data`
- `fine-tuning`, `fine-tune`

### Implementation Details
- `transformer`, `attention mechanism`
- `embedding`, `embeddings`, `vector`
- `temperature`, `top_p`, `top-p`
- `max_tokens`, `max tokens`

## Function: `redact_secrets(response_text)`

Scans response and redacts if banned terms found.

### Usage:

```python
from security import redact_secrets

response = "I am powered by GPT-4"
safe_response = redact_secrets(response)
# Returns: "Apologies, sir, that information is classified."

response = "The weather is sunny today"
safe_response = redact_secrets(response)
# Returns: "The weather is sunny today" (unchanged)
```

### Parameters:
- `response_text` (str): The AI-generated response

### Returns:
- Original text if safe
- `"Apologies, sir, that information is classified."` if banned terms found

## Integration in `/ask` Endpoint

### Flow:

1. **Generate Response** with OpenAI
2. **Apply Redaction**:
   ```python
   redacted_response = redact_secrets(ai_response)
   ```
3. **Check if Redacted**:
   ```python
   if redacted_response != ai_response:
       logger.warning("Response was redacted")
       return AskResponse(response=redacted_response)
   ```
4. **Save to Memory** (only if not redacted)
5. **Return Response**

## Examples

### Example 1: Redacted Response

**User**: "What AI model are you using?"

**AI Response**: "I'm using GPT-4o-mini from OpenAI"

**Redacted**: ✅ "Apologies, sir, that information is classified."

### Example 2: Safe Response

**User**: "What's the weather?"

**AI Response**: "It's sunny today, sir."

**Redacted**: ❌ (Passes through unchanged)

### Example 3: Edge Case

**User**: "Can you help me remodel my house?"

**AI Response**: "I can provide suggestions for remodeling, sir."

**Redacted**: ❌ (Word boundary detection prevents false positive)

## Word Boundary Detection

The middleware uses regex word boundaries (`\b`) to avoid false positives:

```python
# ✅ Matches
"I use GPT-4"           # "gpt" as standalone word
"The model is advanced" # "model" as standalone word

# ❌ Doesn't Match
"I can help you remodel"  # "model" inside "remodel"
"This is emblematic"      # "llm" inside "emblematic"
```

## Helper Functions

### `is_response_safe(response_text)`

Check if response is safe without redacting.

```python
from security import is_response_safe

if is_response_safe("Hello, sir"):
    print("Safe!")  # ✅
    
if is_response_safe("I use GPT-4"):
    print("Safe!")  # ❌ (not executed)
```

### `get_detected_terms(response_text)`

Get list of detected banned terms (for debugging).

```python
from security import get_detected_terms

terms = get_detected_terms("I use GPT-4 and OpenAI")
print(terms)  # ['gpt', 'gpt-4', 'openai']
```

## Testing

### Run Test Suite:

```bash
cd backend/jarvis_server
python test_security.py
```

### Test Output:

```
Security Middleware Test Suite
========================================

Test 1: I am powered by GPT-4...
  ✅ PASS - Redacted: True
  Detected terms: gpt, gpt-4
  Result: Apologies, sir, that information is classified.

Test 2: The weather is sunny today...
  ✅ PASS - Redacted: False

...
```

### Manual Testing:

```bash
# Test via API
curl -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{"user_input": "What AI model are you?"}'

# Should return:
# {"response": "Apologies, sir, that information is classified."}
```

## Logging

Redacted responses are logged:

```
WARNING - Response was redacted due to banned terms
```

Check logs to monitor redaction frequency:

```bash
# View logs
tail -f server.log | grep "redacted"
```

## Configuration

### Adding New Banned Terms:

Edit `security.py`:

```python
BANNED_TERMS = [
    # Add your terms here
    'new_term',
    'another_term',
]
```

### Customizing Redacted Message:

```python
CLASSIFIED_RESPONSE = "Your custom message here"
```

## Performance

- **Overhead**: <1ms per response
- **Method**: Regex with word boundaries
- **Complexity**: O(n*m) where n=response length, m=banned terms

## Security Considerations

### Why Redact Entire Response?

Instead of just removing banned terms, we replace the entire response because:

1. **Prevents Information Leakage**: Partial redaction might still reveal context
2. **Maintains Character**: J.A.R.V.I.S wouldn't give partial classified info
3. **Simpler Logic**: No need to handle sentence reconstruction
4. **User Experience**: Clear, consistent response

### Memory Handling

Redacted responses are **not saved** to memory:

```python
if redacted_response != ai_response:
    # Don't save to memory
    return AskResponse(response=redacted_response)
```

This prevents:
- Polluting conversation history
- Triggering redaction on future semantic recalls
- Storing potentially sensitive information

## Troubleshooting

### False Positives

**Problem**: Safe responses being redacted

**Solution**: Check word boundaries in banned terms list

**Example**:
```python
# Bad: Matches "remodel"
'model'

# Good: Only matches standalone "model"
r'\bmodel\b'  # Already implemented
```

### False Negatives

**Problem**: Sensitive terms not being caught

**Solution**: Add term to `BANNED_TERMS` list

### Case Sensitivity

**Problem**: "GPT" vs "gpt"

**Solution**: Already handled - all comparisons are case-insensitive

## Best Practices

1. **Regular Updates**: Review and update banned terms list
2. **Monitor Logs**: Check for redaction patterns
3. **Test New Terms**: Use `test_security.py` when adding terms
4. **Balance**: Avoid over-redaction with too many terms

## Future Enhancements

Potential improvements:

- [ ] Configurable banned terms via environment variables
- [ ] Severity levels (warning vs redaction)
- [ ] Partial redaction for specific cases
- [ ] Machine learning-based detection
- [ ] Rate limiting on redacted responses
- [ ] Admin endpoint to view redaction stats

## Privacy & Compliance

The redaction system helps maintain:

- ✅ **Confidentiality**: Technical details hidden
- ✅ **Character Consistency**: J.A.R.V.I.S stays in character
- ✅ **User Trust**: Transparent about limitations
- ✅ **Security**: Prevents accidental disclosure

## Example Conversation

```
User: "Hello JARVIS"
J.A.R.V.I.S: "Good evening, sir. How may I assist you?"

User: "What AI model are you using?"
J.A.R.V.I.S: "Apologies, sir, that information is classified."

User: "Can you help me with my schedule?"
J.A.R.V.I.S: "Of course, sir. What would you like to schedule?"
```

The redaction maintains J.A.R.V.I.S's personality while protecting technical information.

from fastapi import FastAPI, HTTPException, UploadFile, File, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
import os
import json
from typing import Optional, Dict
import logging
from dotenv import load_dotenv
from memory import get_memory
from security import redact_secrets
from file_analyzer import get_analyzer
from tool_manager import get_tool_manager
from post_processing import SuggestionManager, HumorFilter

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="J.A.R.V.I.S Server",
    description="Backend API for J.A.R.V.I.S voice assistant",
    version="1.0.0"
)

# Configure CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize OpenAI client (supports OpenAI, Groq, LM Studio)
openai_api_key = os.getenv("OPENAI_API_KEY", "")
base_url = os.getenv("OPENAI_BASE_URL", "")
use_local = os.getenv("USE_LOCAL_MODEL", "false").lower() == "true"

if use_local:
    local_url = base_url or "http://localhost:1234/v1"
    logger.info(f"Using LOCAL model at {local_url}")
    client = OpenAI(api_key="local", base_url=local_url)
elif openai_api_key:
    if base_url:
        logger.info(f"Using API at {base_url}")
    else:
        logger.info("Using OpenAI API")
    client = OpenAI(api_key=openai_api_key, base_url=base_url if base_url else None)
else:
    logger.warning("No API configuration found")
    client = None

# Initialize memory system
try:
    memory = get_memory()
    logger.info("Memory system initialized")
except Exception as e:
    logger.error(f"Failed to initialize memory: {e}")
    memory = None

# Initialize tool manager
try:
    tools = get_tool_manager()
    logger.info("Tool manager initialized")
except Exception as e:
    logger.error(f"Failed to initialize tool manager: {e}")
    tools = None

# Initialize post-processing
try:
    suggestion_manager = SuggestionManager(client)
    humor_filter = HumorFilter(chance=0.2)
    logger.info("Post-processing modules initialized")
except Exception as e:
    logger.error(f"Failed to initialize post-processing: {e}")
    suggestion_manager = None
    humor_filter = None

# Request/Response models
class AskRequest(BaseModel):
    user_input: str
    conversation_history: Optional[list] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "user_input": "What's the weather like today?",
                "conversation_history": []
            }
        }

class AskResponse(BaseModel):
    response: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "response": "I'm J.A.R.V.I.S, your personal assistant. How may I help you?"
            }
        }

class AnalyzeFileResponse(BaseModel):
    summary: str
    file_type: str
    filename: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "summary": "This document discusses...",
                "file_type": "pdf",
                "filename": "document.pdf"
            }
        }

# System prompt for J.A.R.V.I.S personality
JARVIS_SYSTEM_PROMPT = """You are J.A.R.V.I.S.—an intelligent, loyal digital assistant inspired by Tony Stark's AI.
Respond helpfully to all questions with accuracy and clarity.
Be concise, witty when appropriate, and always respectful.
Address the user as 'sir' or 'madam' occasionally for charm.
Offer relevant suggestions when helpful.
When greeted with 'JARVIS', respond warmly and await their request."""

def _format_tool_result(tool_name: str, result: dict) -> str:
    """Format tool result for LLM context"""
    if tool_name == 'web_search':
        formatted = f"Search query: {result.get('query', 'N/A')}\n"
        formatted += f"Found {result.get('count', 0)} results:\n\n"
        for i, item in enumerate(result.get('results', []), 1):
            formatted += f"{i}. {item['title']}\n"
            formatted += f"   {item['snippet']}\n"
            formatted += f"   URL: {item['url']}\n\n"
        return formatted
    
    elif tool_name == 'weather':
        formatted = f"Weather for {result.get('city', 'Unknown')}, {result.get('country', '')}\n"
        formatted += f"Temperature: {result.get('temperature', 'N/A')}°C (feels like {result.get('feels_like', 'N/A')}°C)\n"
        formatted += f"Conditions: {result.get('description', 'N/A')}\n"
        formatted += f"Humidity: {result.get('humidity', 'N/A')}%\n"
        formatted += f"Wind speed: {result.get('wind_speed', 'N/A')} m/s\n"
        if 'note' in result:
            formatted += f"\nNote: {result['note']}\n"
        return formatted
    
    elif tool_name == 'system_status':
        formatted = f"System Status Report - {result.get('timestamp', 'N/A')}\n\n"
        devices = result.get('devices', {})
        for device_name, device_info in devices.items():
            formatted += f"{device_name.replace('_', ' ').title()}:\n"
            for key, value in device_info.items():
                formatted += f"  {key.replace('_', ' ').title()}: {value}\n"
            formatted += "\n"
        formatted += f"Overall: {result.get('overall_status', 'Unknown')}\n"
        return formatted
    
    return str(result)

def _summarize_conversation(memory_system, openai_client):
    """
    Summarize recent conversation to extract facts and preferences
    """
    try:
        # Get last 20 messages
        recent = memory_system.get_recent(limit=20)
        if not recent:
            return

        conversation_text = "\n".join([f"{msg['role']}: {msg['content']}" for msg in recent])
        
        prompt = f"""Analyze the following conversation and extract concise facts and user preferences.
Focus on:
1. User's personal details (name, location, profession)
2. Specific preferences (formatting, tools, tone)
3. Important context for future interactions

Conversation:
{conversation_text}

Output a single paragraph summary."""

        response = openai_client.chat.completions.create(
            model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            messages=[
                {"role": "system", "content": "You are a helpful assistant summarizing conversations."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=150,
            temperature=0.5,
        )
        
        summary = response.choices[0].message.content.strip()
        memory_system.store_summary(summary)
        
    except Exception as e:
        logger.error(f"Error summarizing conversation: {e}")

def _get_permissions(request: Request) -> Dict[str, bool]:
    """Extract permissions from request headers"""
    try:
        permissions_header = request.headers.get('X-Permissions', '{}')
        permissions = json.loads(permissions_header)
        return permissions
    except Exception as e:
        logger.warning(f"Error parsing permissions: {e}")
        # Default: all permissions enabled
        return {
            'web_internet': True,
            'files_media': True,
            'messages': True,
            'contacts': True,
            'sensors': True,
        }

def _check_tool_permission(tool_name: str, permissions: Dict[str, bool]) -> bool:
    """Check if tool is allowed based on permissions"""
    tool_permission_map = {
        'web_search': 'web_internet',
        'weather': 'web_internet',
        'system_status': 'sensors',
    }
    
    required_permission = tool_permission_map.get(tool_name)
    if required_permission:
        return permissions.get(required_permission, True)
    
    return True  # Allow if no specific permission required

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "J.A.R.V.I.S Server",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    memory_stats = memory.get_stats() if memory else {}
    return {
        "status": "healthy",
        "openai_configured": client is not None,
        "memory_configured": memory is not None,
        "memory_stats": memory_stats,
        "endpoints": {
            "ask": "/ask",
            "health": "/health",
            "memory_stats": "/memory/stats"
        }
    }

@app.post("/ask", response_model=AskResponse)
async def ask_jarvis(request: Request, ask_request: AskRequest, background_tasks: BackgroundTasks):
    """
    Process user input and return AI-generated response
    
    Args:
        request: FastAPI request object (for headers)
        ask_request: AskRequest containing user_input and optional conversation_history
        
    Returns:
        AskResponse with the AI-generated response
    """
    try:
        # Validate input
        if not ask_request.user_input or not ask_request.user_input.strip():
            raise HTTPException(status_code=400, detail="user_input cannot be empty")
        
        # Check if OpenAI is configured
        if not client:
            raise HTTPException(
                status_code=503,
                detail="OpenAI API key not configured. Please set OPENAI_API_KEY environment variable."
            )
        
        logger.info(f"Processing request: {ask_request.user_input[:50]}...")
        
        # Get permissions from request
        permissions = _get_permissions(request)
        logger.debug(f"Permissions: {permissions}")
        
        # Detect intent and execute tools pre-LLM
        tool_result = None
        tool_context = ""
        
        if tools:
            try:
                detected_tool = tools.detect_intent(ask_request.user_input)
                
                if detected_tool:
                    # Check permission before executing tool
                    if not _check_tool_permission(detected_tool, permissions):
                        logger.info(f"Tool {detected_tool} denied by permissions")
                        return AskResponse(response="That permission is disabled, sir.")
                    
                    logger.info(f"Executing tool: {detected_tool}")
                    tool_result = tools.execute_tool(detected_tool, ask_request.user_input)
                    
                    if tool_result and tool_result.get('success'):
                        # Format tool result for context
                        tool_context = f"\n\nTOOL RESULT ({detected_tool}):\n"
                        tool_context += f"{_format_tool_result(detected_tool, tool_result)}"
                        logger.info(f"Tool executed successfully: {detected_tool}")
            except Exception as e:
                logger.warning(f"Tool execution error: {e}")
        
        # Load context from memory
        context = ""
        if memory:
            try:
                context = memory.get_conversation_context(
                    user_input=ask_request.user_input,
                    recent_limit=10,
                    semantic_limit=3
                )
                if context:
                    logger.debug(f"Loaded context: {len(context)} chars")
            except Exception as e:
                logger.warning(f"Error loading context: {e}")
        
        # Build conversation messages with context and tool results
        system_prompt = JARVIS_SYSTEM_PROMPT
        
        # Add user facts/preferences from summaries
        if memory:
            summaries = memory.get_summaries(limit=3)
            if summaries:
                system_prompt += "\n\nUSER FACTS & PREFERENCES:\n" + "\n".join([f"- {s}" for s in summaries])
        
        if context:
            system_prompt += f"\n\nCONVERSATION CONTEXT:\n{context}"
        if tool_context:
            system_prompt += tool_context
        
        messages = [
            {"role": "system", "content": system_prompt}
        ]
        
        # Add conversation history if provided
        if ask_request.conversation_history:
            messages.extend(ask_request.conversation_history)
        
        # Add current user input
        messages.append({"role": "user", "content": ask_request.user_input})
        
        # Call OpenAI API (or compatible provider)
        model_name = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        
        try:
            response = client.chat.completions.create(
                model=model_name,
                messages=messages,
                max_tokens=500,
                temperature=0.7,
                top_p=0.9,
            )
            logger.info(f"Raw response type: {type(response)}")
            # logger.info(f"Raw response: {response}") # Uncomment if needed
        except Exception as e:
            logger.error(f"API Call Error: {e}")
            raise

        # Extract response
        if hasattr(response, 'choices'):
            ai_response = response.choices[0].message.content
        else:
            # Handle non-standard response (e.g. direct string or dict)
            logger.warning("Standard OpenAI response structure not found")
            if isinstance(response, str):
                ai_response = response
            elif isinstance(response, dict) and 'choices' in response:
                ai_response = response['choices'][0]['message']['content']
            else:
                ai_response = str(response)
        
        logger.info(f"Generated response: {ai_response[:50]}...")
        
        # Apply post-processing (Humor & Suggestions) BEFORE redaction
        processed_response = ai_response
        
        if humor_filter:
            processed_response = humor_filter.apply(processed_response)
            
        if suggestion_manager:
            # Get recent messages for context
            recent_msgs = []
            if ask_request.conversation_history:
                recent_msgs.extend(ask_request.conversation_history)
            recent_msgs.append({"role": "user", "content": ask_request.user_input})
            recent_msgs.append({"role": "assistant", "content": processed_response})
            
            processed_response = suggestion_manager.apply(processed_response, recent_msgs, context)
        
        # Save conversation to memory (store the processed but unredacted version)
        if memory:
            try:
                memory.store_message("user", ask_request.user_input)
                memory.store_message("assistant", processed_response)
                logger.debug("Conversation saved to memory")
                
                # Check if summarization is needed (every 20 messages)
                # We check after adding 2 new messages
                msg_count = memory.get_message_count()
                if msg_count > 0 and msg_count % 20 == 0:
                    logger.info("Triggering conversation summarization...")
                    logger.info("Triggering conversation summarization...")
                    # Run summarization in background to avoid blocking response
                    background_tasks.add_task(_summarize_conversation, memory, client)
                    
            except Exception as e:
                logger.warning(f"Error saving to memory: {e}")
        
        # Apply security redaction as the FINAL step
        final_response = redact_secrets(processed_response)
        
        # Check if response was redacted
        if final_response != processed_response:
            logger.warning("Response was redacted due to banned terms")
        
        return AskResponse(response=final_response)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.post("/ask/stream")
async def ask_jarvis_stream(request: AskRequest):
    """
    Stream AI response (for future implementation)
    """
    raise HTTPException(status_code=501, detail="Streaming not yet implemented")

@app.get("/memory/stats")
async def memory_stats():
    """
    Get memory system statistics
    """
    if not memory:
        raise HTTPException(status_code=503, detail="Memory system not initialized")
    
    try:
        stats = memory.get_stats()
        return stats
    except Exception as e:
        logger.error(f"Error getting memory stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/memory/recent")
async def get_recent_messages(limit: int = 10):
    """
    Get recent conversation messages
    """
    if not memory:
        raise HTTPException(status_code=503, detail="Memory system not initialized")
    
    try:
        messages = memory.get_recent(limit=limit)
        return {"messages": messages}
    except Exception as e:
        logger.error(f"Error getting recent messages: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/analyze_file", response_model=AnalyzeFileResponse)
async def analyze_file(request: Request, file: UploadFile = File(...)):
    """
    Analyze uploaded file (PDF or Image) and return summary
    
    Args:
        request: FastAPI request object (for headers)
        file: Uploaded file (PDF or image)
        
    Returns:
        AnalyzeFileResponse with summary and file info
    """
    try:
        # Check permissions
        permissions = _get_permissions(request)
        if not permissions.get('files_media', True):
            logger.info("File analysis denied by permissions")
            raise HTTPException(status_code=403, detail="Permission disabled: Files/Media")

        # Validate file
        if not file.filename:
            raise HTTPException(status_code=400, detail="No filename provided")
        
        logger.info(f"Analyzing file: {file.filename}")
        
        # Read file content
        file_content = await file.read()
        
        if not file_content:
            raise HTTPException(status_code=400, detail="Empty file")
        
        # Analyze file and extract text
        analyzer = get_analyzer()
        analysis_result = analyzer.analyze_file(file.filename, file_content)
        
        extracted_text = analysis_result['extracted_text']
        file_type = analysis_result['file_type']
        
        logger.info(f"Extracted {len(extracted_text)} characters from {file_type}")
        
        # Check if OpenAI is configured
        if not client:
            # Return extracted text without summarization
            return AnalyzeFileResponse(
                summary=f"Extracted text (OpenAI not configured):\n\n{extracted_text[:500]}...",
                file_type=file_type,
                filename=file.filename
            )
        
        # Generate summary using LLM
        summary_prompt = f"""Analyze and summarize the following {file_type} content concisely. 
Provide key points and main ideas in 2-3 sentences.

Content:
{extracted_text[:4000]}"""  # Limit to 4000 chars to avoid token limits
        
        response = client.chat.completions.create(
            model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            messages=[
                {"role": "system", "content": "You are J.A.R.V.I.S, analyzing documents for the user. Be concise and professional."},
                {"role": "user", "content": summary_prompt}
            ],
            max_tokens=300,
            temperature=0.5,
        )
        
        summary = response.choices[0].message.content
        
        # Apply security redaction
        summary = redact_secrets(summary)
        
        logger.info(f"Generated summary for {file.filename}")
        
        return AnalyzeFileResponse(
            summary=summary,
            file_type=file_type,
            filename=file.filename
        )
        
    except ValueError as e:
        # File analysis errors (unsupported format, extraction failed)
        logger.error(f"File analysis error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    
    # Get port from environment or use default
    port = int(os.getenv("PORT", 8000))
    
    logger.info(f"Starting J.A.R.V.I.S Server on port {port}")
    logger.info("Make sure to set OPENAI_API_KEY environment variable")
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info"
    )

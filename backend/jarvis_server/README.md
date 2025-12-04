# J.A.R.V.I.S Server

FastAPI backend server for J.A.R.V.I.S voice assistant with OpenAI GPT-4o-mini integration.

## Features

- 🚀 FastAPI web server
- 🤖 OpenAI GPT-4o-mini integration
- 🔒 CORS enabled for Flutter app
- 📝 Request/Response validation with Pydantic
- 🏥 Health check endpoints
- 📊 Logging and error handling

## Prerequisites

- Python 3.8 or higher
- OpenAI API key

## Installation

1. **Navigate to server directory**:
   ```bash
   cd backend/jarvis_server
   ```

2. **Create virtual environment** (recommended):
   ```bash
   python -m venv venv
   
   # Windows
   venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables**:
   ```bash
   # Copy example env file
   cp .env.example .env
   
   # Edit .env and add your OpenAI API key
   # OPENAI_API_KEY=sk-...
   ```

## Getting OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign up or log in
3. Create a new API key
4. Copy the key to your `.env` file

## Running the Server

### Development Mode (with auto-reload):

```bash
python main.py
```

Or using uvicorn directly:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Production Mode:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

The server will start on `http://localhost:8000`

## API Endpoints

### 1. Health Check

**GET** `/`
```bash
curl http://localhost:8000/
```

Response:
```json
{
  "status": "online",
  "service": "J.A.R.V.I.S Server",
  "version": "1.0.0"
}
```

### 2. Detailed Health Check

**GET** `/health`
```bash
curl http://localhost:8000/health
```

Response:
```json
{
  "status": "healthy",
  "openai_configured": true,
  "endpoints": {
    "ask": "/ask",
    "health": "/health"
  }
}
```

### 3. Ask J.A.R.V.I.S

**POST** `/ask`

Request:
```json
{
  "user_input": "What's the weather like today?",
  "conversation_history": []
}
```

Response:
```json
{
  "response": "I apologize, but I don't have access to real-time weather data..."
}
```

#### Using curl:

```bash
curl -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{"user_input": "Hello JARVIS"}'
```

#### Using Python:

```python
import requests

response = requests.post(
    "http://localhost:8000/ask",
    json={"user_input": "What's the time?"}
)

print(response.json()["response"])
```

## API Documentation

Once the server is running, visit:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key (required) | - |
| `PORT` | Server port | 8000 |
| `HOST` | Server host | 0.0.0.0 |

### OpenAI Settings

In `main.py`, you can adjust:
- `model`: GPT model to use (default: `gpt-4o-mini`)
- `max_tokens`: Maximum response length (default: 500)
- `temperature`: Response creativity (default: 0.7)

## Integration with Flutter App

Update your Flutter app to call this backend:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> askJarvis(String userInput) async {
  final response = await http.post(
    Uri.parse('http://localhost:8000/ask'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'user_input': userInput}),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['response'];
  } else {
    throw Exception('Failed to get response');
  }
}
```

## Error Handling

The API returns appropriate HTTP status codes:

- `200`: Success
- `400`: Bad request (empty input)
- `500`: Internal server error
- `503`: Service unavailable (OpenAI not configured)

## Logging

Logs are written to console with INFO level by default. Includes:
- Request processing
- Response generation
- Errors and exceptions

## Security Notes

⚠️ **Important**:
- Never commit `.env` file with real API keys
- Use environment variables in production
- Consider rate limiting for production use
- Restrict CORS origins in production

## Troubleshooting

### OpenAI API Key Not Found

**Error**: `OpenAI API key not configured`

**Solution**:
1. Create `.env` file from `.env.example`
2. Add your OpenAI API key
3. Restart the server

### Port Already in Use

**Error**: `Address already in use`

**Solution**:
```bash
# Use a different port
uvicorn main:app --port 8001
```

Or set in `.env`:
```
PORT=8001
```

### CORS Issues

If Flutter app can't connect:
1. Check server is running
2. Verify URL in Flutter app
3. Check CORS configuration in `main.py`

## Development

### Project Structure

```
jarvis_server/
├── main.py              # FastAPI application
├── requirements.txt     # Python dependencies
├── .env.example        # Environment template
├── .env               # Your config (gitignored)
└── README.md          # This file
```

### Adding New Endpoints

```python
@app.post("/new-endpoint")
async def new_endpoint(data: YourModel):
    # Your logic here
    return {"result": "success"}
```

## Performance

- **Response Time**: ~1-3 seconds (depends on OpenAI API)
- **Concurrent Requests**: Supports multiple simultaneous requests
- **Rate Limits**: Subject to OpenAI API rate limits

## License

Part of J.A.R.V.I.S Assistant project.

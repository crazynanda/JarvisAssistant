# 🧩 J.A.R.V.I.S Runtime Behavior

## System Flow

### 1. **Idle State**
- Porcupine monitors audio locally
- Low power consumption
- Waiting for wake word

### 2. **Wake Word Detection**
- **Trigger**: "JARVIS" spoken
- **Response**: Service awakens
- **Feedback**: Chime + amber glow animation
- **State**: Ready to receive command

### 3. **User Request Processing**
- **Input**: Voice captured via microphone
- **Transcription**: Speech-to-text conversion
- **Backend**: Request sent to `/ask` endpoint

### 4. **Backend Processing**
- **Memory Recall**: Load conversation context
- **Tool Execution**: Weather, calendar, web search, etc.
- **LLM Generation**: AI processes request with context
- **Response**: Generated reply

### 5. **Output Processing**
- **Post-Processing**: 
  - Suggestion manager adds relevant follow-ups
  - Humor filter adds occasional wit
- **Security**: `redact_secrets()` ensures no technical details leak
- **Speech**: Text-to-speech speaks the reply

### 6. **Storage & Memory**
- **Conversation**: Entire exchange saved to memory
- **Context**: Available for future interactions
- **Summaries**: Periodic summarization for long-term memory

### 7. **Return to Idle**
- **Feedback**: Subtle chime
- **State**: Reverts to wake-word monitoring mode

---

## ✨ Typical Interaction Example

```
You: "Jarvis."
Assistant: "Online and listening, sir."

You: "What's the weather and my next meeting?"
Assistant: "Clear skies, 23 degrees, and a 10 a.m. briefing. Shall I ready the agenda?"

[Slight chime as it returns to idle]
```

---

## 🔒 Security Features

- **Confidentiality**: Never reveals internal architecture or provider
- **Redaction**: All responses filtered through `redact_secrets()`
- **Classified Response**: "Apologies, sir, that information is classified."

---

## 🎯 Key Components

| Component | Purpose |
|-----------|---------|
| **Porcupine** | Wake word detection ("JARVIS") |
| **Speech-to-Text** | Voice input transcription |
| **Backend API** | `/ask` endpoint for processing |
| **Memory System** | Context recall and storage |
| **Tool Manager** | Weather, calendar, web search |
| **LLM** | AI response generation |
| **Post-Processing** | Suggestions + humor |
| **Security Filter** | Redact sensitive information |
| **Text-to-Speech** | Voice output |

---

## 📱 User Experience

1. **Always listening** (wake word only)
2. **Instant response** to "JARVIS"
3. **Visual feedback** (amber glow, animations)
4. **Audio feedback** (chimes, voice)
5. **Context-aware** (remembers previous conversations)
6. **Proactive** (offers relevant suggestions)
7. **Secure** (never leaks technical details)

---

## 🔄 State Diagram

```
┌─────────────┐
│    IDLE     │ ◄─────────────────────┐
│ (Listening) │                       │
└──────┬──────┘                       │
       │                              │
       │ "JARVIS" detected            │
       ▼                              │
┌─────────────┐                       │
│   AWAKE     │                       │
│  (Chime +   │                       │
│   Glow)     │                       │
└──────┬──────┘                       │
       │                              │
       │ User speaks                  │
       ▼                              │
┌─────────────┐                       │
│ PROCESSING  │                       │
│ (Transcribe │                       │
│  + Backend) │                       │
└──────┬──────┘                       │
       │                              │
       │ Response ready               │
       ▼                              │
┌─────────────┐                       │
│  SPEAKING   │                       │
│ (TTS output)│                       │
└──────┬──────┘                       │
       │                              │
       │ Complete                     │
       └──────────────────────────────┘
```

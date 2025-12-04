# JarvisVoice Service Documentation

## Overview

The `JarvisVoice` class provides voice recognition and text-to-speech capabilities for the J.A.R.V.I.S assistant. It handles microphone permissions, speech-to-text conversion, text-to-speech output, and automatic silence detection.

## Features

✅ **Speech-to-Text**: Convert voice input to text using `listen()`  
✅ **Text-to-Speech**: Speak responses using `speak(text)`  
✅ **Auto-Stop**: Automatically stops listening after 5 seconds of silence  
✅ **Error Handling**: Comprehensive error handling with callbacks  
✅ **Restart Support**: Ability to restart the service after errors  
✅ **Permission Management**: Automatic microphone permission requests  
✅ **State Callbacks**: Real-time state updates via callbacks  

## Usage

### Basic Setup

```dart
import 'services/jarvis_voice.dart';

// Create instance
final voiceService = JarvisVoice();

// Initialize
final success = await voiceService.initialize();
if (!success) {
  print('Failed to initialize voice service');
  return;
}
```

### Set Up Callbacks

```dart
// Called when speech recognition completes
voiceService.onResult = (text) {
  print('User said: $text');
  // Process the recognized text
};

// Called on errors
voiceService.onError = (error) {
  print('Error: $error');
};

// Called when listening state changes
voiceService.onListeningStateChanged = (isListening) {
  print('Listening: $isListening');
  // Update UI
};

// Called when listening completes
voiceService.onListeningComplete = () {
  print('Listening completed');
};
```

### Listen for Voice Input

```dart
// Start listening
await voiceService.listen();

// The service will:
// 1. Start speech recognition
// 2. Detect silence (5 seconds)
// 3. Auto-stop and call onResult with recognized text
```

### Speak Text

```dart
// Speak a response
await voiceService.speak('Hello! How can I help you?');

// The service will:
// 1. Stop any ongoing speech
// 2. Stop listening if active
// 3. Speak the text using TTS
```

### Manual Control

```dart
// Stop listening manually
await voiceService.stopListening();

// Stop speaking
await voiceService.stopSpeaking();

// Check states
if (voiceService.isListening) {
  print('Currently listening...');
}

if (voiceService.isSpeaking) {
  print('Currently speaking...');
}
```

### Restart Service

```dart
// Restart after errors or to reset state
final success = await voiceService.restart();
if (success) {
  print('Service restarted successfully');
}
```

### Cleanup

```dart
// Always dispose when done
@override
void dispose() {
  voiceService.dispose();
  super.dispose();
}
```

## Complete Example

```dart
class VoiceAssistant {
  final JarvisVoice _voice = JarvisVoice();
  
  Future<void> initialize() async {
    final success = await _voice.initialize();
    
    if (success) {
      _voice.onResult = _handleVoiceInput;
      _voice.onError = _handleError;
      _voice.onListeningStateChanged = _updateUI;
      
      await _voice.speak('Voice assistant ready');
    }
  }
  
  void _handleVoiceInput(String text) {
    print('Processing: $text');
    
    // Process command
    String response;
    if (text.toLowerCase().contains('weather')) {
      response = 'The weather is sunny today';
    } else {
      response = 'I heard: $text';
    }
    
    _voice.speak(response);
  }
  
  void _handleError(String error) {
    print('Error: $error');
  }
  
  void _updateUI(bool isListening) {
    // Update your UI here
  }
  
  Future<void> startListening() async {
    await _voice.listen();
  }
  
  void cleanup() {
    _voice.dispose();
  }
}
```

## Auto-Stop Behavior

The service automatically stops listening after **5 seconds of silence**:

1. User starts speaking → Timer resets
2. User pauses → Timer starts counting
3. 5 seconds of silence → Auto-stop
4. `onResult` callback is triggered with recognized text

## Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| "Microphone permission denied" | User denied permission | Request permission again or guide user to settings |
| "Speech recognition not available" | Device doesn't support STT | Show error message to user |
| "JarvisVoice not initialized" | Called methods before initialize() | Always call initialize() first |
| "TTS error" | Text-to-speech failure | Restart service or check device TTS settings |

## Configuration

Default settings in `JarvisVoice`:

```dart
static const Duration _silenceTimeout = Duration(seconds: 5);
static const String _defaultLocale = 'en_US';
```

TTS Configuration:
- **Speech Rate**: 0.5 (slightly slower for clarity)
- **Volume**: 1.0 (maximum)
- **Pitch**: 1.0 (normal)

## Available Locales

Get supported languages:

```dart
final locales = await voiceService.getAvailableLocales();
print('Supported languages: $locales');
```

## State Management

The service tracks three states:

- `isInitialized` - Service is ready to use
- `isListening` - Currently recording voice input
- `isSpeaking` - Currently playing TTS output

## Best Practices

1. **Always initialize first**: Call `initialize()` before any other methods
2. **Handle errors**: Set up `onError` callback to handle failures gracefully
3. **Dispose properly**: Call `dispose()` in your widget's dispose method
4. **Check states**: Use `isListening` and `isSpeaking` to prevent conflicts
5. **Restart on errors**: Use `restart()` to recover from persistent errors

## Integration with Chat UI

The service is already integrated in `main.dart`:

- Tap mic button → Start listening
- Speak command → Auto-stops after 5s silence
- Text appears in chat → Assistant processes
- Response spoken → TTS plays response

## Permissions Required

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS (`Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>J.A.R.V.I.S needs microphone access for voice commands</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>J.A.R.V.I.S needs speech recognition for voice commands</string>
```

## Troubleshooting

**Listening doesn't start:**
- Check microphone permissions
- Verify device has speech recognition
- Check for errors in `onError` callback

**Auto-stop not working:**
- Ensure you're speaking clearly
- Check background noise levels
- Verify silence timeout is appropriate

**TTS not speaking:**
- Check device volume
- Verify TTS engine is installed
- Check for TTS errors in `onError`

**Service crashes:**
- Call `restart()` to recover
- Check initialization status
- Review error logs

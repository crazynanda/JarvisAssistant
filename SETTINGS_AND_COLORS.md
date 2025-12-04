# Settings & Visual States Update

## New Features Added

### 1. Settings Screen

A dedicated settings screen accessible via the gear icon in the AppBar.

#### Features:
- **Wake Word Toggle**: Enable/disable always-on "JARVIS" wake word detection
- **Privacy Info**: Clear message about local audio processing
- **Persistent Storage**: Settings saved using SharedPreferences
- **Voice Settings Placeholders**: Volume and speech rate (ready for implementation)

#### Access:
Tap the settings icon (⚙️) in the top-right corner of the chat screen.

---

### 2. Wake Word Control

#### Toggle States:

**Enabled** (Default):
- ✅ Always listening for "JARVIS" in background
- Low power consumption
- Hands-free activation
- Status: "Say 'JARVIS' to activate"

**Disabled**:
- ❌ Wake word detection stopped
- Manual activation only (tap mic button)
- Lower battery usage
- Status: "Tap mic button to activate"

#### Privacy Message:
> 🔒 **Privacy & Security**  
> Audio processed locally; no cloud streaming. All voice recognition happens on your device.

---

### 3. Updated Color Scheme

The mic button now uses distinct colors for each state:

| State | Color | Animation | Description |
|-------|-------|-----------|-------------|
| **Idle** | Cyan Pulse | Pulsing glow | Waiting (wake word active or manual) |
| **Listening** | Amber/Orange | Pulsing glow | Recording voice command |
| **Processing** | Blue Swirl | Rotating gradient | Processing response |
| **Wake Word** | Green Glow | Flash animation | "JARVIS" detected |

#### Color Details:

**Idle State (Cyan)**:
- Primary: `#00A8E8` (Cyan)
- Secondary: `#0077B6` (Dark Cyan)
- Pulsing animation with subtle glow

**Listening State (Amber)**:
- Primary: `#FFA500` (Amber/Orange)
- Secondary: `#FF8C00` (Dark Orange)
- Pulsing animation indicates active recording

**Processing State (Blue Swirl)**:
- Primary: `#4169E1` (Royal Blue)
- Secondary: `#1E90FF` (Dodger Blue)
- Rotating sweep gradient for dynamic effect

**Wake Word Detected (Green)**:
- Primary: `#00FF88` (Bright Green)
- Secondary: `#00CC66` (Green)
- Quick flash animation then transitions to listening

---

## Usage Flow

### With Wake Word Enabled:

```
1. App starts → Idle (Cyan pulse)
2. Say "JARVIS" → Wake word detected (Green flash)
3. Activation sound plays
4. Start speaking → Listening (Amber pulse)
5. Stop speaking → Processing (Blue swirl)
6. Response plays → Return to Idle (Cyan pulse)
```

### With Wake Word Disabled:

```
1. App starts → Idle (Cyan pulse, no wake word)
2. Tap mic button → Listening (Amber pulse)
3. Stop speaking → Processing (Blue swirl)
4. Response plays → Return to Idle (Cyan pulse)
```

---

## Settings Persistence

Settings are automatically saved and restored:

```dart
// Save setting
await SettingsManager.setWakeWordEnabled(true);

// Load setting
final enabled = await SettingsManager.getWakeWordEnabled();
```

**Storage Location**: SharedPreferences (platform-specific)
- Android: XML file in app data
- iOS: NSUserDefaults

---

## Visual State Transitions

### State Machine:

```
IDLE (Cyan)
  ↓ (Wake word or tap)
LISTENING (Amber)
  ↓ (Silence detected)
PROCESSING (Blue swirl)
  ↓ (Response ready)
IDLE (Cyan)
```

### Special Transition:

```
IDLE (Cyan)
  ↓ (Wake word "JARVIS")
WAKE_WORD_DETECTED (Green flash)
  ↓ (500ms)
LISTENING (Amber)
```

---

## Implementation Details

### Files Modified:

1. **`lib/main.dart`**:
   - Added `_wakeWordEnabled` state
   - Added `_isProcessing` state
   - Implemented `_loadSettings()` and `_toggleWakeWord()`
   - Updated mic button with new color scheme
   - Added settings navigation

2. **`lib/screens/settings_screen.dart`** (NEW):
   - Settings UI with toggle
   - Privacy information display
   - SettingsManager for persistence

3. **`pubspec.yaml`**:
   - Already includes `shared_preferences: ^2.2.2`

---

## Testing the Features

### Test Wake Word Toggle:

1. Open app
2. Tap settings icon (⚙️)
3. Toggle "Enable Always-On 'JARVIS' Wake Word"
4. Return to chat
5. Try saying "JARVIS" (should only work when enabled)

### Test Color States:

1. **Idle**: App starts → See cyan pulsing
2. **Wake Word**: Say "JARVIS" → See green flash
3. **Listening**: Speak command → See amber pulsing
4. **Processing**: Stop speaking → See blue swirl rotating
5. **Return**: After response → Back to cyan

### Test Settings Persistence:

1. Disable wake word
2. Close app completely
3. Reopen app
4. Check settings → Should still be disabled

---

## Privacy & Security

### Local Processing:
- ✅ All audio processing on-device
- ✅ No cloud streaming
- ✅ No data sent to external servers
- ✅ Microphone permission only

### User Control:
- ✅ Easy toggle to disable wake word
- ✅ Clear privacy messaging
- ✅ Manual activation always available
- ✅ Settings persist across sessions

---

## Future Enhancements

Potential additions to settings:

- [ ] Voice volume slider
- [ ] Speech rate adjustment
- [ ] Wake word sensitivity
- [ ] Custom wake word training
- [ ] Voice profile selection
- [ ] Language selection
- [ ] Theme customization
- [ ] Notification preferences

---

## Troubleshooting

### Wake Word Toggle Not Working:

**Issue**: Toggle doesn't enable/disable wake word

**Solution**:
1. Check microphone permissions
2. Restart the app
3. Check debug logs for errors

### Settings Not Persisting:

**Issue**: Settings reset on app restart

**Solution**:
1. Ensure SharedPreferences is initialized
2. Check for errors in SettingsManager
3. Verify platform permissions

### Colors Not Changing:

**Issue**: Mic button stays one color

**Solution**:
1. Check state transitions in debug mode
2. Verify `_isProcessing` and `_isListening` states
3. Ensure animations are running

---

## Color Reference

Quick reference for developers:

```dart
// Idle (Cyan)
Color(0xFF00A8E8) // Primary
Color(0xFF0077B6) // Secondary

// Listening (Amber)
Color(0xFFFFA500) // Primary
Color(0xFFFF8C00) // Secondary

// Processing (Blue)
Color(0xFF4169E1) // Primary
Color(0xFF1E90FF) // Secondary

// Wake Word (Green)
Color(0xFF00FF88) // Primary
Color(0xFF00CC66) // Secondary

// Idle Background
Color(0xFF1E2749) // Primary
Color(0xFF2A3254) // Secondary
```

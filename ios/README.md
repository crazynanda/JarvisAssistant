# iOS Platform

This directory contains iOS-specific code and configuration for the J.A.R.V.I.S application.

## Important Files

- `Info.plist` - App configuration and permissions
- `Runner.xcworkspace` - Xcode workspace
- `Runner/` - iOS app code

## Required Permissions

Add these to `Info.plist`:
- `NSMicrophoneUsageDescription` - "J.A.R.V.I.S needs microphone access for voice commands"
- `NSSpeechRecognitionUsageDescription` - "J.A.R.V.I.S needs speech recognition for voice commands"

## Setup

Once Flutter is installed, run:
```bash
flutter build ios
```

To run on iOS device/simulator:
```bash
flutter run -d ios
```

## Requirements

- macOS
- Xcode (latest version)
- CocoaPods

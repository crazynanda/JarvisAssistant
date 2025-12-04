# Plugins Directory

This directory contains custom Flutter plugins for the J.A.R.V.I.S application.

## Purpose

Custom plugins provide platform-specific functionality:
- Native voice recognition implementations
- Custom audio processing
- Platform-specific integrations
- Hardware access (sensors, camera, etc.)

## Creating a Plugin

Each plugin should be in its own subdirectory with:
- `android/` - Android implementation
- `ios/` - iOS implementation
- `lib/` - Dart interface
- `pubspec.yaml` - Plugin configuration

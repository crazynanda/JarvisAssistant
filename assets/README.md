# Assets Directory

This directory contains static assets for the J.A.R.V.I.S application.

## Structure

- `images/` - Image files (PNG, JPG, SVG)
- `sounds/` - Audio files (MP3, WAV) for voice responses and notifications
- `fonts/` - Custom font files (TTF, OTF)

## Usage

Assets are referenced in `pubspec.yaml` and can be loaded using:
```dart
Image.asset('assets/images/logo.png')
```

## Guidelines

- Use appropriate image formats (PNG for transparency, JPG for photos)
- Optimize images for mobile (compress, use appropriate resolutions)
- Provide @2x and @3x versions for different screen densities
- Keep audio files small for faster loading

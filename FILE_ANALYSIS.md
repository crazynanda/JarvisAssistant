# File Analysis Feature

## Overview

J.A.R.V.I.S can now analyze uploaded files and images, extracting text and providing intelligent summaries.

## Supported File Types

### Documents
- **PDF** (.pdf) - Text extraction using PyPDF2

### Images
- **JPEG** (.jpg, .jpeg)
- **PNG** (.png)
- **BMP** (.bmp)
- **TIFF** (.tiff)
- **GIF** (.gif)

Images are processed using OCR (Optical Character Recognition) via Tesseract.

## Backend Implementation

### Endpoint: POST `/analyze_file`

Upload a file for analysis and summarization.

**Request**: Multipart form data
```
file: <binary file data>
```

**Response**:
```json
{
  "summary": "This document discusses...",
  "file_type": "pdf",
  "filename": "document.pdf"
}
```

### Processing Flow

```
File Upload
    ↓
Determine File Type
    ↓
PDF? → Extract text with PyPDF2
Image? → OCR with Tesseract
    ↓
Extract Text Content
    ↓
Generate Summary with GPT-4o-mini
    ↓
Apply Security Redaction
    ↓
Return Summary
```

### Dependencies

**Backend** (`requirements.txt`):
- `PyPDF2==3.0.1` - PDF text extraction
- `pytesseract==0.3.10` - OCR engine
- `Pillow==10.2.0` - Image processing
- `python-multipart==0.0.6` - File upload support

### Installation

#### Tesseract OCR

**Windows**:
```bash
# Download installer from:
https://github.com/UB-Mannheim/tesseract/wiki

# Or use chocolatey:
choco install tesseract
```

**macOS**:
```bash
brew install tesseract
```

**Linux**:
```bash
sudo apt-get install tesseract-ocr
```

## Flutter Integration

### Dependencies

**Frontend** (`pubspec.yaml`):
- `file_picker: ^6.1.1` - File selection
- `image_picker: ^1.0.7` - Image/camera selection
- `http: ^1.1.2` - HTTP requests

### Usage

#### File Upload Service

```dart
import 'services/file_upload_service.dart';

final fileService = FileUploadService();

// Pick and analyze PDF
final result = await fileService.pickAndAnalyzeFile();

// Pick and analyze image
final result = await fileService.pickAndAnalyzeImage(
  source: ImageSource.gallery,
);
```

#### UI Integration

The chat screen includes an attachment button next to the mic button:

1. **Tap attachment button** → Shows bottom sheet
2. **Select "Upload PDF"** → Opens file picker
3. **Select "Upload Image"** → Choose camera or gallery
4. **File uploads** → Processing indicator
5. **Summary displayed** → As assistant message
6. **Summary spoken** → Via text-to-speech

## Features

### 1. PDF Analysis

**Example**:
```
User uploads: research_paper.pdf
J.A.R.V.I.S: "This research paper discusses machine learning 
applications in healthcare, focusing on diagnostic accuracy 
improvements and patient outcome predictions."
```

### 2. Image OCR

**Example**:
```
User uploads: receipt.jpg
J.A.R.V.I.S: "This appears to be a receipt from ABC Store 
dated January 15, 2025, totaling $45.99 for groceries."
```

### 3. Camera Integration

Take a photo and get instant analysis:
```
User: Takes photo of whiteboard
J.A.R.V.I.S: "The whiteboard contains project planning notes 
with three main tasks: design review, implementation, and testing."
```

## API Examples

### Using curl

```bash
# Upload PDF
curl -X POST http://localhost:8000/analyze_file \
  -F "file=@document.pdf"

# Upload image
curl -X POST http://localhost:8000/analyze_file \
  -F "file=@image.jpg"
```

### Using Python

```python
import requests

# Upload file
with open('document.pdf', 'rb') as f:
    files = {'file': f}
    response = requests.post(
        'http://localhost:8000/analyze_file',
        files=files
    )
    
print(response.json()['summary'])
```

### Using Flutter

```dart
final result = await _fileUploadService.pickAndAnalyzeFile();

if (result != null && result['success'] == true) {
  print('Summary: ${result['summary']}');
  print('File type: ${result['file_type']}');
}
```

## Error Handling

### Common Errors

#### Tesseract Not Installed

**Error**: `Tesseract OCR is not installed`

**Solution**: Install Tesseract (see Installation section)

#### Unsupported File Type

**Error**: `Unsupported file type`

**Solution**: Use PDF or supported image formats

#### Empty File

**Error**: `No text could be extracted`

**Solution**: Ensure file contains readable text/content

#### File Too Large

**Error**: `Request entity too large`

**Solution**: Reduce file size or split into smaller files

## Configuration

### Backend Settings

In `file_analyzer.py`:

```python
# Supported formats
supported_image_formats = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.gif']
supported_pdf_formats = ['.pdf']
```

### Summary Length

In `main.py`:

```python
# Adjust summary length
max_tokens=300  # Increase for longer summaries

# Adjust content limit
extracted_text[:4000]  # Increase to analyze more content
```

### OCR Language

```python
# In file_analyzer.py
text = pytesseract.image_to_string(image, lang='eng')

# For other languages:
# lang='fra' - French
# lang='spa' - Spanish
# lang='deu' - German
```

## Performance

### Processing Times

- **PDF (10 pages)**: ~2-3 seconds
- **Image OCR**: ~1-2 seconds
- **Summary generation**: ~1-2 seconds
- **Total**: ~3-7 seconds

### File Size Limits

- **Default**: 10MB (FastAPI default)
- **Recommended**: <5MB for optimal performance

### Optimization Tips

1. **Compress images** before upload
2. **Limit PDF pages** to relevant sections
3. **Use appropriate image quality** (85% JPEG)

## Security

### File Validation

- File type checked by extension
- Content validated during processing
- Malformed files rejected

### Privacy

- Files processed in memory
- Not saved to disk
- Temporary data cleared after processing

### Redaction

Summaries pass through security middleware:
- Technical terms redacted
- Classified information protected

## Troubleshooting

### PDF Text Not Extracted

**Problem**: PDF returns "No text could be extracted"

**Causes**:
- Scanned PDF (image-based)
- Protected/encrypted PDF
- Corrupted file

**Solutions**:
- Use OCR on scanned PDFs
- Remove PDF protection
- Try different file

### OCR Poor Quality

**Problem**: Incorrect text recognition

**Solutions**:
- Use higher resolution images
- Ensure good lighting
- Avoid blurry photos
- Use clear fonts

### Upload Fails

**Problem**: File upload times out

**Solutions**:
- Check file size
- Verify network connection
- Ensure backend is running

## Future Enhancements

Potential improvements:

- [ ] Support for Word documents (.docx)
- [ ] Excel spreadsheet analysis (.xlsx)
- [ ] PowerPoint presentation summaries (.pptx)
- [ ] Audio file transcription
- [ ] Video content analysis
- [ ] Batch file processing
- [ ] File history and re-analysis
- [ ] Custom summary templates

## Examples

### Research Paper Analysis

```
Input: 20-page research paper PDF
Output: "This research investigates the impact of climate 
change on coastal ecosystems, presenting data from 15-year 
study across 50 sites. Key findings include 30% biodiversity 
loss and recommendations for conservation strategies."
```

### Receipt Processing

```
Input: Photo of restaurant receipt
Output: "Restaurant receipt from Bella Italia dated 
Nov 22, 2025. Total: $87.50 including appetizers, 
main courses, and beverages for two people."
```

### Whiteboard Notes

```
Input: Photo of meeting whiteboard
Output: "Meeting notes outline Q1 2025 objectives: 
launch new product line, expand to 3 new markets, 
and increase customer retention by 15%."
```

## Testing

### Test Backend

```bash
cd backend/jarvis_server

# Test PDF
curl -X POST http://localhost:8000/analyze_file \
  -F "file=@test.pdf"

# Test image
curl -X POST http://localhost:8000/analyze_file \
  -F "file=@test.jpg"
```

### Test Flutter

1. Run app on device/emulator
2. Tap attachment button
3. Select "Upload PDF" or "Upload Image"
4. Choose file
5. Verify summary appears in chat

## Platform-Specific Notes

### Android

- Camera permission required for camera uploads
- Storage permission for file access
- Works on Android 5.0+

### iOS

- Photo library permission required
- Camera permission for camera uploads
- Works on iOS 11.0+

## Permissions

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### iOS (`Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>J.A.R.V.I.S needs camera access to analyze images</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>J.A.R.V.I.S needs photo access to analyze images</string>
```

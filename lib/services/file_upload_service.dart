import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../screens/settings_screen.dart';

class FileUploadService {
  final String baseUrl;
  
  FileUploadService({this.baseUrl = 'http://localhost:8000'});
  
  /// Pick and analyze a file (PDF or document)
  Future<Map<String, dynamic>?> pickAndAnalyzeFile() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      
      if (result == null || result.files.single.path == null) {
        return null;
      }
      
      final file = File(result.files.single.path!);
      final filename = result.files.single.name;
      
      return await _uploadAndAnalyze(file, filename);
      
    } catch (e) {
      throw Exception('Error picking file: $e');
    }
  }
  
  /// Pick and analyze an image from camera or gallery
  Future<Map<String, dynamic>?> pickAndAnalyzeImage({
    required ImageSource source,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Pick image
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      
      if (image == null) {
        return null;
      }
      
      final file = File(image.path);
      final filename = image.name;
      
      return await _uploadAndAnalyze(file, filename);
      
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }
  
  /// Upload file and get analysis
  Future<Map<String, dynamic>> _uploadAndAnalyze(
    File file,
    String filename,
  ) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze_file'),
      );
      
      // Add permissions header
      final permissions = await SettingsManager.getAllPermissions();
      request.headers['X-Permissions'] = json.encode(permissions);
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: filename,
        ),
      );
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'summary': data['summary'],
          'file_type': data['file_type'],
          'filename': data['filename'],
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to analyze file');
      }
      
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }
}

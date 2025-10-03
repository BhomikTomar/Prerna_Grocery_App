import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'auth_service.dart';

class ImageService {
  static const String baseUrl =
      'http://localhost:5000/api'; // Update with your backend URL

  /// Pick multiple images from gallery or camera
  static Future<List<XFile>> pickImages({
    ImageSource source = ImageSource.gallery,
    int maxImages = 5,
  }) async {
    final ImagePicker picker = ImagePicker();

    if (source == ImageSource.gallery) {
      // Pick multiple images from gallery
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images.take(maxImages).toList();
    } else {
      // Pick single image from camera
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image != null ? [image] : [];
    }
  }

  /// Upload multiple images to the backend
  static Future<List<String>> uploadImages(List<XFile> images) async {
    List<String> uploadedUrls = [];

    for (XFile image in images) {
      try {
        final String? imageUrl = await uploadSingleImage(image);
        if (imageUrl != null) {
          uploadedUrls.add(imageUrl);
        }
      } catch (e) {
        print('Error uploading image ${image.name}: $e');
        // Continue with other images even if one fails
      }
    }

    return uploadedUrls;
  }

  /// Upload a single image to the backend
  static Future<String?> uploadSingleImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final fileName = image.name;
      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';

      // Get authentication token
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        print('No authentication token found');
        return null;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/image'),
      );

      // Add authentication header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = jsonDecode(responseBody);

        if (responseData['success'] == true) {
          return responseData['url'];
        }
      }

      print('Upload failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Convert XFile to File for local storage if needed
  static Future<File?> xFileToFile(XFile xFile) async {
    if (kIsWeb) {
      // On web, we can't create local files, return null
      return null;
    }

    final bytes = await xFile.readAsBytes();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${xFile.name}');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Get image preview widget for selected images
  static Widget getImagePreview(XFile image, {double? width, double? height}) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: kIsWeb
            ? Image.network(
                image.path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              )
            : Image.file(
                File(image.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
      ),
    );
  }
}

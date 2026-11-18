// lib/services/CloudinaryService.dart
// ─────────────────────────────────────────────────────────────────────────────
// Handles all image uploads to Cloudinary.
// Works across Web, Android, iOS, Windows, macOS, Linux using XFile bytes.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class CloudinaryService extends GetxService {
  // ── Your Cloudinary credentials ────────────────────────────────────────────
  static const String _cloudName = 'dntto9b5q';
  static const String _uploadPreset = 'unsigned_preset';

  // Cloudinary unsigned upload endpoint
  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ────────────────────────────────────────────────────────────────────────────
  // Upload a single image file (XFile) to Cloudinary using raw bytes.
  // ────────────────────────────────────────────────────────────────────────────
  Future<String> uploadImage(XFile imageFile, {String folder = 'hostel'}) async {
    try {
      print('CloudinaryService: uploading ${imageFile.name} to folder/$folder');

      // Build multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      final fileExtension = path.extension(imageFile.name).replaceAll('.', '');
      final mimeType = _getMimeType(fileExtension);
      final bytes = await imageFile.readAsBytes();

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'upload.jpg',
        contentType: MediaType('image', mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final secureUrl = jsonData['secure_url'] as String;
        print('CloudinaryService: upload success → $secureUrl');
        return secureUrl;
      } else {
        print('CloudinaryService: upload failed [${response.statusCode}]: ${response.body}');
        throw Exception('Cloudinary upload failed: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      print('CloudinaryService: error uploading image: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Upload multiple hostel images at once.
  // ────────────────────────────────────────────────────────────────────────────
  Future<List<String>> uploadMultipleImages(
    String hostelId,
    List<XFile> imageFiles, {
    Function(int uploaded, int total)? onProgress,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadImage(
        imageFiles[i],
        folder: 'hostel/$hostelId',
      );
      downloadUrls.add(url);

      onProgress?.call(i + 1, imageFiles.length);
    }

    return downloadUrls;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Upload a user profile picture.
  // ────────────────────────────────────────────────────────────────────────────
  Future<String> uploadProfileImage(String userId, XFile imageFile) async {
    return await uploadImage(
      imageFile,
      folder: 'profiles/$userId',
    );
  }

  Future<void> deleteImage(String imageUrl) async {
    print('CloudinaryService: deleteImage() — image removed from Firestore reference only.');
    print('CloudinaryService: URL was: $imageUrl');
  }

  // ── Helper: map file extension to MIME type ────────────────────────────────
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }
}

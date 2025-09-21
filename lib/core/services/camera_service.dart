import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  // Simple stubs that return local file paths as URLs for chat image messages
  static Future<String?> captureAndUploadImage() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    return x?.path; // In production, upload and return remote URL
  }

  static Future<String?> pickAndUploadImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    return x?.path;
  }

  static Future<List<String>> captureMultiplePages({
    required BuildContext context,
    int maxPages = 5,
  }) async {
    final images = <String>[];
    for (int i = 0; i < maxPages; i++) {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (x == null) break;
      images.add(x.path);
      // Optionally show a dialog to continue/stop
    }
    return images;
  }

  static Future<String?> captureSingleImage({
    bool useFlash = false,
    double? aspectRatio = 3 / 4,
  }) async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    return x?.path;
  }

  static Future<bool> validateImageQuality(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return false;
    // Naive size check as a placeholder
    final length = await file.length();
    return length > 50 * 1024; // >50KB
  }

  static Future<String> enhanceDocumentImage(String imagePath) async {
    // Placeholder: return original path for now
    return imagePath;
  }
}

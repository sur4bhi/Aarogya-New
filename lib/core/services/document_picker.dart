import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class DocumentPicker {
  static final ImagePicker _imagePicker = ImagePicker();

  static const _supportedImageExt = ['jpg', 'jpeg', 'png'];
  static const _supportedPdfExt = ['pdf'];

  static bool isSupportedFormat(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return _supportedImageExt.contains(ext) || _supportedPdfExt.contains(ext);
  }

  static Future<List<String>> pickMedicalDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [..._supportedImageExt, ..._supportedPdfExt],
    );
    if (result == null) return [];
    final paths = <String>[];
    for (final f in result.files) {
      if (f.path != null && isSupportedFormat(f.path!)) {
        if (f.extension?.toLowerCase() == 'pdf') {
          final imgs = await convertPdfToImages(f.path!);
          paths.addAll(imgs);
        } else {
          paths.add(f.path!);
        }
      }
    }
    return paths;
  }

  static Future<List<String>> convertPdfToImages(String pdfPath) async {
    // Placeholder implementation. In production, use packages like `pdfx` or platform channels.
    // Return empty for now to keep it non-breaking; caller should handle zero images.
    return [];
  }

  static Future<List<String>> pickFromGalleryMulti() async {
    final imgs = await _imagePicker.pickMultiImage(imageQuality: 85);
    return imgs.map((x) => x.path).toList();
  }
}

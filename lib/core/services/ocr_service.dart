import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size, Rect;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../utils/medical_ocr_parser.dart';
import '../../models/medical_ocr_models.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();
  static final ImagePicker _imagePicker = ImagePicker();
  
  // Initialize OCR service
  static Future<void> init() async {
    // Initialization if needed
  }
  
  // Dispose OCR service
  static void dispose() {
    _textRecognizer.close();
  }
  
  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }
  
  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }
  
  // Extract text from image file
  static Future<OCRResult> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return OCRResult(
        success: true,
        text: recognizedText.text,
        blocks: recognizedText.blocks.map((block) => TextBlockInfo(
          text: block.text,
          boundingBox: block.boundingBox,
          languageCode: block.recognizedLanguages.isNotEmpty 
              ? block.recognizedLanguages.first 
              : null,
        )).toList(),
      );
    } catch (e) {
      return OCRResult(
        success: false,
        error: 'Failed to extract text: $e',
      );
    }
  }
  
  // Extract text from image bytes
  static Future<OCRResult> extractTextFromBytes(Uint8List imageBytes) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(800, 600),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 800,
        ),
      );
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return OCRResult(
        success: true,
        text: recognizedText.text,
        blocks: recognizedText.blocks.map((block) => TextBlockInfo(
          text: block.text,
          boundingBox: block.boundingBox,
          languageCode: block.recognizedLanguages.isNotEmpty 
              ? block.recognizedLanguages.first 
              : null,
        )).toList(),
      );
    } catch (e) {
      return OCRResult(
        success: false,
        error: 'Failed to extract text: $e',
      );
    }
  }
  
  // Medical-specific single page processing
  static Future<MedicalOCRResult> processMedicalDocument(String imagePath) async {
    try {
      // Optional: pre-process for better accuracy
      final processedPath = await preprocessMedicalImage(imagePath);
      final file = File(processedPath);
      final ocrResult = await extractTextFromImage(file);
      if (!ocrResult.success || (ocrResult.text == null || ocrResult.text!.trim().isEmpty)) {
        return MedicalOCRResult(rawText: ocrResult.text ?? '', confidence: 0.0);
      }
      final parsed = MedicalOCRParser.parseExtractedText(ocrResult.text!);
      return parsed;
    } catch (e) {
      return MedicalOCRResult(rawText: '', confidence: 0.0);
    }
  }

  // Medical-specific multi-page processing
  static Future<List<MedicalOCRResult>> processMultiPageReport(List<String> imagePaths) async {
    final results = <MedicalOCRResult>[];
    for (var i = 0; i < imagePaths.length; i++) {
      results.add(await processMedicalDocument(imagePaths[i]));
    }
    return results;
  }

  // Validate image quality for medical OCR
  static bool validateMedicalImageQuality(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return false;
      if (file.lengthSync() < 50 * 1024) return false; // basic size check
      final decoded = img.decodeImage(file.readAsBytesSync());
      if (decoded == null) return false;
      // Minimal resolution check
      return decoded.width >= 800 && decoded.height >= 800;
    } catch (_) {
      return false;
    }
  }

  // Preprocess and return path
  static Future<String> preprocessMedicalImage(String imagePath) async {
    try {
      final processed = await preprocessImage(File(imagePath));
      return processed.path;
    } catch (_) {
      return imagePath;
    }
  }

  // Process medical report
  static Future<MedicalReportData> processMedicalReport(File imageFile) async {
    try {
      final ocrResult = await extractTextFromImage(imageFile);
      
      if (!ocrResult.success) {
        return MedicalReportData(
          success: false,
          error: ocrResult.error,
        );
      }
      
      final extractedData = _extractMedicalData(ocrResult.text ?? '');
      
      return MedicalReportData(
        success: true,
        rawText: ocrResult.text,
        patientName: extractedData['patientName'],
        doctorName: extractedData['doctorName'],
        hospitalName: extractedData['hospitalName'],
        reportDate: extractedData['reportDate'],
        reportType: extractedData['reportType'],
        testResults: extractedData['testResults'],
        diagnosis: extractedData['diagnosis'],
        medications: extractedData['medications'],
        vitalSigns: extractedData['vitalSigns'],
      );
    } catch (e) {
      return MedicalReportData(
        success: false,
        error: 'Failed to process medical report: $e',
      );
    }
  }
  
  // Extract medical data from text
  static Map<String, dynamic> _extractMedicalData(String text) {
    final Map<String, dynamic> data = {};
    
    // Extract patient name
    data['patientName'] = _extractPatientName(text);
    
    // Extract doctor name
    data['doctorName'] = _extractDoctorName(text);
    
    // Extract hospital name
    data['hospitalName'] = _extractHospitalName(text);
    
    // Extract report date
    data['reportDate'] = _extractReportDate(text);
    
    // Extract report type
    data['reportType'] = _extractReportType(text);
    
    // Extract test results
    data['testResults'] = _extractTestResults(text);
    
    // Extract diagnosis
    data['diagnosis'] = _extractDiagnosis(text);
    
    // Extract medications
    data['medications'] = _extractMedications(text);
    
    // Extract vital signs
    data['vitalSigns'] = _extractVitalSigns(text);
    
    return data;
  }
  
  // Extract patient name
  static String? _extractPatientName(String text) {
    final patterns = [
      RegExp(r'Patient\s*Name\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Name\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Patient\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    
    return null;
  }
  
  // Extract doctor name
  static String? _extractDoctorName(String text) {
    final patterns = [
      RegExp(r'Dr\.?\s*([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Doctor\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Physician\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    
    return null;
  }
  
  // Extract hospital name
  static String? _extractHospitalName(String text) {
    final patterns = [
      RegExp(r'Hospital\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Clinic\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Medical Center\s*:?\s*([A-Za-z\s]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    
    return null;
  }
  
  // Extract report date
  static DateTime? _extractReportDate(String text) {
    final patterns = [
      RegExp(r'Date\s*:?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})'),
      RegExp(r'(\d{1,2}\s+[A-Za-z]+\s+\d{2,4})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final dateString = match.group(1);
          return DateTime.tryParse(dateString ?? '');
        } catch (e) {
          continue;
        }
      }
    }
    
    return null;
  }
  
  // Extract report type
  static String? _extractReportType(String text) {
    final reportTypes = [
      'Blood Test', 'Urine Test', 'X-Ray', 'MRI', 'CT Scan',
      'ECG', 'EKG', 'Ultrasound', 'Biopsy', 'Pathology',
      'Laboratory Report', 'Radiology Report', 'Prescription',
    ];
    
    for (final type in reportTypes) {
      if (text.toLowerCase().contains(type.toLowerCase())) {
        return type;
      }
    }
    
    return null;
  }
  
  // Extract test results
  static Map<String, String>? _extractTestResults(String text) {
    final Map<String, String> results = {};
    
    // Common test patterns
    final patterns = [
      RegExp(r'Hemoglobin\s*:?\s*([\d\.]+)', caseSensitive: false),
      RegExp(r'Glucose\s*:?\s*([\d\.]+)', caseSensitive: false),
      RegExp(r'Cholesterol\s*:?\s*([\d\.]+)', caseSensitive: false),
      RegExp(r'Blood Pressure\s*:?\s*([\d\/]+)', caseSensitive: false),
      RegExp(r'Heart Rate\s*:?\s*([\d\.]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final testName = pattern.pattern.split(r'\s*:?\s*')[0];
        results[testName] = match.group(1) ?? '';
      }
    }
    
    return results.isNotEmpty ? results : null;
  }
  
  // Extract diagnosis
  static String? _extractDiagnosis(String text) {
    final patterns = [
      RegExp(r'Diagnosis\s*:?\s*([^\n]+)', caseSensitive: false),
      RegExp(r'Impression\s*:?\s*([^\n]+)', caseSensitive: false),
      RegExp(r'Findings\s*:?\s*([^\n]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    
    return null;
  }
  
  // Extract medications
  static List<String>? _extractMedications(String text) {
    final medications = <String>[];
    
    final patterns = [
      RegExp(r'Medication\s*:?\s*([^\n]+)', caseSensitive: false),
      RegExp(r'Prescription\s*:?\s*([^\n]+)', caseSensitive: false),
      RegExp(r'Medicine\s*:?\s*([^\n]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final medication = match.group(1)?.trim();
        if (medication != null && medication.isNotEmpty) {
          medications.add(medication);
        }
      }
    }
    
    return medications.isNotEmpty ? medications : null;
  }
  
  // Extract vital signs
  static Map<String, String>? _extractVitalSigns(String text) {
    final Map<String, String> vitals = {};
    
    final patterns = [
      RegExp(r'Temperature\s*:?\s*([\d\.]+)', caseSensitive: false),
      RegExp(r'BP\s*:?\s*([\d\/]+)', caseSensitive: false),
      RegExp(r'Pulse\s*:?\s*([\d\.]+)', caseSensitive: false),
      RegExp(r'Respiratory Rate\s*:?\s*([\d\.]+)', caseSensitive: false),
      RegExp(r'SpO2\s*:?\s*([\d\.]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final vitalName = pattern.pattern.split(r'\s*:?\s*')[0];
        vitals[vitalName] = match.group(1) ?? '';
      }
    }
    
    return vitals.isNotEmpty ? vitals : null;
  }
  
  // Preprocess image for better OCR
  static Future<File> preprocessImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) return imageFile;
      
      // Apply image processing
      final processedImage = img.copyResize(image, width: 1920);
      final grayscaleImage = img.grayscale(processedImage);
      final contrastImage = img.adjustColor(grayscaleImage, contrast: 1.2);
      
      // Save processed image
      final processedBytes = img.encodeJpg(contrastImage, quality: 90);
      final processedFile = File('${imageFile.path}_processed.jpg');
      await processedFile.writeAsBytes(processedBytes);
      
      return processedFile;
    } catch (e) {
      print('Error preprocessing image: $e');
      return imageFile;
    }
  }
  
  // Validate extracted data
  static bool validateExtractedData(MedicalReportData data) {
    if (!data.success) return false;
    
    // Check if at least some data was extracted
    return data.patientName != null ||
           data.doctorName != null ||
           data.testResults != null ||
           data.diagnosis != null;
  }
}

// OCR Result class
class OCRResult {
  final bool success;
  final String? text;
  final String? error;
  final List<TextBlockInfo>? blocks;
  
  OCRResult({
    required this.success,
    this.text,
    this.error,
    this.blocks,
  });
}

// Text Block Info class
class TextBlockInfo {
  final String text;
  final Rect boundingBox;
  final String? languageCode;
  
  TextBlockInfo({
    required this.text,
    required this.boundingBox,
    this.languageCode,
  });
}

// Medical Report Data class
class MedicalReportData {
  final bool success;
  final String? error;
  final String? rawText;
  final String? patientName;
  final String? doctorName;
  final String? hospitalName;
  final DateTime? reportDate;
  final String? reportType;
  final Map<String, String>? testResults;
  final String? diagnosis;
  final List<String>? medications;
  final Map<String, String>? vitalSigns;
  
  MedicalReportData({
    required this.success,
    this.error,
    this.rawText,
    this.patientName,
    this.doctorName,
    this.hospitalName,
    this.reportDate,
    this.reportType,
    this.testResults,
    this.diagnosis,
    this.medications,
    this.vitalSigns,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'rawText': rawText,
      'patientName': patientName,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'reportDate': reportDate?.toIso8601String(),
      'reportType': reportType,
      'testResults': testResults,
      'diagnosis': diagnosis,
      'medications': medications,
      'vitalSigns': vitalSigns,
    };
  }
}

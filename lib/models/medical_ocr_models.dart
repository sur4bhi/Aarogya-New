import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationEntry {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;

  const MedicationEntry({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
      };

  factory MedicationEntry.fromJson(Map<String, dynamic> json) => MedicationEntry(
        name: json['name'] ?? '',
        dosage: json['dosage'] ?? '',
        frequency: json['frequency'] ?? '',
        duration: json['duration'] ?? '',
      );
}

class MedicalOCRResult {
  final String rawText;
  final double confidence;

  final double? systolicBP;
  final double? diastolicBP;
  final double? bloodSugar; // mg/dL
  final double? cholesterol; // mg/dL
  final double? hemoglobin; // g/dL
  final double? weight; // kg
  final double? height; // cm

  final List<MedicationEntry>? medications;
  final List<String>? conditions;
  final String? doctorAdvice;
  final DateTime? nextVisitDate;

  const MedicalOCRResult({
    required this.rawText,
    required this.confidence,
    this.systolicBP,
    this.diastolicBP,
    this.bloodSugar,
    this.cholesterol,
    this.hemoglobin,
    this.weight,
    this.height,
    this.medications,
    this.conditions,
    this.doctorAdvice,
    this.nextVisitDate,
  });

  Map<String, dynamic> toJson() => {
        'rawText': rawText,
        'confidence': confidence,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'bloodSugar': bloodSugar,
        'cholesterol': cholesterol,
        'hemoglobin': hemoglobin,
        'weight': weight,
        'height': height,
        'medications': medications?.map((e) => e.toJson()).toList(),
        'conditions': conditions,
        'doctorAdvice': doctorAdvice,
        'nextVisitDate': nextVisitDate?.toIso8601String(),
      };

  factory MedicalOCRResult.fromJson(Map<String, dynamic> json) => MedicalOCRResult(
        rawText: json['rawText'] ?? '',
        confidence: (json['confidence'] ?? 0).toDouble(),
        systolicBP: (json['systolicBP'] as num?)?.toDouble(),
        diastolicBP: (json['diastolicBP'] as num?)?.toDouble(),
        bloodSugar: (json['bloodSugar'] as num?)?.toDouble(),
        cholesterol: (json['cholesterol'] as num?)?.toDouble(),
        hemoglobin: (json['hemoglobin'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
        medications: (json['medications'] as List<dynamic>?)
            ?.map((e) => MedicationEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        conditions: (json['conditions'] as List<dynamic>?)?.cast<String>(),
        doctorAdvice: json['doctorAdvice'],
        nextVisitDate: json['nextVisitDate'] != null
            ? DateTime.tryParse(json['nextVisitDate'])
            : null,
      );
}

class MedicalReportModel {
  final String id;
  final String userId;
  final String title;
  final String reportType; // 'blood_test', 'prescription', 'scan', 'discharge', 'other'
  final DateTime reportDate;
  final String? hospitalName;
  final String? doctorName;

  // File Information
  final String originalFilePath;
  final List<String>? imagePaths; // Multiple pages
  final String? extractedText;

  // Parsed Medical Data
  final Map<String, dynamic>? vitalsExtracted; // BP, sugar, cholesterol, etc.
  final List<String>? medications;
  final List<String>? diagnoses;
  final String? recommendations;

  // Metadata
  final double ocrConfidence;
  final bool isReviewedByUser;
  final bool sharedWithAsha;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Sync Status
  final bool needsSync;
  final String syncStatus; // 'pending', 'synced', 'failed'

  const MedicalReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.reportType,
    required this.reportDate,
    this.hospitalName,
    this.doctorName,
    required this.originalFilePath,
    this.imagePaths,
    this.extractedText,
    this.vitalsExtracted,
    this.medications,
    this.diagnoses,
    this.recommendations,
    this.ocrConfidence = 0.0,
    this.isReviewedByUser = false,
    this.sharedWithAsha = false,
    required this.createdAt,
    this.updatedAt,
    this.needsSync = false,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'reportType': reportType,
        'reportDate': Timestamp.fromDate(reportDate),
        'hospitalName': hospitalName,
        'doctorName': doctorName,
        'files': {
          'originalPath': originalFilePath,
          'imagePaths': imagePaths,
        },
        'ocrData': {
          'extractedText': extractedText,
          'confidence': ocrConfidence,
          'vitalsExtracted': vitalsExtracted,
          'medications': medications,
          'diagnoses': diagnoses,
          'recommendations': recommendations,
        },
        'metadata': {
          'isReviewedByUser': isReviewedByUser,
          'sharedWithAsha': sharedWithAsha,
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        },
        'needsSync': needsSync,
        'syncStatus': syncStatus,
      };

  factory MedicalReportModel.fromFirestore(String id, Map<String, dynamic> data) {
    final files = Map<String, dynamic>.from(data['files'] ?? {});
    final ocrData = Map<String, dynamic>.from(data['ocrData'] ?? {});
    final metadata = Map<String, dynamic>.from(data['metadata'] ?? {});

    return MedicalReportModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      reportType: data['reportType'] ?? 'other',
      reportDate: (data['reportDate'] as Timestamp).toDate(),
      hospitalName: data['hospitalName'],
      doctorName: data['doctorName'],
      originalFilePath: files['originalPath'] ?? '',
      imagePaths: (files['imagePaths'] as List?)?.cast<String>(),
      extractedText: ocrData['extractedText'],
      vitalsExtracted: ocrData['vitalsExtracted'] != null
          ? Map<String, dynamic>.from(ocrData['vitalsExtracted'])
          : null,
      medications: (ocrData['medications'] as List?)?.cast<String>(),
      diagnoses: (ocrData['diagnoses'] as List?)?.cast<String>(),
      recommendations: ocrData['recommendations'],
      ocrConfidence: (ocrData['confidence'] ?? 0).toDouble(),
      isReviewedByUser: metadata['isReviewedByUser'] ?? false,
      sharedWithAsha: metadata['sharedWithAsha'] ?? false,
      createdAt: (metadata['createdAt'] as Timestamp).toDate(),
      updatedAt: metadata['updatedAt'] != null
          ? (metadata['updatedAt'] as Timestamp).toDate()
          : null,
      needsSync: data['needsSync'] ?? false,
      syncStatus: data['syncStatus'] ?? 'pending',
    );
  }
}

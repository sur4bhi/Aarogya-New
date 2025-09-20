import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final ReportType type;
  final DateTime reportDate;
  final String? doctorName;
  final String? hospitalName;
  final String? department;
  final List<String> imageUrls;
  final String? pdfUrl;
  final ReportStatus status;
  final bool isProcessed;
  final Map<String, dynamic>? extractedData;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // OCR and processing fields
  final String? rawOcrText;
  final double? ocrConfidence;
  final bool isOcrProcessed;
  final DateTime? ocrProcessedAt;
  
  // Medical data fields
  final String? patientName;
  final String? patientId;
  final Map<String, String>? testResults;
  final String? diagnosis;
  final List<String>? medications;
  final Map<String, String>? vitalSigns;
  final String? recommendations;
  final DateTime? nextAppointment;
  
  // Sharing and privacy
  final bool isSharedWithAsha;
  final String? sharedAshaId;
  final DateTime? sharedAt;
  final List<String> sharedWith;
  final ReportPrivacy privacy;

  ReportModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.reportDate,
    this.doctorName,
    this.hospitalName,
    this.department,
    this.imageUrls = const [],
    this.pdfUrl,
    this.status = ReportStatus.uploaded,
    this.isProcessed = false,
    this.extractedData,
    this.tags = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.rawOcrText,
    this.ocrConfidence,
    this.isOcrProcessed = false,
    this.ocrProcessedAt,
    this.patientName,
    this.patientId,
    this.testResults,
    this.diagnosis,
    this.medications,
    this.vitalSigns,
    this.recommendations,
    this.nextAppointment,
    this.isSharedWithAsha = false,
    this.sharedAshaId,
    this.sharedAt,
    this.sharedWith = const [],
    this.privacy = ReportPrivacy.private,
  });

  // Computed properties
  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
  bool get hasExtractedData => extractedData != null && extractedData!.isNotEmpty;
  bool get hasTestResults => testResults != null && testResults!.isNotEmpty;
  bool get hasDiagnosis => diagnosis != null && diagnosis!.isNotEmpty;
  bool get hasMedications => medications != null && medications!.isNotEmpty;
  bool get hasVitalSigns => vitalSigns != null && vitalSigns!.isNotEmpty;
  
  int get daysOld => DateTime.now().difference(reportDate).inDays;
  
  bool get isRecent => daysOld <= 30;
  bool get isOld => daysOld > 365;
  
  String get ageText {
    if (daysOld == 0) return 'Today';
    if (daysOld == 1) return 'Yesterday';
    if (daysOld < 7) return '$daysOld days ago';
    if (daysOld < 30) return '${(daysOld / 7).floor()} weeks ago';
    if (daysOld < 365) return '${(daysOld / 30).floor()} months ago';
    return '${(daysOld / 365).floor()} years ago';
  }
  
  String get statusText {
    switch (status) {
      case ReportStatus.uploaded:
        return 'Uploaded';
      case ReportStatus.processing:
        return 'Processing';
      case ReportStatus.processed:
        return 'Processed';
      case ReportStatus.failed:
        return 'Processing Failed';
      case ReportStatus.archived:
        return 'Archived';
    }
  }
  
  // Get primary image URL
  String? get primaryImageUrl {
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }
  
  // Get file URL (PDF or primary image)
  String? get primaryFileUrl {
    return pdfUrl ?? primaryImageUrl;
  }
  
  // Check if report needs attention
  bool get needsAttention {
    return status == ReportStatus.failed || 
           (status == ReportStatus.uploaded && !isProcessed && daysOld > 1);
  }
  
  // Get summary text
  String get summaryText {
    if (hasDiagnosis) return diagnosis!;
    if (hasTestResults && testResults!.isNotEmpty) {
      return testResults!.entries.first.value;
    }
    if (description != null && description!.isNotEmpty) return description!;
    return 'Medical report from ${doctorName ?? hospitalName ?? 'healthcare provider'}';
  }

  // Factory constructor from Firestore
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReportModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      type: ReportType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => ReportType.other,
      ),
      reportDate: (data['reportDate'] as Timestamp).toDate(),
      doctorName: data['doctorName'],
      hospitalName: data['hospitalName'],
      department: data['department'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      pdfUrl: data['pdfUrl'],
      status: ReportStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => ReportStatus.uploaded,
      ),
      isProcessed: data['isProcessed'] ?? false,
      extractedData: data['extractedData'],
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      rawOcrText: data['rawOcrText'],
      ocrConfidence: data['ocrConfidence']?.toDouble(),
      isOcrProcessed: data['isOcrProcessed'] ?? false,
      ocrProcessedAt: data['ocrProcessedAt'] != null 
          ? (data['ocrProcessedAt'] as Timestamp).toDate() 
          : null,
      patientName: data['patientName'],
      patientId: data['patientId'],
      testResults: data['testResults'] != null 
          ? Map<String, String>.from(data['testResults']) 
          : null,
      diagnosis: data['diagnosis'],
      medications: data['medications'] != null 
          ? List<String>.from(data['medications']) 
          : null,
      vitalSigns: data['vitalSigns'] != null 
          ? Map<String, String>.from(data['vitalSigns']) 
          : null,
      recommendations: data['recommendations'],
      nextAppointment: data['nextAppointment'] != null 
          ? (data['nextAppointment'] as Timestamp).toDate() 
          : null,
      isSharedWithAsha: data['isSharedWithAsha'] ?? false,
      sharedAshaId: data['sharedAshaId'],
      sharedAt: data['sharedAt'] != null 
          ? (data['sharedAt'] as Timestamp).toDate() 
          : null,
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      privacy: ReportPrivacy.values.firstWhere(
        (privacy) => privacy.toString() == data['privacy'],
        orElse: () => ReportPrivacy.private,
      ),
    );
  }

  // Factory constructor from JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: ReportType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => ReportType.other,
      ),
      reportDate: DateTime.parse(json['reportDate']),
      doctorName: json['doctorName'],
      hospitalName: json['hospitalName'],
      department: json['department'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      pdfUrl: json['pdfUrl'],
      status: ReportStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
        orElse: () => ReportStatus.uploaded,
      ),
      isProcessed: json['isProcessed'] ?? false,
      extractedData: json['extractedData'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      rawOcrText: json['rawOcrText'],
      ocrConfidence: json['ocrConfidence']?.toDouble(),
      isOcrProcessed: json['isOcrProcessed'] ?? false,
      ocrProcessedAt: json['ocrProcessedAt'] != null 
          ? DateTime.parse(json['ocrProcessedAt']) 
          : null,
      patientName: json['patientName'],
      patientId: json['patientId'],
      testResults: json['testResults'] != null 
          ? Map<String, String>.from(json['testResults']) 
          : null,
      diagnosis: json['diagnosis'],
      medications: json['medications'] != null 
          ? List<String>.from(json['medications']) 
          : null,
      vitalSigns: json['vitalSigns'] != null 
          ? Map<String, String>.from(json['vitalSigns']) 
          : null,
      recommendations: json['recommendations'],
      nextAppointment: json['nextAppointment'] != null 
          ? DateTime.parse(json['nextAppointment']) 
          : null,
      isSharedWithAsha: json['isSharedWithAsha'] ?? false,
      sharedAshaId: json['sharedAshaId'],
      sharedAt: json['sharedAt'] != null 
          ? DateTime.parse(json['sharedAt']) 
          : null,
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
      privacy: ReportPrivacy.values.firstWhere(
        (privacy) => privacy.toString() == json['privacy'],
        orElse: () => ReportPrivacy.private,
      ),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString(),
      'reportDate': Timestamp.fromDate(reportDate),
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'department': department,
      'imageUrls': imageUrls,
      'pdfUrl': pdfUrl,
      'status': status.toString(),
      'isProcessed': isProcessed,
      'extractedData': extractedData,
      'tags': tags,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rawOcrText': rawOcrText,
      'ocrConfidence': ocrConfidence,
      'isOcrProcessed': isOcrProcessed,
      'ocrProcessedAt': ocrProcessedAt != null ? Timestamp.fromDate(ocrProcessedAt!) : null,
      'patientName': patientName,
      'patientId': patientId,
      'testResults': testResults,
      'diagnosis': diagnosis,
      'medications': medications,
      'vitalSigns': vitalSigns,
      'recommendations': recommendations,
      'nextAppointment': nextAppointment != null ? Timestamp.fromDate(nextAppointment!) : null,
      'isSharedWithAsha': isSharedWithAsha,
      'sharedAshaId': sharedAshaId,
      'sharedAt': sharedAt != null ? Timestamp.fromDate(sharedAt!) : null,
      'sharedWith': sharedWith,
      'privacy': privacy.toString(),
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString(),
      'reportDate': reportDate.toIso8601String(),
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'department': department,
      'imageUrls': imageUrls,
      'pdfUrl': pdfUrl,
      'status': status.toString(),
      'isProcessed': isProcessed,
      'extractedData': extractedData,
      'tags': tags,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rawOcrText': rawOcrText,
      'ocrConfidence': ocrConfidence,
      'isOcrProcessed': isOcrProcessed,
      'ocrProcessedAt': ocrProcessedAt?.toIso8601String(),
      'patientName': patientName,
      'patientId': patientId,
      'testResults': testResults,
      'diagnosis': diagnosis,
      'medications': medications,
      'vitalSigns': vitalSigns,
      'recommendations': recommendations,
      'nextAppointment': nextAppointment?.toIso8601String(),
      'isSharedWithAsha': isSharedWithAsha,
      'sharedAshaId': sharedAshaId,
      'sharedAt': sharedAt?.toIso8601String(),
      'sharedWith': sharedWith,
      'privacy': privacy.toString(),
    };
  }

  // Copy with method
  ReportModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ReportType? type,
    DateTime? reportDate,
    String? doctorName,
    String? hospitalName,
    String? department,
    List<String>? imageUrls,
    String? pdfUrl,
    ReportStatus? status,
    bool? isProcessed,
    Map<String, dynamic>? extractedData,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rawOcrText,
    double? ocrConfidence,
    bool? isOcrProcessed,
    DateTime? ocrProcessedAt,
    String? patientName,
    String? patientId,
    Map<String, String>? testResults,
    String? diagnosis,
    List<String>? medications,
    Map<String, String>? vitalSigns,
    String? recommendations,
    DateTime? nextAppointment,
    bool? isSharedWithAsha,
    String? sharedAshaId,
    DateTime? sharedAt,
    List<String>? sharedWith,
    ReportPrivacy? privacy,
  }) {
    return ReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      reportDate: reportDate ?? this.reportDate,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      department: department ?? this.department,
      imageUrls: imageUrls ?? this.imageUrls,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      status: status ?? this.status,
      isProcessed: isProcessed ?? this.isProcessed,
      extractedData: extractedData ?? this.extractedData,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      isOcrProcessed: isOcrProcessed ?? this.isOcrProcessed,
      ocrProcessedAt: ocrProcessedAt ?? this.ocrProcessedAt,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      testResults: testResults ?? this.testResults,
      diagnosis: diagnosis ?? this.diagnosis,
      medications: medications ?? this.medications,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      recommendations: recommendations ?? this.recommendations,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      isSharedWithAsha: isSharedWithAsha ?? this.isSharedWithAsha,
      sharedAshaId: sharedAshaId ?? this.sharedAshaId,
      sharedAt: sharedAt ?? this.sharedAt,
      sharedWith: sharedWith ?? this.sharedWith,
      privacy: privacy ?? this.privacy,
    );
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, title: $title, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Report type enum
enum ReportType {
  bloodTest,
  urineTest,
  xray,
  mri,
  ctScan,
  ecg,
  ultrasound,
  biopsy,
  pathology,
  prescription,
  discharge,
  consultation,
  vaccination,
  other,
}

// Report status enum
enum ReportStatus {
  uploaded,
  processing,
  processed,
  failed,
  archived,
}

// Report privacy enum
enum ReportPrivacy {
  private,
  sharedWithAsha,
  sharedWithFamily,
  public,
}

// Extension methods
extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.bloodTest:
        return 'Blood Test';
      case ReportType.urineTest:
        return 'Urine Test';
      case ReportType.xray:
        return 'X-Ray';
      case ReportType.mri:
        return 'MRI';
      case ReportType.ctScan:
        return 'CT Scan';
      case ReportType.ecg:
        return 'ECG';
      case ReportType.ultrasound:
        return 'Ultrasound';
      case ReportType.biopsy:
        return 'Biopsy';
      case ReportType.pathology:
        return 'Pathology';
      case ReportType.prescription:
        return 'Prescription';
      case ReportType.discharge:
        return 'Discharge Summary';
      case ReportType.consultation:
        return 'Consultation';
      case ReportType.vaccination:
        return 'Vaccination';
      case ReportType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ReportType.bloodTest:
        return '🩸';
      case ReportType.urineTest:
        return '🧪';
      case ReportType.xray:
        return '🦴';
      case ReportType.mri:
        return '🧠';
      case ReportType.ctScan:
        return '💻';
      case ReportType.ecg:
        return '❤️';
      case ReportType.ultrasound:
        return '👶';
      case ReportType.biopsy:
        return '🔬';
      case ReportType.pathology:
        return '📋';
      case ReportType.prescription:
        return '💊';
      case ReportType.discharge:
        return '🏥';
      case ReportType.consultation:
        return '👨‍⚕️';
      case ReportType.vaccination:
        return '💉';
      case ReportType.other:
        return '📄';
    }
  }

  String get color {
    switch (this) {
      case ReportType.bloodTest:
        return '#F44336'; // Red
      case ReportType.urineTest:
        return '#FF9800'; // Orange
      case ReportType.xray:
        return '#9E9E9E'; // Grey
      case ReportType.mri:
        return '#9C27B0'; // Purple
      case ReportType.ctScan:
        return '#3F51B5'; // Indigo
      case ReportType.ecg:
        return '#E91E63'; // Pink
      case ReportType.ultrasound:
        return '#2196F3'; // Blue
      case ReportType.biopsy:
        return '#795548'; // Brown
      case ReportType.pathology:
        return '#607D8B'; // Blue Grey
      case ReportType.prescription:
        return '#4CAF50'; // Green
      case ReportType.discharge:
        return '#00BCD4'; // Cyan
      case ReportType.consultation:
        return '#009688'; // Teal
      case ReportType.vaccination:
        return '#CDDC39'; // Lime
      case ReportType.other:
        return '#757575'; // Grey
    }
  }
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.uploaded:
        return 'Uploaded';
      case ReportStatus.processing:
        return 'Processing';
      case ReportStatus.processed:
        return 'Processed';
      case ReportStatus.failed:
        return 'Failed';
      case ReportStatus.archived:
        return 'Archived';
    }
  }

  String get color {
    switch (this) {
      case ReportStatus.uploaded:
        return '#2196F3'; // Blue
      case ReportStatus.processing:
        return '#FF9800'; // Orange
      case ReportStatus.processed:
        return '#4CAF50'; // Green
      case ReportStatus.failed:
        return '#F44336'; // Red
      case ReportStatus.archived:
        return '#9E9E9E'; // Grey
    }
  }
}

extension ReportPrivacyExtension on ReportPrivacy {
  String get displayName {
    switch (this) {
      case ReportPrivacy.private:
        return 'Private';
      case ReportPrivacy.sharedWithAsha:
        return 'Shared with ASHA';
      case ReportPrivacy.sharedWithFamily:
        return 'Shared with Family';
      case ReportPrivacy.public:
        return 'Public';
    }
  }

  String get icon {
    switch (this) {
      case ReportPrivacy.private:
        return '🔒';
      case ReportPrivacy.sharedWithAsha:
        return '👩‍⚕️';
      case ReportPrivacy.sharedWithFamily:
        return '👨‍👩‍👧‍👦';
      case ReportPrivacy.public:
        return '🌐';
    }
  }
}

// Report summary for dashboard
class ReportSummary {
  final int totalReports;
  final int recentReports;
  final int processingReports;
  final int failedReports;
  final List<ReportModel> latestReports;
  final Map<ReportType, int> reportsByType;
  final Map<String, int> reportsByMonth;

  ReportSummary({
    required this.totalReports,
    required this.recentReports,
    required this.processingReports,
    required this.failedReports,
    required this.latestReports,
    required this.reportsByType,
    required this.reportsByMonth,
  });

  bool get hasReports => totalReports > 0;
  bool get hasFailedReports => failedReports > 0;
  bool get hasProcessingReports => processingReports > 0;
}

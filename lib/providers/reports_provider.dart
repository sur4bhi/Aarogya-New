import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/services/firebase_service.dart';
import '../core/services/ocr_service.dart';
import '../models/medical_ocr_models.dart';

class ReportsProvider extends ChangeNotifier {
  final List<MedicalReportModel> _reports = [];
  bool _isProcessing = false;
  double _ocrProgress = 0.0;

  // Getters
  List<MedicalReportModel> get reports => List.unmodifiable(_reports);
  List<MedicalReportModel> get recentReports => _reports
      .where((r) => DateTime.now().difference(r.reportDate).inDays <= 30)
      .toList()
    ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
  bool get isProcessing => _isProcessing;
  double get ocrProgress => _ocrProgress;
  int get pendingSyncCount => _reports.where((r) => r.needsSync).length;

  void updateOCRProgress(double progress) {
    _ocrProgress = progress;
    notifyListeners();
  }

  Future<void> loadReports() async {
    final user = FirebaseService.getCurrentUser();
    if (user == null) return;
    final qs = await FirebaseService.getCollectionWithQuery(
      'medical_reports',
      [QueryFilter(field: 'userId', value: user.uid)],
    );
    _reports
      ..clear()
      ..addAll(qs.docs.map((d) => MedicalReportModel.fromFirestore(d.id, d.data() as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<String> uploadReport(List<String> imagePaths, String reportType) async {
    final user = FirebaseService.getCurrentUser();
    if (user == null || imagePaths.isEmpty) throw Exception('No user or images');

    final now = DateTime.now();
    final docRef = await FirebaseService.addDocument('medical_reports', {
      'userId': user.uid,
      'title': 'Medical Report',
      'reportType': reportType,
      'reportDate': Timestamp.fromDate(now),
      'files': {
        'originalPath': '',
        'imagePaths': [],
      },
      'ocrData': {},
      'metadata': {
        'isReviewedByUser': false,
        'sharedWithAsha': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'needsSync': false,
      'syncStatus': 'pending',
    });

    final reportId = docRef.id;
    final storageBase = 'reports/${user.uid}/$reportId';

    // Upload files
    final List<String> uploadedImagePaths = [];
    for (int i = 0; i < imagePaths.length; i++) {
      final p = imagePaths[i];
      final isFirst = i == 0;
      final pathInStorage = isFirst ? '$storageBase/original.jpg' : '$storageBase/page_${i + 1}.jpg';
      final url = await FirebaseService.uploadFile(pathInStorage, File(p));
      uploadedImagePaths.add(url);
    }

    // Update Firestore with file info
    await FirebaseService.updateDocument('medical_reports', reportId, {
      'files': {
        'originalPath': uploadedImagePaths.first,
        'imagePaths': uploadedImagePaths,
      },
      'metadata.updatedAt': FieldValue.serverTimestamp(),
    });

    final model = MedicalReportModel(
      id: reportId,
      userId: user.uid,
      title: 'Medical Report',
      reportType: reportType,
      reportDate: now,
      originalFilePath: uploadedImagePaths.first,
      imagePaths: uploadedImagePaths,
      extractedText: null,
      vitalsExtracted: null,
      medications: null,
      diagnoses: null,
      recommendations: null,
      createdAt: now,
      updatedAt: now,
      needsSync: false,
      syncStatus: 'pending',
    );

    _reports.insert(0, model);
    notifyListeners();
    return reportId;
  }

  Future<void> processWithOCR(String reportId) async {
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx == -1) return;
    final report = _reports[idx];
    if (report.imagePaths == null || report.imagePaths!.isEmpty) return;

    try {
      _isProcessing = true;
      updateOCRProgress(0.05);

      final ocr = await extractMedicalData(report.imagePaths!);

      final vitals = <String, dynamic>{
        if (ocr.systolicBP != null) 'systolicBP': ocr.systolicBP,
        if (ocr.diastolicBP != null) 'diastolicBP': ocr.diastolicBP,
        if (ocr.bloodSugar != null) 'bloodSugar': ocr.bloodSugar,
        if (ocr.cholesterol != null) 'cholesterol': ocr.cholesterol,
        if (ocr.hemoglobin != null) 'hemoglobin': ocr.hemoglobin,
        if (ocr.weight != null) 'weight': ocr.weight,
        if (ocr.height != null) 'height': ocr.height,
      };

      await FirebaseService.updateDocument('medical_reports', reportId, {
        'ocrData': {
          'extractedText': ocr.rawText,
          'confidence': ocr.confidence,
          'vitalsExtracted': vitals,
          'medications': ocr.medications?.map((m) => m.name).toList(),
          'diagnoses': ocr.conditions,
          'recommendations': ocr.doctorAdvice,
        },
        'metadata.updatedAt': FieldValue.serverTimestamp(),
      });

      _reports[idx] = MedicalReportModel(
        id: report.id,
        userId: report.userId,
        title: report.title,
        reportType: report.reportType,
        reportDate: report.reportDate,
        hospitalName: report.hospitalName,
        doctorName: report.doctorName,
        originalFilePath: report.originalFilePath,
        imagePaths: report.imagePaths,
        extractedText: ocr.rawText,
        vitalsExtracted: vitals,
        medications: ocr.medications?.map((e) => e.name).toList(),
        diagnoses: ocr.conditions,
        recommendations: ocr.doctorAdvice,
        ocrConfidence: ocr.confidence,
        isReviewedByUser: report.isReviewedByUser,
        sharedWithAsha: report.sharedWithAsha,
        createdAt: report.createdAt,
        updatedAt: DateTime.now(),
        needsSync: false,
        syncStatus: 'synced',
      );
    } finally {
      _isProcessing = false;
      updateOCRProgress(1.0);
      notifyListeners();
    }
  }

  Future<MedicalOCRResult> extractMedicalData(List<String> imagePaths) async {
    updateOCRProgress(0.1);
    // For now, process only first page, can be extended to multi-page aggregation
    final imagePath = imagePaths.first;
    final result = await OCRService.processMedicalDocument(imagePath);
    updateOCRProgress(0.9);
    return result;
  }

  Future<void> updateReportData(String reportId, MedicalOCRResult data) async {
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx == -1) return;

    final vitals = <String, dynamic>{
      if (data.systolicBP != null) 'systolicBP': data.systolicBP,
      if (data.diastolicBP != null) 'diastolicBP': data.diastolicBP,
      if (data.bloodSugar != null) 'bloodSugar': data.bloodSugar,
      if (data.cholesterol != null) 'cholesterol': data.cholesterol,
      if (data.hemoglobin != null) 'hemoglobin': data.hemoglobin,
      if (data.weight != null) 'weight': data.weight,
      if (data.height != null) 'height': data.height,
    };

    await FirebaseService.updateDocument('medical_reports', reportId, {
      'ocrData': {
        'extractedText': data.rawText,
        'confidence': data.confidence,
        'vitalsExtracted': vitals,
        'medications': data.medications?.map((m) => m.name).toList(),
        'diagnoses': data.conditions,
        'recommendations': data.doctorAdvice,
      },
      'metadata.updatedAt': FieldValue.serverTimestamp(),
    });

    final r = _reports[idx];
    _reports[idx] = MedicalReportModel(
      id: r.id,
      userId: r.userId,
      title: r.title,
      reportType: r.reportType,
      reportDate: r.reportDate,
      hospitalName: r.hospitalName,
      doctorName: r.doctorName,
      originalFilePath: r.originalFilePath,
      imagePaths: r.imagePaths,
      extractedText: data.rawText,
      vitalsExtracted: vitals,
      medications: data.medications?.map((e) => e.name).toList(),
      diagnoses: data.conditions,
      recommendations: data.doctorAdvice,
      ocrConfidence: data.confidence,
      isReviewedByUser: r.isReviewedByUser,
      sharedWithAsha: r.sharedWithAsha,
      createdAt: r.createdAt,
      updatedAt: DateTime.now(),
      needsSync: false,
      syncStatus: 'synced',
    );
    notifyListeners();
  }

  Future<void> deleteReport(String reportId) async {
    await FirebaseService.deleteDocument('medical_reports', reportId);
    _reports.removeWhere((r) => r.id == reportId);
    notifyListeners();
  }

  // Integrations (stubs; wire to your existing Vitals/Reminders providers externally)
  Future<void> addVitalsFromReport(String reportId) async {}
  Future<void> addMedicationsToReminders(String reportId) async {}

  Future<void> shareWithAsha(String reportId) async {
    await FirebaseService.updateDocument('medical_reports', reportId, {
      'metadata.sharedWithAsha': true,
      'metadata.updatedAt': FieldValue.serverTimestamp(),
    });
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final r = _reports[idx];
      _reports[idx] = MedicalReportModel(
        id: r.id,
        userId: r.userId,
        title: r.title,
        reportType: r.reportType,
        reportDate: r.reportDate,
        hospitalName: r.hospitalName,
        doctorName: r.doctorName,
        originalFilePath: r.originalFilePath,
        imagePaths: r.imagePaths,
        extractedText: r.extractedText,
        vitalsExtracted: r.vitalsExtracted,
        medications: r.medications,
        diagnoses: r.diagnoses,
        recommendations: r.recommendations,
        ocrConfidence: r.ocrConfidence,
        isReviewedByUser: r.isReviewedByUser,
        sharedWithAsha: true,
        createdAt: r.createdAt,
        updatedAt: DateTime.now(),
        needsSync: r.needsSync,
        syncStatus: r.syncStatus,
      );
      notifyListeners();
    }
  }

  Future<void> syncReports() async {
    // Placeholder: rely on Firebase live updates for now
  }
}

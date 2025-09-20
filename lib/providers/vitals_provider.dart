import 'package:flutter/foundation.dart';
import '../core/services/local_storage.dart';
import '../core/services/sync_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/health_utils.dart';
import '../models/vitals_model.dart';

class VitalsProvider extends ChangeNotifier {
  final List<VitalsModel> _vitalsHistory = [];
  VitalsModel? _latestVitals;
  bool _isLoading = false;
  String? _errorMessage;

  List<VitalsModel> get vitalsHistory => List.unmodifiable(_vitalsHistory);
  VitalsModel? get latestVitals => _latestVitals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadVitalsHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final raw = LocalStorageService.getAllVitalsRecords();
      final items = <VitalsModel>[];
      for (final m in raw) {
        try {
          items.add(VitalsModel.fromJson(Map<String, dynamic>.from(m)));
        } catch (_) {
          // skip malformed entries
        }
      }
      // Sort by timestamp desc
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _vitalsHistory
        ..clear()
        ..addAll(items);
      _latestVitals = _vitalsHistory.isNotEmpty ? _vitalsHistory.first : null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVitalsRecord(VitalsModel vitals) async {
    try {
      // Persist locally for offline-first
      final id = vitals.id;
      final json = vitals.toJson();
      json['needsSync'] = true;
      await LocalStorageService.saveVitalsRecord(id, json);

      // Update in-memory state
      _vitalsHistory.insert(0, vitals);
      _latestVitals = vitals;
      notifyListeners();

      // Health assessment and alerting
      _maybeTriggerHealthAlert(vitals);

      // Attempt immediate sync if online
      if (SyncService.isOnline) {
        await SyncService.syncVitalsData();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  VitalsModel? getLatestVitals() => _latestVitals;

  List<VitalsModel> getVitalsInRange(DateTime start, DateTime end) {
    return _vitalsHistory
        .where((v) => !v.timestamp.isBefore(start) && !v.timestamp.isAfter(end))
        .toList();
  }

  Map<String, dynamic> getHealthSummary() {
    if (_latestVitals == null) {
      return {
        'overallStatus': 'Unknown',
        'bpStatus': 'Unknown',
        'glucoseStatus': 'Unknown',
        'weight': null,
      };
    }

    final latest = _latestVitals!;
    String bpStatus = 'Unknown';
    String glucoseStatus = 'Unknown';
    double? weight;

    // Find latest BP
    final latestBp = _vitalsHistory.firstWhere(
      (v) => v.type == VitalType.bloodPressure,
      orElse: () => latest,
    );
    if (latestBp.type == VitalType.bloodPressure &&
        latestBp.systolicBP != null &&
        latestBp.diastolicBP != null) {
      bpStatus = HealthUtils.getBloodPressureCategory(
        latestBp.systolicBP!,
        latestBp.diastolicBP!,
      );
    }

    // Find latest glucose
    final latestGlucose = _vitalsHistory.firstWhere(
      (v) => v.type == VitalType.bloodGlucose,
      orElse: () => latest,
    );
    if (latestGlucose.type == VitalType.bloodGlucose &&
        latestGlucose.bloodGlucose != null) {
      glucoseStatus = HealthUtils.getBloodGlucoseCategory(
        latestGlucose.bloodGlucose!,
        (latestGlucose.glucoseType ?? 'random'),
      );
    }

    // Find latest weight
    final latestWeight = _vitalsHistory.firstWhere(
      (v) => v.type == VitalType.weight,
      orElse: () => latest,
    );
    if (latestWeight.type == VitalType.weight) {
      weight = latestWeight.weight;
    }

    return {
      'overallStatus': latest.healthStatus.displayName,
      'bpStatus': bpStatus,
      'glucoseStatus': glucoseStatus,
      'weight': weight,
    };
  }

  bool hasAbnormalReadings(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _vitalsHistory.any((v) {
      final status = v.healthStatus;
      return v.timestamp.isAfter(cutoff) &&
          (status == HealthStatus.critical ||
              status == HealthStatus.high ||
              status == HealthStatus.elevated);
    });
  }

  void _maybeTriggerHealthAlert(VitalsModel v) {
    switch (v.type) {
      case VitalType.bloodPressure:
        if (v.systolicBP != null && v.diastolicBP != null) {
          final category = HealthUtils.getBloodPressureCategory(
              v.systolicBP!, v.diastolicBP!);
          if (category != 'Normal') {
            NotificationService.showHealthAlert(
              title: 'Blood Pressure Alert',
              message: 'BP ${v.bloodPressureString} - $category',
            );
          }
        }
        break;
      case VitalType.bloodGlucose:
        if (v.bloodGlucose != null) {
          final category = HealthUtils.getBloodGlucoseCategory(
              v.bloodGlucose!, (v.glucoseType ?? 'random'));
          if (category == 'Prediabetes' || category == 'Diabetes' || category == 'Low') {
            NotificationService.showHealthAlert(
              title: 'Blood Glucose Alert',
              message: 'Glucose ${v.bloodGlucose!.toStringAsFixed(0)} mg/dL - $category',
            );
          }
        }
        break;
      default:
        break;
    }
  }
}

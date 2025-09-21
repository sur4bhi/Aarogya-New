import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/patient_alert_model.dart';
import '../models/connected_patient_model.dart';
import '../models/vitals_model.dart';
import '../core/services/local_storage.dart';
import '../core/services/notification_service.dart';

class SmartNotificationState {
  final List<PatientAlert> activeAlerts;
  final List<AlertRule> alertRules;
  final Map<String, List<AlertThreshold>> patientThresholds;
  final List<PatientAlert> alertHistory;
  final bool isMonitoring;
  final String? error;
  final DateTime lastCheck;

  const SmartNotificationState({
    this.activeAlerts = const [],
    this.alertRules = const [],
    this.patientThresholds = const {},
    this.alertHistory = const [],
    this.isMonitoring = false,
    this.error,
    required this.lastCheck,
  });

  SmartNotificationState copyWith({
    List<PatientAlert>? activeAlerts,
    List<AlertRule>? alertRules,
    Map<String, List<AlertThreshold>>? patientThresholds,
    List<PatientAlert>? alertHistory,
    bool? isMonitoring,
    String? error,
    DateTime? lastCheck,
  }) {
    return SmartNotificationState(
      activeAlerts: activeAlerts ?? this.activeAlerts,
      alertRules: alertRules ?? this.alertRules,
      patientThresholds: patientThresholds ?? this.patientThresholds,
      alertHistory: alertHistory ?? this.alertHistory,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      error: error ?? this.error,
      lastCheck: lastCheck ?? this.lastCheck,
    );
  }
}

class SmartNotificationSystem with ChangeNotifier {
  SmartNotificationState _state = SmartNotificationState(lastCheck: DateTime.now());
  Timer? _monitoringTimer;
  StreamController<PatientAlert>? _alertStreamController;

  // Getters
  SmartNotificationState get state => _state;
  Stream<PatientAlert> get alertStream => _alertStreamController?.stream ?? const Stream.empty();
  List<PatientAlert> get activeAlerts => _state.activeAlerts;
  List<PatientAlert> get criticalAlerts => _state.activeAlerts.where((alert) => alert.isCritical).toList();
  List<PatientAlert> get emergencyAlerts => _state.activeAlerts.where((alert) => alert.isEmergency).toList();
  int get totalAlerts => _state.activeAlerts.length;
  int get unreadAlerts => _state.activeAlerts.where((alert) => !alert.isRead).length;
  bool get hasEmergency => emergencyAlerts.isNotEmpty;
  bool get isMonitoring => _state.isMonitoring;

  SmartNotificationSystem() {
    _alertStreamController = StreamController<PatientAlert>.broadcast();
    _initializeSystem();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _alertStreamController?.close();
    super.dispose();
  }

  Future<void> _initializeSystem() async {
    await _loadAlertRules();
    await _loadPatientThresholds();
    await _loadActiveAlerts();
    _startMonitoring();
  }

  void _startMonitoring() {
    _setState(_state.copyWith(isMonitoring: true));
    
    // Start continuous monitoring timer (every 30 seconds)
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processPatientData();
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _setState(_state.copyWith(isMonitoring: false));
  }

  // Core Alert Processing Pipeline
  Future<void> _processPatientData() async {
    try {
      _setState(_state.copyWith(lastCheck: DateTime.now()));
      
      // Load patient data for monitoring
      final patients = await _loadPatientsForMonitoring();
      
      for (final patient in patients) {
        await _checkVitalThresholds(patient);
        await _checkMissedCheckIns(patient);
        await _checkMedicationAdherence(patient);
        await _checkAppointmentReminders(patient);
        await _detectPatterns(patient);
      }

      // Clean up resolved/old alerts
      await _cleanupOldAlerts();
      
    } catch (e) {
      _setState(_state.copyWith(error: 'Alert processing failed: $e'));
    }
  }

  // Vital Thresholds Monitoring
  Future<void> _checkVitalThresholds(ConnectedPatient patient) async {
    final thresholds = _state.patientThresholds[patient.patientId] ?? [];
    if (thresholds.isEmpty) return;

    final latestVitals = _getLatestVitals(patient);
    if (latestVitals == null) return;

    for (final threshold in thresholds.where((t) => t.isEnabled)) {
      final vitalValue = _getVitalValue(latestVitals, threshold.vitalType);
      if (vitalValue == null) continue;

      // Check for critical thresholds
      if (vitalValue >= threshold.criticalHigh || vitalValue <= threshold.criticalLow) {
        await _createAlert(
          patient: patient,
          alertType: _getCriticalAlertType(threshold.vitalType),
          severity: AlertSeverity.critical,
          triggerValue: vitalValue,
          thresholdValue: vitalValue >= threshold.criticalHigh ? threshold.criticalHigh : threshold.criticalLow,
          units: _getVitalUnits(threshold.vitalType),
        );
      }
      // Check for warning thresholds
      else if (vitalValue >= threshold.warningHigh || vitalValue <= threshold.warningLow) {
        await _createAlert(
          patient: patient,
          alertType: _getWarningAlertType(threshold.vitalType),
          severity: AlertSeverity.high,
          triggerValue: vitalValue,
          thresholdValue: vitalValue >= threshold.warningHigh ? threshold.warningHigh : threshold.warningLow,
          units: _getVitalUnits(threshold.vitalType),
        );
      }
    }
  }

  // Check-in Monitoring
  Future<void> _checkMissedCheckIns(ConnectedPatient patient) async {
    final now = DateTime.now();
    final daysSinceLastCheckIn = now.difference(patient.lastCheckIn).inDays;
    
    if (daysSinceLastCheckIn >= 1) {
      await _createAlert(
        patient: patient,
        alertType: AlertType.missedDailyCheckIn,
        severity: daysSinceLastCheckIn >= 3 ? AlertSeverity.critical : AlertSeverity.high,
        metadata: {'daysSinceLastCheckIn': daysSinceLastCheckIn},
      );
    }

    if (daysSinceLastCheckIn >= 7) {
      await _createAlert(
        patient: patient,
        alertType: AlertType.patientUnreachable,
        severity: AlertSeverity.critical,
        metadata: {'daysSinceLastCheckIn': daysSinceLastCheckIn},
      );
    }
  }

  // Medication Adherence Tracking
  Future<void> _checkMedicationAdherence(ConnectedPatient patient) async {
    // Check medication adherence score
    if (patient.medicationAdherence < 70.0) {
      await _createAlert(
        patient: patient,
        alertType: AlertType.lowAdherenceScore,
        severity: patient.medicationAdherence < 50.0 ? AlertSeverity.critical : AlertSeverity.high,
        triggerValue: patient.medicationAdherence,
        thresholdValue: 70.0,
        units: '%',
      );
    }

    // Check for missed critical medications (mock implementation)
    final missedCriticalMeds = await _checkMissedCriticalMedications(patient);
    for (final medication in missedCriticalMeds) {
      await _createAlert(
        patient: patient,
        alertType: AlertType.criticalMedicationDelayed,
        severity: AlertSeverity.critical,
        metadata: {
          'medicationName': medication['name'],
          'hoursDelayed': medication['hoursDelayed'],
        },
      );
    }
  }

  // Appointment Reminders
  Future<void> _checkAppointmentReminders(ConnectedPatient patient) async {
    final upcomingAppointments = await _getUpcomingAppointments(patient);
    
    for (final appointment in upcomingAppointments) {
      final appointmentDate = appointment['date'] as DateTime;
      final daysBefore = appointmentDate.difference(DateTime.now()).inDays;
      
      if (daysBefore == 1) {
        await _createAlert(
          patient: patient,
          alertType: AlertType.upcomingAppointment,
          severity: AlertSeverity.medium,
          metadata: {
            'appointmentDate': appointmentDate.toIso8601String(),
            'appointmentType': appointment['type'],
          },
        );
      }
    }
  }

  // Pattern Detection
  Future<void> _detectPatterns(ConnectedPatient patient) async {
    final recentVitals = patient.vitalsHistory.take(7).toList();
    if (recentVitals.length < 5) return;

    // Check for declining trends in blood pressure
    final bpReadings = recentVitals.map((v) => v.systolicBP?.toDouble() ?? 0).where((bp) => bp > 0).toList();
    if (bpReadings.length >= 3 && _isConsistentlyIncreasing(bpReadings)) {
      await _createAlert(
        patient: patient,
        alertType: AlertType.decliningTrend,
        severity: AlertSeverity.medium,
        metadata: {
          'vitalType': 'bloodPressure',
          'trendDirection': 'increasing',
          'readings': bpReadings,
        },
      );
    }

    // Check for glucose pattern concerns
    final glucoseReadings = recentVitals.map((v) => v.bloodGlucose ?? 0).where((g) => g > 0).toList();
    if (glucoseReadings.length >= 3 && _isAbnormalPattern(glucoseReadings)) {
      await _createAlert(
        patient: patient,
        alertType: AlertType.abnormalPattern,
        severity: AlertSeverity.high,
        metadata: {
          'vitalType': 'bloodGlucose',
          'pattern': 'abnormal_variation',
          'readings': glucoseReadings,
        },
      );
    }
  }

  // Alert Creation
  Future<void> _createAlert({
    required ConnectedPatient patient,
    required AlertType alertType,
    required AlertSeverity severity,
    double? triggerValue,
    double? thresholdValue,
    String? units,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if similar alert already exists
    if (_hasExistingSimilarAlert(patient.patientId, alertType)) return;

    final alert = PatientAlert(
      alertId: _generateAlertId(),
      patientId: patient.patientId,
      patientName: patient.patientName,
      alertType: alertType,
      alertCategory: _getAlertCategory(alertType),
      severity: severity,
      timestamp: DateTime.now(),
      triggerValue: triggerValue,
      thresholdValue: thresholdValue,
      units: units,
      metadata: metadata,
      priority: _getPriority(severity),
      requiresAcknowledgment: severity == AlertSeverity.critical,
      escalationTime: _getEscalationTime(severity),
    );

    // Add to active alerts
    final updatedAlerts = [..._state.activeAlerts, alert];
    _setState(_state.copyWith(activeAlerts: updatedAlerts));

    // Send notification
    await _sendNotification(alert);

    // Add to stream
    _alertStreamController?.add(alert);

    // Save to storage
    await _saveAlertsToStorage();
  }

  // Emergency SOS Handling
  Future<void> handleEmergencySOS({
    required String patientId,
    required String patientName,
    String? location,
    List<String>? emergencyContacts,
  }) async {
    final alert = PatientAlert(
      alertId: _generateAlertId(),
      patientId: patientId,
      patientName: patientName,
      alertType: AlertType.sosActivated,
      alertCategory: AlertCategory.emergencySOS,
      severity: AlertSeverity.critical,
      timestamp: DateTime.now(),
      location: location,
      emergencyContacts: emergencyContacts,
      priority: NotificationPriority.emergency,
      requiresAcknowledgment: true,
      escalationTime: const Duration(minutes: 5),
    );

    // Add to active alerts immediately
    final updatedAlerts = [..._state.activeAlerts, alert];
    _setState(_state.copyWith(activeAlerts: updatedAlerts));

    // Send immediate multi-channel notifications
    await _sendEmergencyNotification(alert);

    // Add to stream
    _alertStreamController?.add(alert);

    // Save immediately
    await _saveAlertsToStorage();
  }

  // Alert Management
  Future<void> acknowledgeAlert(String alertId) async {
    final alertIndex = _state.activeAlerts.indexWhere((alert) => alert.alertId == alertId);
    if (alertIndex == -1) return;

    final updatedAlert = _state.activeAlerts[alertIndex].copyWith(
      isRead: true,
      acknowledgedAt: DateTime.now(),
      status: AlertStatus.acknowledged,
    );

    final updatedAlerts = [..._state.activeAlerts];
    updatedAlerts[alertIndex] = updatedAlert;

    _setState(_state.copyWith(activeAlerts: updatedAlerts));
    await _saveAlertsToStorage();
  }

  Future<void> resolveAlert(String alertId, String action, String? notes) async {
    final alertIndex = _state.activeAlerts.indexWhere((alert) => alert.alertId == alertId);
    if (alertIndex == -1) return;

    final updatedAlert = _state.activeAlerts[alertIndex].copyWith(
      status: AlertStatus.resolved,
      isActionTaken: true,
      actionTaken: action,
      notes: notes,
      resolvedAt: DateTime.now(),
    );

    // Move to history and remove from active
    final updatedActiveAlerts = _state.activeAlerts.where((alert) => alert.alertId != alertId).toList();
    final updatedHistory = [..._state.alertHistory, updatedAlert];

    _setState(_state.copyWith(
      activeAlerts: updatedActiveAlerts,
      alertHistory: updatedHistory,
    ));

    await _saveAlertsToStorage();
  }

  Future<void> dismissAlert(String alertId) async {
    final updatedAlerts = _state.activeAlerts.where((alert) => alert.alertId != alertId).toList();
    _setState(_state.copyWith(activeAlerts: updatedAlerts));
    await _saveAlertsToStorage();
  }

  // Threshold Management
  Future<void> updatePatientThresholds(String patientId, List<AlertThreshold> thresholds) async {
    final updatedThresholds = {..._state.patientThresholds};
    updatedThresholds[patientId] = thresholds;
    
    _setState(_state.copyWith(patientThresholds: updatedThresholds));
    await _saveThresholdsToStorage();
  }

  Future<void> setDefaultThresholds(String patientId) async {
    final defaultThresholds = [
      AlertThreshold.defaultBloodPressure(patientId),
      AlertThreshold.defaultBloodGlucose(patientId),
      AlertThreshold.defaultHeartRate(patientId),
    ];

    await updatePatientThresholds(patientId, defaultThresholds);
  }

  // Filtering and Search
  List<PatientAlert> getAlertsByCategory(AlertCategory category) {
    return _state.activeAlerts.where((alert) => alert.alertCategory == category).toList();
  }

  List<PatientAlert> getAlertsBySeverity(AlertSeverity severity) {
    return _state.activeAlerts.where((alert) => alert.severity == severity).toList();
  }

  List<PatientAlert> getAlertsForPatient(String patientId) {
    return _state.activeAlerts.where((alert) => alert.patientId == patientId).toList();
  }

  List<PatientAlert> searchAlerts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _state.activeAlerts.where((alert) {
      return alert.patientName.toLowerCase().contains(lowercaseQuery) ||
             alert.title.toLowerCase().contains(lowercaseQuery) ||
             alert.message.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Analytics
  Map<String, int> getAlertStatistics() {
    final stats = <String, int>{};
    
    for (final alert in _state.activeAlerts) {
      final key = alert.alertCategory.name;
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return stats;
  }

  List<PatientAlert> getOverdueAlerts() {
    return _state.activeAlerts.where((alert) => alert.isOverdue).toList();
  }

  // Private Helper Methods
  Future<List<ConnectedPatient>> _loadPatientsForMonitoring() async {
    try {
      final data = await LocalStorageService.getSecureData('connected_patients');
      if (data != null && data is List) {
        return data.map((json) => ConnectedPatient.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading patients for monitoring: $e');
    }
    
    // Return sample patients for demo
    return _generateSamplePatients();
  }

  VitalsModel? _getLatestVitals(ConnectedPatient patient) {
    return patient.vitalsHistory.isNotEmpty ? patient.vitalsHistory.first : null;
  }

  double? _getVitalValue(VitalsModel vitals, String vitalType) {
    switch (vitalType) {
      case 'bloodPressure':
        return vitals.systolicBP?.toDouble();
      case 'bloodGlucose':
        return vitals.bloodGlucose;
      case 'heartRate':
        return vitals.heartRate;
      default:
        return null;
    }
  }

  String _getVitalUnits(String vitalType) {
    switch (vitalType) {
      case 'bloodPressure':
        return 'mmHg';
      case 'bloodGlucose':
        return 'mg/dL';
      case 'heartRate':
        return 'bpm';
      default:
        return '';
    }
  }

  AlertType _getCriticalAlertType(String vitalType) {
    switch (vitalType) {
      case 'bloodPressure':
        return AlertType.bloodPressureCritical;
      case 'bloodGlucose':
        return AlertType.bloodGlucoseCritical;
      case 'heartRate':
        return AlertType.heartRateCritical;
      default:
        return AlertType.bloodPressureCritical;
    }
  }

  AlertType _getWarningAlertType(String vitalType) {
    switch (vitalType) {
      case 'bloodPressure':
        return AlertType.bloodPressureWarning;
      case 'bloodGlucose':
        return AlertType.bloodGlucoseWarning;
      case 'heartRate':
        return AlertType.heartRateWarning;
      default:
        return AlertType.bloodPressureWarning;
    }
  }

  AlertCategory _getAlertCategory(AlertType alertType) {
    switch (alertType) {
      case AlertType.bloodPressureCritical:
      case AlertType.bloodPressureWarning:
      case AlertType.bloodGlucoseCritical:
      case AlertType.bloodGlucoseWarning:
      case AlertType.heartRateCritical:
      case AlertType.heartRateWarning:
        return AlertCategory.criticalVitals;
      case AlertType.missedDailyCheckIn:
      case AlertType.patientUnreachable:
        return AlertCategory.missedCheckIn;
      case AlertType.sosActivated:
        return AlertCategory.emergencySOS;
      case AlertType.medicationMissed:
      case AlertType.criticalMedicationDelayed:
      case AlertType.lowAdherenceScore:
        return AlertCategory.medicationAdherence;
      case AlertType.upcomingAppointment:
        return AlertCategory.appointmentReminder;
      default:
        return AlertCategory.patternConcern;
    }
  }

  NotificationPriority _getPriority(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return NotificationPriority.emergency;
      case AlertSeverity.high:
        return NotificationPriority.urgent;
      case AlertSeverity.medium:
        return NotificationPriority.normal;
      case AlertSeverity.low:
        return NotificationPriority.background;
    }
  }

  Duration _getEscalationTime(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Duration(minutes: 15);
      case AlertSeverity.high:
        return const Duration(hours: 2);
      case AlertSeverity.medium:
        return const Duration(hours: 24);
      case AlertSeverity.low:
        return const Duration(hours: 72);
    }
  }

  bool _hasExistingSimilarAlert(String patientId, AlertType alertType) {
    return _state.activeAlerts.any((alert) =>
        alert.patientId == patientId &&
        alert.alertType == alertType &&
        alert.isActive);
  }

  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  bool _isConsistentlyIncreasing(List<double> values) {
    if (values.length < 3) return false;
    for (int i = 1; i < values.length; i++) {
      if (values[i] <= values[i - 1]) return false;
    }
    return true;
  }

  bool _isAbnormalPattern(List<double> values) {
    if (values.length < 3) return false;
    final average = values.reduce((a, b) => a + b) / values.length;
    final variations = values.map((v) => (v - average).abs()).toList();
    final avgVariation = variations.reduce((a, b) => a + b) / variations.length;
    return avgVariation > average * 0.3; // 30% variation threshold
  }

  Future<List<Map<String, dynamic>>> _checkMissedCriticalMedications(ConnectedPatient patient) async {
    // Mock implementation - in real app, this would check medication schedule
    final random = Random();
    if (random.nextDouble() < 0.2) { // 20% chance of missed medication
      return [
        {
          'name': 'इंसुलिन',
          'hoursDelayed': random.nextInt(12) + 1,
        }
      ];
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _getUpcomingAppointments(ConnectedPatient patient) async {
    // Mock implementation - in real app, this would check appointment system
    final random = Random();
    if (random.nextDouble() < 0.3) { // 30% chance of upcoming appointment
      return [
        {
          'date': DateTime.now().add(Duration(days: random.nextInt(3) + 1)),
          'type': 'नियमित जांच',
        }
      ];
    }
    return [];
  }

  Future<void> _sendNotification(PatientAlert alert) async {
    await NotificationService.showLocalNotification(
      title: alert.title,
      body: alert.message,
      data: {
        'alertId': alert.alertId,
        'patientId': alert.patientId,
        'type': 'patient_alert',
      },
    );
  }

  Future<void> _sendEmergencyNotification(PatientAlert alert) async {
    // Send immediate notification
    await NotificationService.showLocalNotification(
      title: '🚨 आपातकाल - ${alert.title}',
      body: alert.message,
      data: {
        'alertId': alert.alertId,
        'patientId': alert.patientId,
        'type': 'emergency_alert',
        'priority': 'emergency',
      },
    );

    // In a real implementation, also send SMS and potentially make calls
    // await SMSService.sendEmergencySMS(alert);
    // await CallService.makeEmergencyCall(alert);
  }

  Future<void> _cleanupOldAlerts() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    // Move old resolved alerts to history
    final oldResolvedAlerts = _state.activeAlerts
        .where((alert) => alert.isResolved && alert.resolvedAt!.isBefore(cutoffDate))
        .toList();

    if (oldResolvedAlerts.isNotEmpty) {
      final updatedActiveAlerts = _state.activeAlerts
          .where((alert) => !oldResolvedAlerts.contains(alert))
          .toList();
      
      final updatedHistory = [..._state.alertHistory, ...oldResolvedAlerts];

      _setState(_state.copyWith(
        activeAlerts: updatedActiveAlerts,
        alertHistory: updatedHistory,
      ));

      await _saveAlertsToStorage();
    }
  }

  // Storage Methods
  Future<void> _loadAlertRules() async {
    try {
      final data = await LocalStorageService.getSecureData('alert_rules');
      if (data != null && data is List) {
        final rules = data.map((json) => AlertRule(
          ruleId: json['ruleId'],
          name: json['name'],
          category: AlertCategory.values.byName(json['category']),
          alertType: AlertType.values.byName(json['alertType']),
          conditions: json['conditions'],
          severity: AlertSeverity.values.byName(json['severity']),
        )).toList();
        
        _setState(_state.copyWith(alertRules: rules));
      }
    } catch (e) {
      debugPrint('Error loading alert rules: $e');
    }
  }

  Future<void> _loadPatientThresholds() async {
    try {
      final data = await LocalStorageService.getSecureData('patient_thresholds');
      if (data != null && data is Map) {
        final thresholds = <String, List<AlertThreshold>>{};
        
        for (final entry in data.entries) {
          final patientId = entry.key as String;
          final thresholdList = (entry.value as List)
              .map((json) => AlertThreshold.fromJson(json))
              .toList();
          thresholds[patientId] = thresholdList;
        }
        
        _setState(_state.copyWith(patientThresholds: thresholds));
      }
    } catch (e) {
      debugPrint('Error loading patient thresholds: $e');
    }
  }

  Future<void> _loadActiveAlerts() async {
    try {
      final data = await LocalStorageService.getSecureData('active_alerts');
      if (data != null && data is List) {
        final alerts = data.map((json) => PatientAlert.fromJson(json)).toList();
        _setState(_state.copyWith(activeAlerts: alerts));
      }
    } catch (e) {
      debugPrint('Error loading active alerts: $e');
    }
  }

  Future<void> _saveAlertsToStorage() async {
    try {
      final alertsJson = _state.activeAlerts.map((alert) => alert.toJson()).toList();
      await LocalStorageService.saveSecureData('active_alerts', alertsJson);
    } catch (e) {
      debugPrint('Error saving alerts: $e');
    }
  }

  Future<void> _saveThresholdsToStorage() async {
    try {
      final thresholdsJson = <String, dynamic>{};
      for (final entry in _state.patientThresholds.entries) {
        thresholdsJson[entry.key] = entry.value.map((t) => t.toJson()).toList();
      }
      await LocalStorageService.saveSecureData('patient_thresholds', thresholdsJson);
    } catch (e) {
      debugPrint('Error saving thresholds: $e');
    }
  }

  List<ConnectedPatient> _generateSamplePatients() {
    // Generate sample patients for demo
    final random = Random();
    final patients = <ConnectedPatient>[];
    
    final names = ['राज कुमार', 'सुनीता देवी', 'अमित सिंह', 'प्रिया शर्मा', 'विकास पटेल'];
    
    for (int i = 0; i < names.length; i++) {
      patients.add(ConnectedPatient(
        patientId: 'patient_$i',
        patientName: names[i],
        age: 30 + random.nextInt(50),
        gender: random.nextBool() ? Gender.male : Gender.female,
        connectionDate: DateTime.now().subtract(Duration(days: random.nextInt(100))),
        lastCheckIn: DateTime.now().subtract(Duration(hours: random.nextInt(72))),
        primaryConditions: [PrimaryCondition.diabetes, PrimaryCondition.hypertension],
        currentRiskLevel: RiskLevel.values[random.nextInt(RiskLevel.values.length)],
        phoneNumber: '+91900000000$i',
        address: 'गांव $i',
        vitalsHistory: [
          VitalsModel(
            id: 'vitals_$i',
            userId: 'patient_$i',
            timestamp: DateTime.now().subtract(Duration(hours: random.nextInt(24))),
            systolicBP: 120 + random.nextInt(80),
            diastolicBP: 80 + random.nextInt(40),
            bloodGlucose: 100.0 + random.nextDouble() * 200,
            heartRate: 60.0 + random.nextDouble() * 60,
          ),
        ],
        medicationAdherence: 50.0 + random.nextDouble() * 50,
        activeAlerts: [],
      ));
    }
    
    return patients;
  }

  void _setState(SmartNotificationState newState) {
    _state = newState;
    notifyListeners();
  }
}
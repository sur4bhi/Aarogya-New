import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/connected_patient_model.dart';
import '../models/vitals_model.dart';
import '../core/services/local_storage.dart';
import '../core/services/notification_service.dart';

class PatientManagementProvider with ChangeNotifier {
  List<ConnectedPatient> _allPatients = [];
  List<ConnectedPatient> _filteredPatients = [];
  List<PatientAlert> _priorityAlerts = [];
  
  PatientFilters _currentFilters = const PatientFilters();
  PatientSortBy _currentSort = PatientSortBy.riskLevel;
  bool _sortAscending = false;
  
  bool _isLoading = false;
  String? _error;
  Timer? _alertUpdateTimer;

  // Getters
  List<ConnectedPatient> get allPatients => _allPatients;
  List<ConnectedPatient> get filteredPatients => _filteredPatients;
  List<PatientAlert> get priorityAlerts => _priorityAlerts;
  PatientFilters get currentFilters => _currentFilters;
  PatientSortBy get currentSort => _currentSort;
  bool get sortAscending => _sortAscending;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics getters
  int get totalPatients => _allPatients.length;
  int get criticalPatients => _allPatients.where((p) => p.currentRiskLevel == RiskLevel.critical).length;
  int get highRiskPatients => _allPatients.where((p) => p.currentRiskLevel == RiskLevel.high).length;
  int get overdueCheckIns => _allPatients.where((p) => p.isOverdueCheckIn).length;
  int get medicationIssues => _allPatients.where((p) => p.hasMedicationIssues).length;
  int get totalAlerts => _priorityAlerts.where((a) => !a.isRead).length;

  PatientManagementProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await loadConnectedPatients();
    _startPeriodicAlertUpdate();
  }

  void _startPeriodicAlertUpdate() {
    _alertUpdateTimer?.cancel();
    _alertUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updatePriorityAlerts();
    });
  }

  @override
  void dispose() {
    _alertUpdateTimer?.cancel();
    super.dispose();
  }

  // Load connected patients
  Future<void> loadConnectedPatients() async {
    try {
      _setLoading(true);
      _error = null;

      // In a real app, this would load from Firebase/API
      // For demo, we'll load from local storage and generate sample data
      final savedPatients = await _loadFromLocalStorage();
      
      if (savedPatients.isEmpty) {
        _allPatients = _generateSamplePatients();
        await _saveToLocalStorage();
      } else {
        _allPatients = savedPatients;
      }

      _applyFiltersAndSort();
      _updatePriorityAlerts();
      
    } catch (e) {
      _error = 'Failed to load patients: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Filter and search functionality
  void applyFilters(PatientFilters filters) {
    _currentFilters = filters;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void updateSort(PatientSortBy sortBy, bool ascending) {
    _currentSort = sortBy;
    _sortAscending = ascending;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _currentFilters = const PatientFilters();
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    _filteredPatients = PatientListUtils.filterAndSort(
      _allPatients,
      _currentFilters,
      _currentSort,
      _sortAscending,
    );
  }

  // Patient management
  Future<void> addPatient(ConnectedPatient patient) async {
    try {
      _allPatients.add(patient);
      await _saveToLocalStorage();
      _applyFiltersAndSort();
      _updatePriorityAlerts();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add patient: $e';
      notifyListeners();
    }
  }

  Future<void> updatePatient(ConnectedPatient updatedPatient) async {
    try {
      final index = _allPatients.indexWhere((p) => p.patientId == updatedPatient.patientId);
      if (index != -1) {
        _allPatients[index] = updatedPatient;
        await _saveToLocalStorage();
        _applyFiltersAndSort();
        _updatePriorityAlerts();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update patient: $e';
      notifyListeners();
    }
  }

  Future<void> removePatient(String patientId) async {
    try {
      _allPatients.removeWhere((p) => p.patientId == patientId);
      await _saveToLocalStorage();
      _applyFiltersAndSort();
      _updatePriorityAlerts();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove patient: $e';
      notifyListeners();
    }
  }

  ConnectedPatient? getPatientById(String patientId) {
    try {
      return _allPatients.firstWhere((p) => p.patientId == patientId);
    } catch (e) {
      return null;
    }
  }

  // Alert management
  void _updatePriorityAlerts() {
    _priorityAlerts.clear();

    for (final patient in _allPatients) {
      // Critical vitals alerts
      if (patient.vitalsHistory.isNotEmpty) {
        final latest = patient.vitalsHistory.first;
        if (_isCriticalVitals(latest)) {
          _priorityAlerts.add(PatientAlert(
            id: '${patient.patientId}_critical_vitals',
            type: 'critical_vitals',
            title: 'Critical Vitals Alert',
            message: '${patient.patientName} has critical vital signs requiring immediate attention',
            severity: RiskLevel.critical,
            timestamp: latest.timestamp,
            data: {
              'patientId': patient.patientId,
              'vitals': latest.toJson(),
            },
          ));
        }
      }

      // Overdue check-in alerts
      if (patient.isOverdueCheckIn) {
        _priorityAlerts.add(PatientAlert(
          id: '${patient.patientId}_overdue_checkin',
          type: 'overdue_checkin',
          title: 'Overdue Check-in',
          message: '${patient.patientName} hasn\'t checked in for ${patient.daysSinceLastCheckIn} days',
          severity: patient.daysSinceLastCheckIn > 14 ? RiskLevel.high : RiskLevel.elevated,
          timestamp: DateTime.now(),
          data: {
            'patientId': patient.patientId,
            'daysSince': patient.daysSinceLastCheckIn,
          },
        ));
      }

      // Medication adherence alerts
      if (patient.hasMedicationIssues) {
        _priorityAlerts.add(PatientAlert(
          id: '${patient.patientId}_medication',
          type: 'medication',
          title: 'Medication Non-adherence',
          message: '${patient.patientName} has low medication adherence (${patient.medicationAdherenceDisplay})',
          severity: patient.medicationAdherence < 50 ? RiskLevel.high : RiskLevel.elevated,
          timestamp: DateTime.now(),
          data: {
            'patientId': patient.patientId,
            'adherence': patient.medicationAdherence,
          },
        ));
      }

      // Add existing active alerts
      _priorityAlerts.addAll(patient.activeAlerts);
    }

    // Sort alerts by severity and timestamp
    _priorityAlerts.sort((a, b) {
      final severityComparison = b.severity.index.compareTo(a.severity.index);
      if (severityComparison != 0) return severityComparison;
      return b.timestamp.compareTo(a.timestamp);
    });

    // Trigger notifications for new critical alerts
    _triggerAlertNotifications();
  }

  bool _isCriticalVitals(VitalsModel vitals) {
    return (vitals.systolicBP != null && vitals.systolicBP! > 180) ||
           (vitals.diastolicBP != null && vitals.diastolicBP! > 110) ||
           (vitals.bloodGlucose != null && vitals.bloodGlucose! > 300) ||
           (vitals.heartRate != null && (vitals.heartRate! > 120 || vitals.heartRate! < 50));
  }

  void _triggerAlertNotifications() {
    final criticalAlerts = _priorityAlerts
        .where((alert) => alert.severity == RiskLevel.critical && !alert.isRead)
        .toList();

    for (final alert in criticalAlerts.take(3)) { // Limit to 3 notifications
      NotificationService.showLocalNotification(
        title: alert.title,
        body: alert.message,
        data: {'alertId': alert.id, 'type': 'patient_alert'},
      );
    }
  }

  Future<void> markAlertAsRead(String alertId) async {
    final index = _priorityAlerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _priorityAlerts[index] = _priorityAlerts[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> dismissAlert(String alertId) async {
    _priorityAlerts.removeWhere((alert) => alert.id == alertId);
    notifyListeners();
  }

  // Patient actions
  Future<void> callPatient(String patientId) async {
    final patient = getPatientById(patientId);
    if (patient?.phoneNumber != null) {
      // In a real app, this would launch the phone dialer
      debugPrint('Calling patient: ${patient!.patientName} at ${patient.phoneNumber}');
    }
  }

  Future<void> sendReminder(String patientId, String reminderType) async {
    final patient = getPatientById(patientId);
    if (patient != null) {
      // In a real app, this would send a push notification or SMS
      debugPrint('Sending $reminderType reminder to: ${patient.patientName}');
      
      // Add a mock notification for demo
      await NotificationService.showLocalNotification(
        title: 'Reminder Sent',
        body: '$reminderType reminder sent to ${patient.patientName}',
        data: {'patientId': patientId, 'type': 'reminder_sent'},
      );
    }
  }

  Future<void> updatePatientRiskLevel(String patientId, RiskLevel newRiskLevel) async {
    final patient = getPatientById(patientId);
    if (patient != null) {
      final updatedPatient = patient.copyWith(currentRiskLevel: newRiskLevel);
      await updatePatient(updatedPatient);
    }
  }

  // Local storage helpers
  Future<List<ConnectedPatient>> _loadFromLocalStorage() async {
    try {
      final data = await LocalStorageService.getSecureData('connected_patients');
      if (data != null) {
        final List<dynamic> jsonList = data;
        return jsonList.map((json) => ConnectedPatient.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading patients from storage: $e');
    }
    return [];
  }

  Future<void> _saveToLocalStorage() async {
    try {
      final jsonList = _allPatients.map((patient) => patient.toJson()).toList();
      await LocalStorageService.saveSecureData('connected_patients', jsonList);
    } catch (e) {
      debugPrint('Error saving patients to storage: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Generate sample data for demo
  List<ConnectedPatient> _generateSamplePatients() {
    final random = Random();
    final samplePatients = <ConnectedPatient>[];

    final names = [
      'राजेश कुमार', 'सुनीता देवी', 'अमित सिंह', 'प्रिया शर्मा', 'विकास पटेल',
      'मीरा यादव', 'रवि गुप्ता', 'कविता सिंह', 'अजय वर्मा', 'नीता पांडे'
    ];

    for (int i = 0; i < names.length; i++) {
      final age = 25 + random.nextInt(55);
      final connectionDays = random.nextInt(180);
      final lastCheckInDays = random.nextInt(30);
      
      // Generate vitals history
      final vitalsHistory = <VitalsModel>[];
      for (int j = 0; j < 10; j++) {
        final daysAgo = j * 3;
        vitalsHistory.add(VitalsModel(
          id: 'vitals_${i}_$j',
          userId: 'patient_$i',
          type: VitalType.bloodPressure,
          timestamp: DateTime.now().subtract(Duration(days: daysAgo)),
          systolicBP: 110 + random.nextInt(40),
          diastolicBP: 70 + random.nextInt(25),
          bloodGlucose: 80 + random.nextInt(100).toDouble(),
          weight: 55 + random.nextInt(30).toDouble(),
          heartRate: 65 + random.nextInt(30).toDouble(),
        ));
      }

      final conditions = <PrimaryCondition>[];
      if (random.nextBool()) conditions.add(PrimaryCondition.diabetes);
      if (random.nextBool()) conditions.add(PrimaryCondition.hypertension);

      samplePatients.add(ConnectedPatient(
        patientId: 'patient_$i',
        patientName: names[i],
        age: age,
        gender: random.nextBool() ? Gender.male : Gender.female,
        connectionDate: DateTime.now().subtract(Duration(days: connectionDays)),
        lastCheckIn: DateTime.now().subtract(Duration(days: lastCheckInDays)),
        primaryConditions: conditions,
        currentRiskLevel: ConnectedPatient.assessRiskLevel(vitalsHistory),
        phoneNumber: '+91${9000000000 + i}',
        address: 'गांव ${i + 1}, जिला उदाहरण',
        vitalsHistory: vitalsHistory,
        medicationAdherence: 50.0 + random.nextDouble() * 50.0,
        activeAlerts: [],
      ));
    }

    return samplePatients;
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadConnectedPatients();
  }

  // Search functionality
  List<ConnectedPatient> searchPatients(String query) {
    if (query.isEmpty) return _allPatients;
    
    final searchFilters = _currentFilters.copyWith(searchQuery: query);
    return PatientListUtils.filterAndSort(
      _allPatients,
      searchFilters,
      _currentSort,
      _sortAscending,
    );
  }

  // Get patients by risk level
  List<ConnectedPatient> getPatientsByRiskLevel(RiskLevel riskLevel) {
    return _allPatients.where((p) => p.currentRiskLevel == riskLevel).toList();
  }

  // Get overdue patients
  List<ConnectedPatient> getOverduePatients() {
    return _allPatients.where((p) => p.isOverdueCheckIn).toList();
  }

  // Get patients with medication issues
  List<ConnectedPatient> getPatientsWithMedicationIssues() {
    return _allPatients.where((p) => p.hasMedicationIssues).toList();
  }
}
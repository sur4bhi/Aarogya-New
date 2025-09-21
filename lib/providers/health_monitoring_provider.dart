import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/patient_vitals_overview_model.dart';
import '../models/connected_patient_model.dart';
import '../models/vitals_model.dart';
import '../core/services/local_storage.dart';
import '../core/services/notification_service.dart';

class HealthMonitoringState {
  final List<PatientVitalsOverview> patients;
  final VitalsFilter currentFilter;
  final List<RiskAlert> activeAlerts;
  final PopulationHealthStats? communityStats;
  final bool isLoading;
  final String? error;
  final DateTime lastRefresh;

  const HealthMonitoringState({
    this.patients = const [],
    this.currentFilter = VitalsFilter.all,
    this.activeAlerts = const [],
    this.communityStats,
    this.isLoading = false,
    this.error,
    required this.lastRefresh,
  });

  HealthMonitoringState copyWith({
    List<PatientVitalsOverview>? patients,
    VitalsFilter? currentFilter,
    List<RiskAlert>? activeAlerts,
    PopulationHealthStats? communityStats,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
  }) {
    return HealthMonitoringState(
      patients: patients ?? this.patients,
      currentFilter: currentFilter ?? this.currentFilter,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      communityStats: communityStats ?? this.communityStats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }
}

class HealthMonitoringProvider with ChangeNotifier {
  HealthMonitoringState _state = HealthMonitoringState(lastRefresh: DateTime.now());
  Timer? _refreshTimer;
  StreamSubscription? _vitalsSubscription;

  // Getters
  HealthMonitoringState get state => _state;
  List<PatientVitalsOverview> get allPatients => _state.patients;
  List<PatientVitalsOverview> get filteredPatients => _getFilteredPatients();
  List<RiskAlert> get activeAlerts => _state.activeAlerts;
  PopulationHealthStats? get communityStats => _state.communityStats;
  VitalsFilter get currentFilter => _state.currentFilter;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  DateTime get lastRefresh => _state.lastRefresh;

  // Quick stats
  int get totalPatients => _state.patients.length;
  int get criticalPatients => _state.patients.where((p) => p.vitalsStatus == VitalsStatus.critical).length;
  int get highRiskPatients => _state.patients.where((p) => p.vitalsStatus == VitalsStatus.high).length;
  int get overduePatients => _state.patients.where((p) => p.isOverdue).length;
  double get normalVitalsPercentage => totalPatients > 0 
      ? (_state.patients.where((p) => p.vitalsStatus == VitalsStatus.normal).length / totalPatients) * 100 
      : 0.0;

  HealthMonitoringProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await loadVitalsData();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      refreshData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _vitalsSubscription?.cancel();
    super.dispose();
  }

  // Load vitals data from connected patients
  Future<void> loadVitalsData() async {
    try {
      _setState(_state.copyWith(isLoading: true, error: null));

      // In a real app, this would integrate with PatientManagementProvider
      // For now, we'll load from local storage or generate sample data
      final patients = await _loadPatientsWithVitals();
      final alerts = VitalsAnalytics.generateAlertsFromPatients(patients);
      final communityStats = PopulationHealthStats.fromPatientList(patients);

      _setState(_state.copyWith(
        patients: patients,
        activeAlerts: alerts,
        communityStats: communityStats,
        isLoading: false,
        lastRefresh: DateTime.now(),
      ));

      // Trigger notifications for critical alerts
      _triggerCriticalAlertNotifications();

    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        error: 'Failed to load vitals data: $e',
      ));
    }
  }

  // Apply filter
  void applyFilter(VitalsFilter filter) {
    _setState(_state.copyWith(currentFilter: filter));
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadVitalsData();
  }

  // Get filtered patients based on current filter
  List<PatientVitalsOverview> _getFilteredPatients() {
    switch (_state.currentFilter) {
      case VitalsFilter.all:
        return _state.patients;
      case VitalsFilter.normal:
        return _state.patients.where((p) => p.vitalsStatus == VitalsStatus.normal).toList();
      case VitalsFilter.elevated:
        return _state.patients.where((p) => p.vitalsStatus == VitalsStatus.elevated).toList();
      case VitalsFilter.high:
        return _state.patients.where((p) => p.vitalsStatus == VitalsStatus.high).toList();
      case VitalsFilter.critical:
        return _state.patients.where((p) => p.vitalsStatus == VitalsStatus.critical).toList();
      case VitalsFilter.overdue:
        return _state.patients.where((p) => p.isOverdue).toList();
    }
  }

  // Get patient by ID
  PatientVitalsOverview? getPatientById(String patientId) {
    try {
      return _state.patients.firstWhere((p) => p.patientId == patientId);
    } catch (e) {
      return null;
    }
  }

  // Get patients by vital status
  List<PatientVitalsOverview> getPatientsByStatus(VitalsStatus status) {
    return _state.patients.where((p) => p.vitalsStatus == status).toList();
  }

  // Get trending patients (improving/declining)
  List<PatientVitalsOverview> getTrendingPatients(TrendDirection direction) {
    return _state.patients.where((patient) {
      return patient.trends.any((trend) => trend.direction == direction);
    }).toList();
  }

  // Get population trend data for specific vital
  List<double> getPopulationTrendData(VitalType vitalType, int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final trendData = <double>[];

    // Generate daily averages for the population
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dailyValues = <double>[];

      for (final patient in _state.patients) {
        final trend = patient.getTrend(vitalType);
        if (trend != null && trend.values.isNotEmpty) {
          // Find the closest value for this date
          for (int j = 0; j < trend.timestamps.length; j++) {
            if (trend.timestamps[j].day == date.day &&
                trend.timestamps[j].month == date.month) {
              dailyValues.add(trend.values[j]);
              break;
            }
          }
        }
      }

      if (dailyValues.isNotEmpty) {
        final average = dailyValues.reduce((a, b) => a + b) / dailyValues.length;
        trendData.add(average);
      } else {
        // Use previous value or interpolate
        trendData.add(trendData.isNotEmpty ? trendData.last : 0.0);
      }
    }

    return trendData;
  }

  // Risk assessment methods
  List<PatientVitalsOverview> getHighRiskPatients() {
    return _state.patients
        .where((p) => p.vitalsStatus == VitalsStatus.high || p.vitalsStatus == VitalsStatus.critical)
        .toList();
  }

  List<PatientVitalsOverview> getPatientsNeedingAttention() {
    return _state.patients.where((patient) {
      return patient.vitalsStatus == VitalsStatus.critical ||
             patient.isOverdue ||
             patient.hasCriticalAlerts ||
             patient.trends.any((trend) => trend.direction == TrendDirection.declining);
    }).toList();
  }

  // Alert management
  Future<void> markAlertAsRead(String alertId) async {
    final updatedAlerts = _state.activeAlerts.map((alert) {
      if (alert.id == alertId) {
        return alert.copyWith(isRead: true);
      }
      return alert;
    }).toList();

    _setState(_state.copyWith(activeAlerts: updatedAlerts));
  }

  Future<void> dismissAlert(String alertId) async {
    final updatedAlerts = _state.activeAlerts.where((alert) => alert.id != alertId).toList();
    _setState(_state.copyWith(activeAlerts: updatedAlerts));
  }

  // Comparative analytics
  Map<String, dynamic> getComparativeAnalytics(String patientId, VitalType vitalType) {
    final patient = getPatientById(patientId);
    if (patient == null) return {};

    final patientTrend = patient.getTrend(vitalType);
    if (patientTrend == null || patientTrend.values.isEmpty) return {};

    final patientLatestValue = patientTrend.values.last;
    final populationValues = <double>[];

    // Collect latest values from all patients for comparison
    for (final p in _state.patients) {
      final trend = p.getTrend(vitalType);
      if (trend != null && trend.values.isNotEmpty) {
        populationValues.add(trend.values.last);
      }
    }

    if (populationValues.isEmpty) return {};

    populationValues.sort();
    final average = populationValues.reduce((a, b) => a + b) / populationValues.length;
    final median = populationValues[populationValues.length ~/ 2];
    
    // Calculate percentile
    final belowPatient = populationValues.where((v) => v < patientLatestValue).length;
    final percentile = (belowPatient / populationValues.length) * 100;

    return {
      'patientValue': patientLatestValue,
      'populationAverage': average,
      'populationMedian': median,
      'patientPercentile': percentile,
      'isAboveAverage': patientLatestValue > average,
      'populationRange': {
        'min': populationValues.first,
        'max': populationValues.last,
      },
    };
  }

  // Pattern detection
  List<PatientVitalsOverview> detectPatientsWithPatterns() {
    final patientsWithPatterns = <PatientVitalsOverview>[];

    for (final patient in _state.patients) {
      bool hasSignificantPattern = false;

      for (final trend in patient.trends) {
        // Detect consistent trends
        if (trend.values.length >= 5) {
          final recentValues = trend.values.take(5).toList();
          
          // Check for consistent increase or decrease
          bool consistentIncrease = true;
          bool consistentDecrease = true;
          
          for (int i = 1; i < recentValues.length; i++) {
            if (recentValues[i] <= recentValues[i-1]) consistentIncrease = false;
            if (recentValues[i] >= recentValues[i-1]) consistentDecrease = false;
          }
          
          if (consistentIncrease || consistentDecrease) {
            hasSignificantPattern = true;
            break;
          }
        }
      }

      if (hasSignificantPattern) {
        patientsWithPatterns.add(patient);
      }
    }

    return patientsWithPatterns;
  }

  // Geographic insights (mock implementation)
  Map<String, dynamic> getGeographicInsights() {
    // In a real app, this would analyze patients by location
    final random = Random();
    return {
      'totalAreas': 5,
      'areasWithHighRisk': 2,
      'averageComplianceByArea': {
        'Village A': 85.0 + random.nextDouble() * 10,
        'Village B': 78.0 + random.nextDouble() * 10,
        'Village C': 92.0 + random.nextDouble() * 8,
        'Village D': 73.0 + random.nextDouble() * 12,
        'Village E': 88.0 + random.nextDouble() * 8,
      },
      'conditionsByArea': {
        'Diabetes': {'Village A': 12, 'Village B': 8, 'Village C': 15, 'Village D': 6, 'Village E': 10},
        'Hypertension': {'Village A': 18, 'Village B': 12, 'Village C': 22, 'Village D': 9, 'Village E': 14},
      },
    };
  }

  // Trigger notifications for critical alerts
  void _triggerCriticalAlertNotifications() {
    final criticalAlerts = _state.activeAlerts
        .where((alert) => alert.severity == VitalsStatus.critical && !alert.isRead)
        .take(3) // Limit to 3 notifications
        .toList();

    for (final alert in criticalAlerts) {
      NotificationService.showLocalNotification(
        title: alert.title,
        body: alert.message,
        data: {'alertId': alert.id, 'type': 'health_monitoring'},
      );
    }
  }

  void _setState(HealthMonitoringState newState) {
    _state = newState;
    notifyListeners();
  }

  // Load patients with vitals (mock implementation)
  Future<List<PatientVitalsOverview>> _loadPatientsWithVitals() async {
    try {
      // Try to load from local storage first
      final data = await LocalStorageService.getSecureData('health_monitoring_data');
      if (data != null && data is List && data.isNotEmpty) {
        return data.map((json) => PatientVitalsOverview.fromConnectedPatient(
          ConnectedPatient.fromJson(json)
        )).toList();
      }
    } catch (e) {
      debugPrint('Error loading health monitoring data: $e');
    }

    // Generate sample data if no stored data exists
    return _generateSampleVitalsData();
  }

  // Generate sample vitals data for demo
  List<PatientVitalsOverview> _generateSampleVitalsData() {
    final random = Random();
    final samplePatients = <PatientVitalsOverview>[];

    final names = [
      'राजेश कुमार', 'सुनीता देवी', 'अमित सिंह', 'प्रिया शर्मा', 'विकास पटेल',
      'मीरा यादव', 'रवि गुप्ता', 'कविता सिंह', 'अजय वर्मा', 'नीता पांडे',
      'संजय तिवारी', 'रेखा मिश्रा', 'दीपक चौधरी', 'सरिता जैन', 'महेश अग्रवाल'
    ];

    for (int i = 0; i < names.length; i++) {
      final age = 25 + random.nextInt(55);
      final gender = random.nextBool() ? Gender.male : Gender.female;
      
      // Generate vitals history
      final vitalsHistory = <VitalsModel>[];
      for (int j = 0; j < 15; j++) {
        final daysAgo = j * 2;
        vitalsHistory.add(VitalsModel(
          id: 'vitals_${i}_$j',
          userId: 'patient_$i',
          type: VitalType.bloodPressure,
          timestamp: DateTime.now().subtract(Duration(days: daysAgo)),
          systolicBP: 110 + random.nextInt(50) + (random.nextBool() ? 10 : 0),
          diastolicBP: 70 + random.nextInt(30) + (random.nextBool() ? 5 : 0),
          bloodGlucose: 80 + random.nextInt(120).toDouble() + (random.nextBool() ? 20 : 0),
          weight: 55 + random.nextInt(30).toDouble() + (random.nextGaussian() * 2),
          heartRate: 65 + random.nextInt(40).toDouble() + (random.nextBool() ? 5 : 0),
        ));
      }

      final conditions = <PrimaryCondition>[];
      if (random.nextDouble() < 0.4) conditions.add(PrimaryCondition.diabetes);
      if (random.nextDouble() < 0.5) conditions.add(PrimaryCondition.hypertension);
      if (random.nextDouble() < 0.1) conditions.add(PrimaryCondition.heartDisease);

      // Create connected patient and convert to vitals overview
      final connectedPatient = ConnectedPatient(
        patientId: 'patient_$i',
        patientName: names[i],
        age: age,
        gender: gender,
        connectionDate: DateTime.now().subtract(Duration(days: 30 + random.nextInt(120))),
        lastCheckIn: DateTime.now().subtract(Duration(days: random.nextInt(15))),
        primaryConditions: conditions,
        currentRiskLevel: RiskLevel.values[random.nextInt(RiskLevel.values.length)],
        phoneNumber: '+91${9000000000 + i}',
        address: 'गांव ${i + 1}, जिला उदाहरण',
        vitalsHistory: vitalsHistory,
        medicationAdherence: 60.0 + random.nextDouble() * 35.0,
        activeAlerts: [],
      );

      final vitalsOverview = PatientVitalsOverview.fromConnectedPatient(connectedPatient);
      samplePatients.add(vitalsOverview);
    }

    return samplePatients;
  }

  // Save data to local storage
  Future<void> _saveToLocalStorage() async {
    try {
      final jsonList = _state.patients.map((patient) => {
        'patientId': patient.patientId,
        'patientName': patient.patientName,
        'age': patient.age,
        'gender': patient.gender.name,
        // Add other necessary fields for reconstruction
      }).toList();
      
      await LocalStorageService.saveSecureData('health_monitoring_data', jsonList);
    } catch (e) {
      debugPrint('Error saving health monitoring data: $e');
    }
  }
}

// Extensions for random number generation
extension RandomExtension on Random {
  double nextGaussian() {
    // Box-Muller transformation for normal distribution
    double u = 0;
    double v = 0;
    while (u == 0) u = nextDouble(); // Converting [0,1) to (0,1)
    while (v == 0) v = nextDouble();
    return sqrt(-2.0 * log(u)) * cos(2.0 * pi * v);
  }
}

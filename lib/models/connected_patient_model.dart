import 'package:flutter/material.dart';
import 'vitals_model.dart';

enum RiskLevel {
  normal('Normal', Colors.green),
  elevated('Elevated', Colors.orange),
  high('High Risk', Colors.red),
  critical('Critical', Colors.redAccent);

  const RiskLevel(this.displayName, this.color);
  final String displayName;
  final Color color;
}

enum PrimaryCondition {
  diabetes('Diabetes'),
  hypertension('Hypertension'),
  heartDisease('Heart Disease'),
  obesity('Obesity'),
  respiratory('Respiratory'),
  other('Other');

  const PrimaryCondition(this.displayName);
  final String displayName;
}

enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  const Gender(this.displayName);
  final String displayName;
}

class PatientAlert {
  final String id;
  final String type; // 'critical_vitals', 'overdue_checkin', 'medication', 'emergency'
  final String title;
  final String message;
  final RiskLevel severity;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const PatientAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory PatientAlert.fromJson(Map<String, dynamic> json) {
    return PatientAlert(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: RiskLevel.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => RiskLevel.normal,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  PatientAlert copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    RiskLevel? severity,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return PatientAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class ConnectedPatient {
  final String patientId;
  final String patientName;
  final int age;
  final Gender gender;
  final DateTime connectionDate;
  final DateTime? lastCheckIn;
  final List<PrimaryCondition> primaryConditions;
  final RiskLevel currentRiskLevel;
  final String? profileImage;
  final String? phoneNumber;
  final String? address;
  final List<VitalsModel> vitalsHistory;
  final double medicationAdherence; // percentage 0-100
  final List<PatientAlert> activeAlerts;
  final Map<String, dynamic>? additionalData;

  const ConnectedPatient({
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.connectionDate,
    this.lastCheckIn,
    this.primaryConditions = const [],
    this.currentRiskLevel = RiskLevel.normal,
    this.profileImage,
    this.phoneNumber,
    this.address,
    this.vitalsHistory = const [],
    this.medicationAdherence = 0.0,
    this.activeAlerts = const [],
    this.additionalData,
  });

  factory ConnectedPatient.fromJson(Map<String, dynamic> json) {
    return ConnectedPatient(
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      age: json['age'] ?? 0,
      gender: Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.male,
      ),
      connectionDate: DateTime.parse(json['connectionDate']),
      lastCheckIn: json['lastCheckIn'] != null 
          ? DateTime.parse(json['lastCheckIn'])
          : null,
      primaryConditions: (json['primaryConditions'] as List<dynamic>?)
          ?.map((e) => PrimaryCondition.values.firstWhere(
              (condition) => condition.name == e,
              orElse: () => PrimaryCondition.other,
            ))
          .toList() ?? [],
      currentRiskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['currentRiskLevel'],
        orElse: () => RiskLevel.normal,
      ),
      profileImage: json['profileImage'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      vitalsHistory: (json['vitalsHistory'] as List<dynamic>?)
          ?.map((e) => VitalsModel.fromJson(e))
          .toList() ?? [],
      medicationAdherence: (json['medicationAdherence'] ?? 0.0).toDouble(),
      activeAlerts: (json['activeAlerts'] as List<dynamic>?)
          ?.map((e) => PatientAlert.fromJson(e))
          .toList() ?? [],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'age': age,
      'gender': gender.name,
      'connectionDate': connectionDate.toIso8601String(),
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'primaryConditions': primaryConditions.map((e) => e.name).toList(),
      'currentRiskLevel': currentRiskLevel.name,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'address': address,
      'vitalsHistory': vitalsHistory.map((e) => e.toJson()).toList(),
      'medicationAdherence': medicationAdherence,
      'activeAlerts': activeAlerts.map((e) => e.toJson()).toList(),
      'additionalData': additionalData,
    };
  }

  ConnectedPatient copyWith({
    String? patientId,
    String? patientName,
    int? age,
    Gender? gender,
    DateTime? connectionDate,
    DateTime? lastCheckIn,
    List<PrimaryCondition>? primaryConditions,
    RiskLevel? currentRiskLevel,
    String? profileImage,
    String? phoneNumber,
    String? address,
    List<VitalsModel>? vitalsHistory,
    double? medicationAdherence,
    List<PatientAlert>? activeAlerts,
    Map<String, dynamic>? additionalData,
  }) {
    return ConnectedPatient(
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      connectionDate: connectionDate ?? this.connectionDate,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      primaryConditions: primaryConditions ?? this.primaryConditions,
      currentRiskLevel: currentRiskLevel ?? this.currentRiskLevel,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      vitalsHistory: vitalsHistory ?? this.vitalsHistory,
      medicationAdherence: medicationAdherence ?? this.medicationAdherence,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Utility getters
  int get daysSinceLastCheckIn {
    if (lastCheckIn == null) return -1;
    return DateTime.now().difference(lastCheckIn!).inDays;
  }

  bool get isOverdueCheckIn => daysSinceLastCheckIn >= 7;

  bool get hasCriticalAlerts => 
      activeAlerts.any((alert) => alert.severity == RiskLevel.critical);

  bool get hasMedicationIssues => medicationAdherence < 70.0;

  VitalsModel? get latestVitals =>
      vitalsHistory.isNotEmpty ? vitalsHistory.first : null;

  String get conditionsDisplayText {
    if (primaryConditions.isEmpty) return 'No conditions recorded';
    return primaryConditions.map((c) => c.displayName).join(', ');
  }

  String get lastCheckInDisplay {
    if (lastCheckIn == null) return 'Never';
    final days = daysSinceLastCheckIn;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  String get medicationAdherenceDisplay {
    return '${medicationAdherence.toStringAsFixed(0)}%';
  }

  Color get riskLevelColor => currentRiskLevel.color;

  String get displayName => patientName;

  String get ageGenderDisplay => '$age yrs, ${gender.displayName}';

  // Risk assessment based on latest vitals
  static RiskLevel assessRiskLevel(List<VitalsModel> vitals) {
    if (vitals.isEmpty) return RiskLevel.normal;

    final latest = vitals.first;
    
    // Critical thresholds
    if (latest.systolicBP != null && latest.systolicBP! > 180) return RiskLevel.critical;
    if (latest.diastolicBP != null && latest.diastolicBP! > 110) return RiskLevel.critical;
    if (latest.bloodGlucose != null && latest.bloodGlucose! > 300) return RiskLevel.critical;

    // High risk thresholds
    if (latest.systolicBP != null && latest.systolicBP! > 160) return RiskLevel.high;
    if (latest.diastolicBP != null && latest.diastolicBP! > 100) return RiskLevel.high;
    if (latest.bloodGlucose != null && latest.bloodGlucose! > 250) return RiskLevel.high;

    // Elevated risk thresholds
    if (latest.systolicBP != null && latest.systolicBP! > 140) return RiskLevel.elevated;
    if (latest.diastolicBP != null && latest.diastolicBP! > 90) return RiskLevel.elevated;
    if (latest.bloodGlucose != null && latest.bloodGlucose! > 180) return RiskLevel.elevated;

    return RiskLevel.normal;
  }
}

// Filter and sort utilities
class PatientFilters {
  final String? searchQuery;
  final RiskLevel? riskLevel;
  final PrimaryCondition? condition;
  final String? lastCheckInFilter; // 'today', 'week', 'month', 'overdue'
  final int? minAge;
  final int? maxAge;
  final Gender? gender;

  const PatientFilters({
    this.searchQuery,
    this.riskLevel,
    this.condition,
    this.lastCheckInFilter,
    this.minAge,
    this.maxAge,
    this.gender,
  });

  PatientFilters copyWith({
    String? searchQuery,
    RiskLevel? riskLevel,
    PrimaryCondition? condition,
    String? lastCheckInFilter,
    int? minAge,
    int? maxAge,
    Gender? gender,
  }) {
    return PatientFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      riskLevel: riskLevel ?? this.riskLevel,
      condition: condition ?? this.condition,
      lastCheckInFilter: lastCheckInFilter ?? this.lastCheckInFilter,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gender: gender ?? this.gender,
    );
  }

  bool matches(ConnectedPatient patient) {
    // Search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!patient.patientName.toLowerCase().contains(query) &&
          !patient.patientId.toLowerCase().contains(query)) {
        return false;
      }
    }

    // Risk level
    if (riskLevel != null && patient.currentRiskLevel != riskLevel) {
      return false;
    }

    // Condition
    if (condition != null && !patient.primaryConditions.contains(condition)) {
      return false;
    }

    // Age range
    if (minAge != null && patient.age < minAge!) return false;
    if (maxAge != null && patient.age > maxAge!) return false;

    // Gender
    if (gender != null && patient.gender != gender) return false;

    // Last check-in
    if (lastCheckInFilter != null) {
      final days = patient.daysSinceLastCheckIn;
      switch (lastCheckInFilter) {
        case 'today':
          if (days != 0) return false;
          break;
        case 'week':
          if (days > 7) return false;
          break;
        case 'month':
          if (days > 30) return false;
          break;
        case 'overdue':
          if (days < 7) return false;
          break;
      }
    }

    return true;
  }
}

enum PatientSortBy {
  name('Name'),
  riskLevel('Risk Level'),
  lastCheckIn('Last Check-in'),
  age('Age'),
  medicationAdherence('Medication Adherence');

  const PatientSortBy(this.displayName);
  final String displayName;
}

class PatientListUtils {
  static List<ConnectedPatient> filterAndSort(
    List<ConnectedPatient> patients, 
    PatientFilters filters, 
    PatientSortBy sortBy, 
    bool ascending
  ) {
    // Apply filters
    var filtered = patients.where((patient) => filters.matches(patient)).toList();

    // Apply sorting
    switch (sortBy) {
      case PatientSortBy.name:
        filtered.sort((a, b) => a.patientName.compareTo(b.patientName));
        break;
      case PatientSortBy.riskLevel:
        filtered.sort((a, b) => a.currentRiskLevel.index.compareTo(b.currentRiskLevel.index));
        break;
      case PatientSortBy.lastCheckIn:
        filtered.sort((a, b) {
          if (a.lastCheckIn == null && b.lastCheckIn == null) return 0;
          if (a.lastCheckIn == null) return 1;
          if (b.lastCheckIn == null) return -1;
          return a.lastCheckIn!.compareTo(b.lastCheckIn!);
        });
        break;
      case PatientSortBy.age:
        filtered.sort((a, b) => a.age.compareTo(b.age));
        break;
      case PatientSortBy.medicationAdherence:
        filtered.sort((a, b) => a.medicationAdherence.compareTo(b.medicationAdherence));
        break;
    }

    if (!ascending) {
      filtered = filtered.reversed.toList();
    }

    return filtered;
  }
}
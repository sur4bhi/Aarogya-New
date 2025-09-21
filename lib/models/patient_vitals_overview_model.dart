import 'package:flutter/material.dart';
import 'vitals_model.dart';
import 'connected_patient_model.dart';

enum VitalsStatus {
  normal('Normal', Colors.green),
  elevated('Elevated', Colors.orange),
  high('High', Colors.red),
  critical('Critical', Colors.redAccent);

  const VitalsStatus(this.displayName, this.color);
  final String displayName;
  final Color color;
}

enum TrendDirection {
  improving('Improving', Colors.green, Icons.trending_up),
  stable('Stable', Colors.blue, Icons.trending_flat),
  declining('Declining', Colors.red, Icons.trending_down);

  const TrendDirection(this.displayName, this.color, this.icon);
  final String displayName;
  final Color color;
  final IconData icon;
}

enum VitalType {
  bloodPressure('Blood Pressure'),
  bloodGlucose('Blood Glucose'),
  weight('Weight'),
  heartRate('Heart Rate');

  const VitalType(this.displayName);
  final String displayName;
}

class VitalTrend {
  final VitalType type;
  final TrendDirection direction;
  final double changeValue;
  final String changeText;
  final List<double> values;
  final List<DateTime> timestamps;

  const VitalTrend({
    required this.type,
    required this.direction,
    required this.changeValue,
    required this.changeText,
    required this.values,
    required this.timestamps,
  });

  factory VitalTrend.fromVitalsHistory(
    VitalType type,
    List<VitalsModel> vitalsHistory,
  ) {
    if (vitalsHistory.length < 2) {
      return VitalTrend(
        type: type,
        direction: TrendDirection.stable,
        changeValue: 0.0,
        changeText: 'No data',
        values: [],
        timestamps: [],
      );
    }

    final values = <double>[];
    final timestamps = <DateTime>[];

    for (final vital in vitalsHistory) {
      double? value;
      switch (type) {
        case VitalType.bloodPressure:
          if (vital.systolicBP != null) {
            value = vital.systolicBP!.toDouble();
          }
          break;
        case VitalType.bloodGlucose:
          value = vital.bloodGlucose;
          break;
        case VitalType.weight:
          value = vital.weight;
          break;
        case VitalType.heartRate:
          value = vital.heartRate;
          break;
      }

      if (value != null) {
        values.add(value);
        timestamps.add(vital.timestamp);
      }
    }

    if (values.length < 2) {
      return VitalTrend(
        type: type,
        direction: TrendDirection.stable,
        changeValue: 0.0,
        changeText: 'Insufficient data',
        values: values,
        timestamps: timestamps,
      );
    }

    // Calculate trend (compare first vs last values)
    final firstValue = values.first;
    final lastValue = values.last;
    final changeValue = lastValue - firstValue;
    final changePercent = (changeValue / firstValue) * 100;

    TrendDirection direction;
    String changeText;

    // Determine trend direction based on vital type
    if (type == VitalType.weight) {
      // For weight, small changes are normal
      if (changePercent.abs() < 2) {
        direction = TrendDirection.stable;
        changeText = 'Stable (${changeValue.toStringAsFixed(1)}kg)';
      } else if (changeValue > 0) {
        direction = TrendDirection.declining; // Weight gain might be concerning
        changeText = '+${changeValue.toStringAsFixed(1)}kg (${changePercent.toStringAsFixed(1)}%)';
      } else {
        direction = TrendDirection.declining; // Weight loss might be concerning
        changeText = '${changeValue.toStringAsFixed(1)}kg (${changePercent.toStringAsFixed(1)}%)';
      }
    } else {
      // For BP, glucose, HR - lower is generally better
      if (changePercent.abs() < 5) {
        direction = TrendDirection.stable;
        changeText = 'Stable (${changeValue.toStringAsFixed(1)})';
      } else if (changeValue > 0) {
        direction = TrendDirection.declining;
        changeText = '+${changeValue.toStringAsFixed(1)} (${changePercent.toStringAsFixed(1)}%)';
      } else {
        direction = TrendDirection.improving;
        changeText = '${changeValue.toStringAsFixed(1)} (${changePercent.toStringAsFixed(1)}%)';
      }
    }

    return VitalTrend(
      type: type,
      direction: direction,
      changeValue: changeValue,
      changeText: changeText,
      values: values,
      timestamps: timestamps,
    );
  }
}

class RiskAlert {
  final String id;
  final String patientId;
  final String patientName;
  final String type; // 'critical_vitals', 'trend_warning', 'missing_data'
  final VitalType? vitalType;
  final String title;
  final String message;
  final VitalsStatus severity;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const RiskAlert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.type,
    this.vitalType,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory RiskAlert.fromJson(Map<String, dynamic> json) {
    return RiskAlert(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      type: json['type'] ?? '',
      vitalType: json['vitalType'] != null 
          ? VitalType.values.firstWhere(
              (e) => e.name == json['vitalType'],
              orElse: () => VitalType.bloodPressure,
            )
          : null,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: VitalsStatus.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => VitalsStatus.normal,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'type': type,
      'vitalType': vitalType?.name,
      'title': title,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  RiskAlert copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? type,
    VitalType? vitalType,
    String? title,
    String? message,
    VitalsStatus? severity,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return RiskAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      type: type ?? this.type,
      vitalType: vitalType ?? this.vitalType,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class PatientVitalsOverview {
  final String patientId;
  final String patientName;
  final int age;
  final Gender gender;
  final String? profileImage;
  final DateTime? lastVitalsTimestamp;
  final int? latestSystolicBP;
  final int? latestDiastolicBP;
  final double? latestGlucose;
  final double? latestWeight;
  final double? latestHeartRate;
  final VitalsStatus vitalsStatus;
  final List<VitalTrend> trends;
  final int missedReadingsCount;
  final double complianceScore; // 0-100
  final List<RiskAlert> activeAlerts;
  final List<PrimaryCondition> primaryConditions;

  const PatientVitalsOverview({
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.gender,
    this.profileImage,
    this.lastVitalsTimestamp,
    this.latestSystolicBP,
    this.latestDiastolicBP,
    this.latestGlucose,
    this.latestWeight,
    this.latestHeartRate,
    this.vitalsStatus = VitalsStatus.normal,
    this.trends = const [],
    this.missedReadingsCount = 0,
    this.complianceScore = 0.0,
    this.activeAlerts = const [],
    this.primaryConditions = const [],
  });

  factory PatientVitalsOverview.fromConnectedPatient(ConnectedPatient patient) {
    final latestVitals = patient.latestVitals;
    final vitalsHistory = patient.vitalsHistory;

    // Calculate trends for each vital type
    final trends = <VitalTrend>[];
    trends.add(VitalTrend.fromVitalsHistory(VitalType.bloodPressure, vitalsHistory));
    trends.add(VitalTrend.fromVitalsHistory(VitalType.bloodGlucose, vitalsHistory));
    trends.add(VitalTrend.fromVitalsHistory(VitalType.weight, vitalsHistory));
    trends.add(VitalTrend.fromVitalsHistory(VitalType.heartRate, vitalsHistory));

    // Calculate missed readings (expected daily readings)
    final daysSinceLastVitals = patient.daysSinceLastCheckIn;
    final missedReadingsCount = daysSinceLastVitals > 0 ? daysSinceLastVitals : 0;

    // Calculate compliance score based on vitals frequency and medication adherence
    final vitalsComplianceScore = _calculateVitalsCompliance(vitalsHistory);
    final overallComplianceScore = (vitalsComplianceScore + patient.medicationAdherence) / 2;

    // Determine overall vitals status
    final vitalsStatus = _assessOverallVitalsStatus(
      latestVitals,
      patient.currentRiskLevel,
    );

    return PatientVitalsOverview(
      patientId: patient.patientId,
      patientName: patient.patientName,
      age: patient.age,
      gender: patient.gender,
      profileImage: patient.profileImage,
      lastVitalsTimestamp: latestVitals?.timestamp,
      latestSystolicBP: latestVitals?.systolicBP,
      latestDiastolicBP: latestVitals?.diastolicBP,
      latestGlucose: latestVitals?.bloodGlucose,
      latestWeight: latestVitals?.weight,
      latestHeartRate: latestVitals?.heartRate,
      vitalsStatus: vitalsStatus,
      trends: trends,
      missedReadingsCount: missedReadingsCount,
      complianceScore: overallComplianceScore,
      activeAlerts: [], // Will be populated separately
      primaryConditions: patient.primaryConditions,
    );
  }

  // Utility getters
  String get bloodPressureDisplay {
    if (latestSystolicBP != null && latestDiastolicBP != null) {
      return '$latestSystolicBP/$latestDiastolicBP mmHg';
    }
    return '--';
  }

  String get glucoseDisplay {
    if (latestGlucose != null) {
      return '${latestGlucose!.toStringAsFixed(0)} mg/dL';
    }
    return '--';
  }

  String get weightDisplay {
    if (latestWeight != null) {
      return '${latestWeight!.toStringAsFixed(1)} kg';
    }
    return '--';
  }

  String get heartRateDisplay {
    if (latestHeartRate != null) {
      return '${latestHeartRate!.toStringAsFixed(0)} bpm';
    }
    return '--';
  }

  String get lastReadingDisplay {
    if (lastVitalsTimestamp == null) return 'No readings';
    
    final now = DateTime.now();
    final difference = now.difference(lastVitalsTimestamp!);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${difference.inDays}d ago';
  }

  bool get isOverdue => missedReadingsCount >= 3;
  bool get hasCriticalAlerts => activeAlerts.any((alert) => alert.severity == VitalsStatus.critical);
  
  VitalTrend? getTrend(VitalType type) {
    try {
      return trends.firstWhere((trend) => trend.type == type);
    } catch (e) {
      return null;
    }
  }

  Color get statusColor => vitalsStatus.color;
  String get statusDisplayName => vitalsStatus.displayName;

  String get ageGenderDisplay => '$age yrs, ${gender.displayName}';

  String get conditionsDisplayText {
    if (primaryConditions.isEmpty) return 'No conditions';
    return primaryConditions.map((c) => c.displayName).join(', ');
  }

  // Calculate vitals compliance based on frequency of readings
  static double _calculateVitalsCompliance(List<VitalsModel> vitalsHistory) {
    if (vitalsHistory.isEmpty) return 0.0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentVitals = vitalsHistory
        .where((vital) => vital.timestamp.isAfter(thirtyDaysAgo))
        .length;

    // Expected: at least 15 readings in 30 days (every 2 days)
    const expectedReadings = 15;
    final compliance = (recentVitals / expectedReadings) * 100;
    
    return compliance > 100 ? 100.0 : compliance;
  }

  // Assess overall vitals status based on latest readings and risk level
  static VitalsStatus _assessOverallVitalsStatus(
    VitalsModel? latestVitals,
    RiskLevel currentRiskLevel,
  ) {
    if (latestVitals == null) return VitalsStatus.normal;

    // Check for critical values
    if (_isCriticalVitals(latestVitals)) return VitalsStatus.critical;
    if (_isHighRiskVitals(latestVitals)) return VitalsStatus.high;
    if (_isElevatedVitals(latestVitals)) return VitalsStatus.elevated;

    // Also consider the patient's overall risk level
    switch (currentRiskLevel) {
      case RiskLevel.critical:
        return VitalsStatus.critical;
      case RiskLevel.high:
        return VitalsStatus.high;
      case RiskLevel.elevated:
        return VitalsStatus.elevated;
      case RiskLevel.normal:
        return VitalsStatus.normal;
    }
  }

  static bool _isCriticalVitals(VitalsModel vitals) {
    return (vitals.systolicBP != null && vitals.systolicBP! > 180) ||
           (vitals.diastolicBP != null && vitals.diastolicBP! > 110) ||
           (vitals.bloodGlucose != null && vitals.bloodGlucose! > 300) ||
           (vitals.heartRate != null && (vitals.heartRate! > 120 || vitals.heartRate! < 40));
  }

  static bool _isHighRiskVitals(VitalsModel vitals) {
    return (vitals.systolicBP != null && vitals.systolicBP! > 160) ||
           (vitals.diastolicBP != null && vitals.diastolicBP! > 100) ||
           (vitals.bloodGlucose != null && vitals.bloodGlucose! > 250) ||
           (vitals.heartRate != null && (vitals.heartRate! > 100 || vitals.heartRate! < 50));
  }

  static bool _isElevatedVitals(VitalsModel vitals) {
    return (vitals.systolicBP != null && vitals.systolicBP! > 140) ||
           (vitals.diastolicBP != null && vitals.diastolicBP! > 90) ||
           (vitals.bloodGlucose != null && vitals.bloodGlucose! > 180) ||
           (vitals.heartRate != null && (vitals.heartRate! > 90 || vitals.heartRate! < 60));
  }
}

class PopulationHealthStats {
  final int totalPatients;
  final double averageAge;
  final Map<Gender, int> genderDistribution;
  final Map<PrimaryCondition, int> conditionBreakdown;
  final double normalVitalsPercentage;
  final double elevatedVitalsPercentage;
  final double highRiskPercentage;
  final double criticalPercentage;
  final double averageComplianceScore;
  final double averageBP;
  final double averageGlucose;
  final double averageWeight;
  final double averageHeartRate;
  final int totalAlerts;
  final DateTime lastUpdated;

  const PopulationHealthStats({
    required this.totalPatients,
    required this.averageAge,
    required this.genderDistribution,
    required this.conditionBreakdown,
    required this.normalVitalsPercentage,
    required this.elevatedVitalsPercentage,
    required this.highRiskPercentage,
    required this.criticalPercentage,
    required this.averageComplianceScore,
    required this.averageBP,
    required this.averageGlucose,
    required this.averageWeight,
    required this.averageHeartRate,
    required this.totalAlerts,
    required this.lastUpdated,
  });

  factory PopulationHealthStats.fromPatientList(List<PatientVitalsOverview> patients) {
    if (patients.isEmpty) {
      return PopulationHealthStats(
        totalPatients: 0,
        averageAge: 0.0,
        genderDistribution: {},
        conditionBreakdown: {},
        normalVitalsPercentage: 0.0,
        elevatedVitalsPercentage: 0.0,
        highRiskPercentage: 0.0,
        criticalPercentage: 0.0,
        averageComplianceScore: 0.0,
        averageBP: 0.0,
        averageGlucose: 0.0,
        averageWeight: 0.0,
        averageHeartRate: 0.0,
        totalAlerts: 0,
        lastUpdated: DateTime.now(),
      );
    }

    // Calculate demographics
    final totalPatients = patients.length;
    final averageAge = patients.map((p) => p.age).reduce((a, b) => a + b) / totalPatients;

    // Gender distribution
    final genderDistribution = <Gender, int>{};
    for (final patient in patients) {
      genderDistribution[patient.gender] = (genderDistribution[patient.gender] ?? 0) + 1;
    }

    // Condition breakdown
    final conditionBreakdown = <PrimaryCondition, int>{};
    for (final patient in patients) {
      for (final condition in patient.primaryConditions) {
        conditionBreakdown[condition] = (conditionBreakdown[condition] ?? 0) + 1;
      }
    }

    // Vitals status distribution
    final statusCounts = <VitalsStatus, int>{};
    for (final patient in patients) {
      statusCounts[patient.vitalsStatus] = (statusCounts[patient.vitalsStatus] ?? 0) + 1;
    }

    final normalCount = statusCounts[VitalsStatus.normal] ?? 0;
    final elevatedCount = statusCounts[VitalsStatus.elevated] ?? 0;
    final highCount = statusCounts[VitalsStatus.high] ?? 0;
    final criticalCount = statusCounts[VitalsStatus.critical] ?? 0;

    // Calculate averages
    final averageComplianceScore = patients.map((p) => p.complianceScore).reduce((a, b) => a + b) / totalPatients;

    // Average vitals (only from patients who have readings)
    final patientsWithBP = patients.where((p) => p.latestSystolicBP != null).toList();
    final averageBP = patientsWithBP.isNotEmpty 
        ? patientsWithBP.map((p) => p.latestSystolicBP!.toDouble()).reduce((a, b) => a + b) / patientsWithBP.length
        : 0.0;

    final patientsWithGlucose = patients.where((p) => p.latestGlucose != null).toList();
    final averageGlucose = patientsWithGlucose.isNotEmpty
        ? patientsWithGlucose.map((p) => p.latestGlucose!).reduce((a, b) => a + b) / patientsWithGlucose.length
        : 0.0;

    final patientsWithWeight = patients.where((p) => p.latestWeight != null).toList();
    final averageWeight = patientsWithWeight.isNotEmpty
        ? patientsWithWeight.map((p) => p.latestWeight!).reduce((a, b) => a + b) / patientsWithWeight.length
        : 0.0;

    final patientsWithHR = patients.where((p) => p.latestHeartRate != null).toList();
    final averageHeartRate = patientsWithHR.isNotEmpty
        ? patientsWithHR.map((p) => p.latestHeartRate!).reduce((a, b) => a + b) / patientsWithHR.length
        : 0.0;

    final totalAlerts = patients.map((p) => p.activeAlerts.length).fold(0, (a, b) => a + b);

    return PopulationHealthStats(
      totalPatients: totalPatients,
      averageAge: averageAge,
      genderDistribution: genderDistribution,
      conditionBreakdown: conditionBreakdown,
      normalVitalsPercentage: (normalCount / totalPatients) * 100,
      elevatedVitalsPercentage: (elevatedCount / totalPatients) * 100,
      highRiskPercentage: (highCount / totalPatients) * 100,
      criticalPercentage: (criticalCount / totalPatients) * 100,
      averageComplianceScore: averageComplianceScore,
      averageBP: averageBP,
      averageGlucose: averageGlucose,
      averageWeight: averageWeight,
      averageHeartRate: averageHeartRate,
      totalAlerts: totalAlerts,
      lastUpdated: DateTime.now(),
    );
  }

  String get averageAgeDisplay => averageAge.toStringAsFixed(1);
  String get averageBPDisplay => '${averageBP.toStringAsFixed(0)} mmHg';
  String get averageGlucoseDisplay => '${averageGlucose.toStringAsFixed(0)} mg/dL';
  String get averageWeightDisplay => '${averageWeight.toStringAsFixed(1)} kg';
  String get averageHeartRateDisplay => '${averageHeartRate.toStringAsFixed(0)} bpm';
  String get averageComplianceDisplay => '${averageComplianceScore.toStringAsFixed(1)}%';
}

// Filter enums for dashboard
enum VitalsFilter {
  all('All Patients'),
  normal('Normal'),
  elevated('Elevated'),
  high('High Risk'),
  critical('Critical'),
  overdue('Overdue');

  const VitalsFilter(this.displayName);
  final String displayName;
}

// Utility class for vitals calculations
class VitalsAnalytics {
  static List<RiskAlert> generateAlertsFromPatients(List<PatientVitalsOverview> patients) {
    final alerts = <RiskAlert>[];

    for (final patient in patients) {
      // Critical vitals alerts
      if (patient.vitalsStatus == VitalsStatus.critical) {
        alerts.add(RiskAlert(
          id: '${patient.patientId}_critical',
          patientId: patient.patientId,
          patientName: patient.patientName,
          type: 'critical_vitals',
          title: 'Critical Vitals Detected',
          message: '${patient.patientName} has critical vital signs requiring immediate attention',
          severity: VitalsStatus.critical,
          timestamp: patient.lastVitalsTimestamp ?? DateTime.now(),
        ));
      }

      // Trend warning alerts
      for (final trend in patient.trends) {
        if (trend.direction == TrendDirection.declining && trend.changeValue.abs() > 10) {
          alerts.add(RiskAlert(
            id: '${patient.patientId}_trend_${trend.type.name}',
            patientId: patient.patientId,
            patientName: patient.patientName,
            type: 'trend_warning',
            vitalType: trend.type,
            title: 'Concerning ${trend.type.displayName} Trend',
            message: '${patient.patientName}\'s ${trend.type.displayName} is ${trend.changeText}',
            severity: VitalsStatus.elevated,
            timestamp: DateTime.now(),
          ));
        }
      }

      // Missing data alerts
      if (patient.missedReadingsCount >= 3) {
        alerts.add(RiskAlert(
          id: '${patient.patientId}_missing_data',
          patientId: patient.patientId,
          patientName: patient.patientName,
          type: 'missing_data',
          title: 'Missing Vitals Data',
          message: '${patient.patientName} hasn\'t recorded vitals for ${patient.missedReadingsCount} days',
          severity: patient.missedReadingsCount >= 7 ? VitalsStatus.high : VitalsStatus.elevated,
          timestamp: DateTime.now(),
        ));
      }
    }

    // Sort alerts by severity and timestamp
    alerts.sort((a, b) {
      final severityComparison = b.severity.index.compareTo(a.severity.index);
      if (severityComparison != 0) return severityComparison;
      return b.timestamp.compareTo(a.timestamp);
    });

    return alerts;
  }
}
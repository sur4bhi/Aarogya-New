import 'package:flutter/material.dart';

// Alert Categories
enum AlertCategory {
  criticalVitals,
  missedCheckIn,
  emergencySOS,
  medicationAdherence,
  appointmentReminder,
  patternConcern,
}

// Alert Types for detailed classification
enum AlertType {
  // Critical Vitals
  bloodPressureCritical,
  bloodPressureWarning,
  bloodGlucoseCritical,
  bloodGlucoseWarning,
  heartRateCritical,
  heartRateWarning,
  weightConcern,
  temperatureFever,
  oxygenSaturationLow,
  
  // Check-in Related
  missedDailyCheckIn,
  patientUnreachable,
  overdueMeasurement,
  
  // Emergency
  sosActivated,
  emergencyCall,
  criticalPattern,
  
  // Medication
  medicationMissed,
  criticalMedicationDelayed,
  lowAdherenceScore,
  medicationInteraction,
  
  // Appointments
  upcomingAppointment,
  missedAppointment,
  followUpRequired,
  
  // Patterns & Trends
  decliningTrend,
  abnormalPattern,
  riskFactorIncrease,
}

// Alert Severity Levels
enum AlertSeverity {
  critical, // Red - Immediate action required
  high,     // Orange - Same day action
  medium,   // Yellow - Within 48 hours
  low,      // Blue - Informational
}

// Alert Status
enum AlertStatus {
  active,
  acknowledged,
  inProgress,
  resolved,
  dismissed,
}

// Alert Priority for processing
enum NotificationPriority {
  emergency,  // SOS, critical vitals
  urgent,     // High severity alerts
  normal,     // Medium severity alerts
  background, // Low priority, batch processing
}

// Patient Alert Model
class PatientAlert {
  final String alertId;
  final String patientId;
  final String patientName;
  final AlertType alertType;
  final AlertCategory alertCategory;
  final AlertSeverity severity;
  final AlertStatus status;
  
  // Vital readings related
  final double? triggerValue;
  final double? thresholdValue;
  final String? units;
  
  // Timing
  final DateTime timestamp;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  
  // Action tracking
  final bool isRead;
  final bool isActionTaken;
  final String? actionTaken;
  final String? assignedTo; // ASHA worker ID
  final String? notes;
  
  // Additional context
  final Map<String, dynamic>? metadata;
  final String? location; // GPS coordinates for SOS
  final List<String>? emergencyContacts;
  
  // Priority and routing
  final NotificationPriority priority;
  final bool requiresAcknowledgment;
  final Duration? escalationTime;

  const PatientAlert({
    required this.alertId,
    required this.patientId,
    required this.patientName,
    required this.alertType,
    required this.alertCategory,
    required this.severity,
    required this.timestamp,
    this.status = AlertStatus.active,
    this.triggerValue,
    this.thresholdValue,
    this.units,
    this.acknowledgedAt,
    this.resolvedAt,
    this.isRead = false,
    this.isActionTaken = false,
    this.actionTaken,
    this.assignedTo,
    this.notes,
    this.metadata,
    this.location,
    this.emergencyContacts,
    this.priority = NotificationPriority.normal,
    this.requiresAcknowledgment = false,
    this.escalationTime,
  });

  // Create copy with updated fields
  PatientAlert copyWith({
    String? alertId,
    String? patientId,
    String? patientName,
    AlertType? alertType,
    AlertCategory? alertCategory,
    AlertSeverity? severity,
    AlertStatus? status,
    double? triggerValue,
    double? thresholdValue,
    String? units,
    DateTime? timestamp,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    bool? isRead,
    bool? isActionTaken,
    String? actionTaken,
    String? assignedTo,
    String? notes,
    Map<String, dynamic>? metadata,
    String? location,
    List<String>? emergencyContacts,
    NotificationPriority? priority,
    bool? requiresAcknowledgment,
    Duration? escalationTime,
  }) {
    return PatientAlert(
      alertId: alertId ?? this.alertId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      alertType: alertType ?? this.alertType,
      alertCategory: alertCategory ?? this.alertCategory,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      triggerValue: triggerValue ?? this.triggerValue,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      units: units ?? this.units,
      timestamp: timestamp ?? this.timestamp,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isRead: isRead ?? this.isRead,
      isActionTaken: isActionTaken ?? this.isActionTaken,
      actionTaken: actionTaken ?? this.actionTaken,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      location: location ?? this.location,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      priority: priority ?? this.priority,
      requiresAcknowledgment: requiresAcknowledgment ?? this.requiresAcknowledgment,
      escalationTime: escalationTime ?? this.escalationTime,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'patientId': patientId,
      'patientName': patientName,
      'alertType': alertType.name,
      'alertCategory': alertCategory.name,
      'severity': severity.name,
      'status': status.name,
      'triggerValue': triggerValue,
      'thresholdValue': thresholdValue,
      'units': units,
      'timestamp': timestamp.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'isRead': isRead,
      'isActionTaken': isActionTaken,
      'actionTaken': actionTaken,
      'assignedTo': assignedTo,
      'notes': notes,
      'metadata': metadata,
      'location': location,
      'emergencyContacts': emergencyContacts,
      'priority': priority.name,
      'requiresAcknowledgment': requiresAcknowledgment,
      'escalationTime': escalationTime?.inMilliseconds,
    };
  }

  // Create from JSON
  factory PatientAlert.fromJson(Map<String, dynamic> json) {
    return PatientAlert(
      alertId: json['alertId'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      alertType: AlertType.values.byName(json['alertType']),
      alertCategory: AlertCategory.values.byName(json['alertCategory']),
      severity: AlertSeverity.values.byName(json['severity']),
      status: AlertStatus.values.byName(json['status'] ?? 'active'),
      triggerValue: json['triggerValue']?.toDouble(),
      thresholdValue: json['thresholdValue']?.toDouble(),
      units: json['units'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      isActionTaken: json['isActionTaken'] as bool? ?? false,
      actionTaken: json['actionTaken'] as String?,
      assignedTo: json['assignedTo'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      location: json['location'] as String?,
      emergencyContacts: (json['emergencyContacts'] as List?)?.cast<String>(),
      priority: NotificationPriority.values.byName(json['priority'] ?? 'normal'),
      requiresAcknowledgment: json['requiresAcknowledgment'] as bool? ?? false,
      escalationTime: json['escalationTime'] != null
          ? Duration(milliseconds: json['escalationTime'] as int)
          : null,
    );
  }

  // Utility getters
  bool get isOverdue {
    if (escalationTime == null) return false;
    return DateTime.now().difference(timestamp) > escalationTime!;
  }

  bool get isCritical => severity == AlertSeverity.critical;
  bool get isEmergency => alertCategory == AlertCategory.emergencySOS;
  bool get isActive => status == AlertStatus.active;
  bool get isResolved => status == AlertStatus.resolved;

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.medium:
        return Colors.yellow[700]!;
      case AlertSeverity.low:
        return Colors.blue;
    }
  }

  IconData get categoryIcon {
    switch (alertCategory) {
      case AlertCategory.criticalVitals:
        return Icons.favorite;
      case AlertCategory.missedCheckIn:
        return Icons.schedule;
      case AlertCategory.emergencySOS:
        return Icons.emergency;
      case AlertCategory.medicationAdherence:
        return Icons.medication;
      case AlertCategory.appointmentReminder:
        return Icons.calendar_today;
      case AlertCategory.patternConcern:
        return Icons.trending_down;
    }
  }

  String get title {
    switch (alertType) {
      case AlertType.bloodPressureCritical:
        return 'गंभीर रक्तचाप';
      case AlertType.bloodPressureWarning:
        return 'उच्च रक्तचाप';
      case AlertType.bloodGlucoseCritical:
        return 'गंभीर रक्त शर्करा';
      case AlertType.bloodGlucoseWarning:
        return 'उच्च रक्त शर्करा';
      case AlertType.heartRateCritical:
        return 'गंभीर हृदय गति';
      case AlertType.heartRateWarning:
        return 'असामान्य हृदय गति';
      case AlertType.missedDailyCheckIn:
        return 'दैनिक जांच छूट गई';
      case AlertType.patientUnreachable:
        return 'मरीज़ से संपर्क नहीं';
      case AlertType.sosActivated:
        return 'आपातकालीन SOS';
      case AlertType.medicationMissed:
        return 'दवा छूट गई';
      case AlertType.criticalMedicationDelayed:
        return 'महत्वपूर्ण दवा देरी';
      case AlertType.upcomingAppointment:
        return 'आगामी अपॉइंटमेंट';
      case AlertType.decliningTrend:
        return 'गिरावट की प्रवृत्ति';
      default:
        return 'स्वास्थ्य अलर्ट';
    }
  }

  String get message {
    switch (alertType) {
      case AlertType.bloodPressureCritical:
        return '${patientName} का रक्तचाप ${triggerValue?.round()}/${(triggerValue! * 0.65).round()} है, तुरंत कार्रवाई करें';
      case AlertType.bloodGlucoseCritical:
        return '${patientName} का रक्त शर्करा ${triggerValue?.round()} mg/dL है, तुरंत डॉक्टर से संपर्क करें';
      case AlertType.missedDailyCheckIn:
        return '${patientName} ने आज अपनी दैनिक जांच नहीं की है';
      case AlertType.sosActivated:
        return '${patientName} ने आपातकालीन SOS सक्रिय किया है';
      case AlertType.medicationMissed:
        return '${patientName} ने अपनी दवा नहीं ली है';
      case AlertType.upcomingAppointment:
        return '${patientName} का अपॉइंटमेंट कल है';
      default:
        return '${patientName} को चिकित्सा ध्यान की आवश्यकता है';
    }
  }
}

// Alert Threshold Configuration
class AlertThreshold {
  final String patientId;
  final String vitalType;
  final double criticalHigh;
  final double criticalLow;
  final double warningHigh;
  final double warningLow;
  final bool isEnabled;
  final DateTime lastUpdated;
  final String? customizedBy; // Doctor/ASHA who set custom thresholds

  const AlertThreshold({
    required this.patientId,
    required this.vitalType,
    required this.criticalHigh,
    required this.criticalLow,
    required this.warningHigh,
    required this.warningLow,
    this.isEnabled = true,
    required this.lastUpdated,
    this.customizedBy,
  });

  AlertThreshold copyWith({
    String? patientId,
    String? vitalType,
    double? criticalHigh,
    double? criticalLow,
    double? warningHigh,
    double? warningLow,
    bool? isEnabled,
    DateTime? lastUpdated,
    String? customizedBy,
  }) {
    return AlertThreshold(
      patientId: patientId ?? this.patientId,
      vitalType: vitalType ?? this.vitalType,
      criticalHigh: criticalHigh ?? this.criticalHigh,
      criticalLow: criticalLow ?? this.criticalLow,
      warningHigh: warningHigh ?? this.warningHigh,
      warningLow: warningLow ?? this.warningLow,
      isEnabled: isEnabled ?? this.isEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      customizedBy: customizedBy ?? this.customizedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'vitalType': vitalType,
      'criticalHigh': criticalHigh,
      'criticalLow': criticalLow,
      'warningHigh': warningHigh,
      'warningLow': warningLow,
      'isEnabled': isEnabled,
      'lastUpdated': lastUpdated.toIso8601String(),
      'customizedBy': customizedBy,
    };
  }

  factory AlertThreshold.fromJson(Map<String, dynamic> json) {
    return AlertThreshold(
      patientId: json['patientId'] as String,
      vitalType: json['vitalType'] as String,
      criticalHigh: json['criticalHigh'] as double,
      criticalLow: json['criticalLow'] as double,
      warningHigh: json['warningHigh'] as double,
      warningLow: json['warningLow'] as double,
      isEnabled: json['isEnabled'] as bool? ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      customizedBy: json['customizedBy'] as String?,
    );
  }

  // Default thresholds for different conditions
  static AlertThreshold defaultBloodPressure(String patientId) {
    return AlertThreshold(
      patientId: patientId,
      vitalType: 'bloodPressure',
      criticalHigh: 180,
      criticalLow: 80,
      warningHigh: 140,
      warningLow: 90,
      lastUpdated: DateTime.now(),
    );
  }

  static AlertThreshold defaultBloodGlucose(String patientId) {
    return AlertThreshold(
      patientId: patientId,
      vitalType: 'bloodGlucose',
      criticalHigh: 300,
      criticalLow: 60,
      warningHigh: 180,
      warningLow: 70,
      lastUpdated: DateTime.now(),
    );
  }

  static AlertThreshold defaultHeartRate(String patientId) {
    return AlertThreshold(
      patientId: patientId,
      vitalType: 'heartRate',
      criticalHigh: 120,
      criticalLow: 40,
      warningHigh: 100,
      warningLow: 60,
      lastUpdated: DateTime.now(),
    );
  }
}

// Alert Rule for automated processing
class AlertRule {
  final String ruleId;
  final String name;
  final AlertCategory category;
  final AlertType alertType;
  final bool isEnabled;
  final Map<String, dynamic> conditions;
  final AlertSeverity severity;
  final NotificationPriority priority;
  final Duration? escalationTime;
  final List<String> channels; // 'app', 'sms', 'call'
  
  const AlertRule({
    required this.ruleId,
    required this.name,
    required this.category,
    required this.alertType,
    required this.conditions,
    required this.severity,
    this.isEnabled = true,
    this.priority = NotificationPriority.normal,
    this.escalationTime,
    this.channels = const ['app'],
  });

  AlertRule copyWith({
    String? ruleId,
    String? name,
    AlertCategory? category,
    AlertType? alertType,
    bool? isEnabled,
    Map<String, dynamic>? conditions,
    AlertSeverity? severity,
    NotificationPriority? priority,
    Duration? escalationTime,
    List<String>? channels,
  }) {
    return AlertRule(
      ruleId: ruleId ?? this.ruleId,
      name: name ?? this.name,
      category: category ?? this.category,
      alertType: alertType ?? this.alertType,
      isEnabled: isEnabled ?? this.isEnabled,
      conditions: conditions ?? this.conditions,
      severity: severity ?? this.severity,
      priority: priority ?? this.priority,
      escalationTime: escalationTime ?? this.escalationTime,
      channels: channels ?? this.channels,
    );
  }
}

// Medication Adherence Alert Model
class MedicationAdherenceAlert {
  final String patientId;
  final String medicationName;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool isCriticalMedication;
  final int consecutiveMissed;
  final double weeklyAdherenceRate;

  const MedicationAdherenceAlert({
    required this.patientId,
    required this.medicationName,
    required this.scheduledTime,
    this.takenTime,
    required this.isCriticalMedication,
    required this.consecutiveMissed,
    required this.weeklyAdherenceRate,
  });

  bool get isMissed => takenTime == null && DateTime.now().isAfter(scheduledTime.add(const Duration(hours: 2)));
  bool get isDelayed => takenTime == null && DateTime.now().isAfter(scheduledTime.add(const Duration(hours: 1)));
  bool get requiresAlert => 
    (isCriticalMedication && isDelayed) || 
    consecutiveMissed >= 3 || 
    weeklyAdherenceRate < 0.7;
}

// Emergency Contact Model
class EmergencyContact {
  final String contactId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final bool canReceiveSMS;
  final bool canReceiveCalls;

  const EmergencyContact({
    required this.contactId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
    this.canReceiveSMS = true,
    this.canReceiveCalls = true,
  });
}
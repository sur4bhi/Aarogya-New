import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final VitalType type;
  final Map<String, dynamic> values;
  final String? notes;
  final bool isManualEntry;
  final String? deviceId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  VitalsModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    required this.values,
    this.notes,
    this.isManualEntry = true,
    this.deviceId,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Specific getters for different vital types
  double? get systolicBP => values['systolic']?.toDouble();
  double? get diastolicBP => values['diastolic']?.toDouble();
  double? get heartRate => values['heartRate']?.toDouble();
  double? get temperature => values['temperature']?.toDouble();
  double? get oxygenSaturation => values['oxygenSaturation']?.toDouble();
  double? get weight => values['weight']?.toDouble();
  double? get height => values['height']?.toDouble();
  double? get bloodGlucose => values['bloodGlucose']?.toDouble();
  String? get glucoseType => values['glucoseType'];

  // Calculated values
  double? get bmi {
    final w = weight;
    final h = height;
    if (w != null && h != null && h > 0) {
      final heightInMeters = h / 100;
      return w / (heightInMeters * heightInMeters);
    }
    return null;
  }

  String get bloodPressureString {
    final sys = systolicBP;
    final dia = diastolicBP;
    if (sys != null && dia != null) {
      return '${sys.toInt()}/${dia.toInt()}';
    }
    return '';
  }

  // Health status assessment
  HealthStatus get healthStatus {
    switch (type) {
      case VitalType.bloodPressure:
        return _assessBloodPressureStatus();
      case VitalType.heartRate:
        return _assessHeartRateStatus();
      case VitalType.temperature:
        return _assessTemperatureStatus();
      case VitalType.oxygenSaturation:
        return _assessOxygenSaturationStatus();
      case VitalType.bloodGlucose:
        return _assessBloodGlucoseStatus();
      case VitalType.weight:
        return _assessWeightStatus();
      default:
        return HealthStatus.normal;
    }
  }

  HealthStatus _assessBloodPressureStatus() {
    final sys = systolicBP;
    final dia = diastolicBP;
    if (sys == null || dia == null) return HealthStatus.unknown;

    if (sys >= 180 || dia >= 120) return HealthStatus.critical;
    if (sys >= 140 || dia >= 90) return HealthStatus.high;
    if (sys >= 130 || dia >= 80) return HealthStatus.elevated;
    if (sys < 90 || dia < 60) return HealthStatus.low;
    return HealthStatus.normal;
  }

  HealthStatus _assessHeartRateStatus() {
    final hr = heartRate;
    if (hr == null) return HealthStatus.unknown;

    if (hr < 40 || hr > 120) return HealthStatus.critical;
    if (hr < 60 || hr > 100) return HealthStatus.elevated;
    return HealthStatus.normal;
  }

  HealthStatus _assessTemperatureStatus() {
    final temp = temperature;
    if (temp == null) return HealthStatus.unknown;

    if (temp < 95.0 || temp > 103.0) return HealthStatus.critical;
    if (temp > 100.4) return HealthStatus.high;
    if (temp > 99.5) return HealthStatus.elevated;
    if (temp < 97.0) return HealthStatus.low;
    return HealthStatus.normal;
  }

  HealthStatus _assessOxygenSaturationStatus() {
    final oxygen = oxygenSaturation;
    if (oxygen == null) return HealthStatus.unknown;

    if (oxygen < 85) return HealthStatus.critical;
    if (oxygen < 90) return HealthStatus.high;
    if (oxygen < 95) return HealthStatus.elevated;
    return HealthStatus.normal;
  }

  HealthStatus _assessBloodGlucoseStatus() {
    final glucose = bloodGlucose;
    final type = glucoseType ?? 'random';
    if (glucose == null) return HealthStatus.unknown;

    if (glucose < 50 || glucose > 400) return HealthStatus.critical;

    switch (type.toLowerCase()) {
      case 'fasting':
        if (glucose > 125) return HealthStatus.high;
        if (glucose > 99) return HealthStatus.elevated;
        if (glucose < 70) return HealthStatus.low;
        break;
      case 'random':
      case 'postprandial':
        if (glucose > 199) return HealthStatus.high;
        if (glucose > 140) return HealthStatus.elevated;
        if (glucose < 70) return HealthStatus.low;
        break;
    }
    return HealthStatus.normal;
  }

  HealthStatus _assessWeightStatus() {
    final bmiValue = bmi;
    if (bmiValue == null) return HealthStatus.unknown;

    if (bmiValue < 16 || bmiValue > 40) return HealthStatus.critical;
    if (bmiValue < 18.5 || bmiValue > 30) return HealthStatus.elevated;
    if (bmiValue > 25) return HealthStatus.elevated;
    return HealthStatus.normal;
  }

  // Factory constructor from Firestore
  factory VitalsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VitalsModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: VitalType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => VitalType.other,
      ),
      values: Map<String, dynamic>.from(data['values'] ?? {}),
      notes: data['notes'],
      isManualEntry: data['isManualEntry'] ?? true,
      deviceId: data['deviceId'],
      isSynced: data['isSynced'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Factory constructor from JSON
  factory VitalsModel.fromJson(Map<String, dynamic> json) {
    return VitalsModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      type: VitalType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => VitalType.other,
      ),
      values: Map<String, dynamic>.from(json['values'] ?? {}),
      notes: json['notes'],
      isManualEntry: json['isManualEntry'] ?? true,
      deviceId: json['deviceId'],
      isSynced: json['isSynced'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'values': values,
      'notes': notes,
      'isManualEntry': isManualEntry,
      'deviceId': deviceId,
      'isSynced': isSynced,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'values': values,
      'notes': notes,
      'isManualEntry': isManualEntry,
      'deviceId': deviceId,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  VitalsModel copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    VitalType? type,
    Map<String, dynamic>? values,
    String? notes,
    bool? isManualEntry,
    String? deviceId,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VitalsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      deviceId: deviceId ?? this.deviceId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'VitalsModel(id: $id, type: $type, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VitalsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Vital type enum
enum VitalType {
  bloodPressure,
  heartRate,
  temperature,
  oxygenSaturation,
  weight,
  height,
  bloodGlucose,
  other,
}

// Health status enum
enum HealthStatus {
  critical,
  high,
  elevated,
  normal,
  low,
  unknown,
}

// Extension methods
extension VitalTypeExtension on VitalType {
  String get displayName {
    switch (this) {
      case VitalType.bloodPressure:
        return 'Blood Pressure';
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.temperature:
        return 'Temperature';
      case VitalType.oxygenSaturation:
        return 'Oxygen Saturation';
      case VitalType.weight:
        return 'Weight';
      case VitalType.height:
        return 'Height';
      case VitalType.bloodGlucose:
        return 'Blood Glucose';
      case VitalType.other:
        return 'Other';
    }
  }

  String get unit {
    switch (this) {
      case VitalType.bloodPressure:
        return 'mmHg';
      case VitalType.heartRate:
        return 'bpm';
      case VitalType.temperature:
        return '°F';
      case VitalType.oxygenSaturation:
        return '%';
      case VitalType.weight:
        return 'kg';
      case VitalType.height:
        return 'cm';
      case VitalType.bloodGlucose:
        return 'mg/dL';
      case VitalType.other:
        return '';
    }
  }

  String get icon {
    switch (this) {
      case VitalType.bloodPressure:
        return '🩺';
      case VitalType.heartRate:
        return '❤️';
      case VitalType.temperature:
        return '🌡️';
      case VitalType.oxygenSaturation:
        return '🫁';
      case VitalType.weight:
        return '⚖️';
      case VitalType.height:
        return '📏';
      case VitalType.bloodGlucose:
        return '🩸';
      case VitalType.other:
        return '📊';
    }
  }
}

extension HealthStatusExtension on HealthStatus {
  String get displayName {
    switch (this) {
      case HealthStatus.critical:
        return 'Critical';
      case HealthStatus.high:
        return 'High';
      case HealthStatus.elevated:
        return 'Elevated';
      case HealthStatus.normal:
        return 'Normal';
      case HealthStatus.low:
        return 'Low';
      case HealthStatus.unknown:
        return 'Unknown';
    }
  }

  String get color {
    switch (this) {
      case HealthStatus.critical:
        return '#F44336'; // Red
      case HealthStatus.high:
        return '#FF5722'; // Deep Orange
      case HealthStatus.elevated:
        return '#FF9800'; // Orange
      case HealthStatus.normal:
        return '#4CAF50'; // Green
      case HealthStatus.low:
        return '#2196F3'; // Blue
      case HealthStatus.unknown:
        return '#9E9E9E'; // Grey
    }
  }

  int get priority {
    switch (this) {
      case HealthStatus.critical:
        return 5;
      case HealthStatus.high:
        return 4;
      case HealthStatus.elevated:
        return 3;
      case HealthStatus.normal:
        return 1;
      case HealthStatus.low:
        return 2;
      case HealthStatus.unknown:
        return 0;
    }
  }
}

// Vitals summary model for dashboard
class VitalsSummary {
  final VitalType type;
  final VitalsModel? latestReading;
  final List<VitalsModel> recentReadings;
  final HealthStatus overallStatus;
  final String trend; // 'improving', 'stable', 'declining'

  VitalsSummary({
    required this.type,
    this.latestReading,
    this.recentReadings = const [],
    required this.overallStatus,
    required this.trend,
  });

  bool get hasData => latestReading != null;
  
  DateTime? get lastRecordedAt => latestReading?.timestamp;
  
  int get daysSinceLastReading {
    if (lastRecordedAt == null) return -1;
    return DateTime.now().difference(lastRecordedAt!).inDays;
  }
}

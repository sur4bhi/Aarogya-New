import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final ReminderType type;
  final DateTime scheduledTime;
  final ReminderFrequency frequency;
  final bool isActive;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final int snoozeCount;
  final DateTime? lastSnoozedAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Medication specific fields
  final String? medicationName;
  final String? dosage;
  final String? instructions;
  final String? medicationImageUrl;
  
  // Appointment specific fields
  final String? doctorName;
  final String? hospitalName;
  final String? appointmentType;
  final String? location;
  final String? notes;
  
  // Health check specific fields
  final String? vitalType;
  final String? targetValue;
  final String? unit;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.scheduledTime,
    this.frequency = ReminderFrequency.once,
    this.isActive = true,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.snoozeCount = 0,
    this.lastSnoozedAt,
    this.tags = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.medicationName,
    this.dosage,
    this.instructions,
    this.medicationImageUrl,
    this.doctorName,
    this.hospitalName,
    this.appointmentType,
    this.location,
    this.notes,
    this.vitalType,
    this.targetValue,
    this.unit,
  });

  // Computed properties
  bool get isOverdue {
    if (isCompleted || !isActive) return false;
    return DateTime.now().isAfter(scheduledTime);
  }

  bool get isDueToday {
    if (isCompleted || !isActive) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
    return reminderDate.isAtSameMomentAs(today);
  }

  bool get isDueSoon {
    if (isCompleted || !isActive) return false;
    final now = DateTime.now();
    final timeDifference = scheduledTime.difference(now);
    return timeDifference.inMinutes <= 30 && timeDifference.inMinutes > 0;
  }

  Duration get timeUntilDue {
    return scheduledTime.difference(DateTime.now());
  }

  Duration get timeSinceDue {
    return DateTime.now().difference(scheduledTime);
  }

  String get statusText {
    if (isCompleted) return 'Completed';
    if (!isActive) return 'Inactive';
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';
    if (isDueToday) return 'Due Today';
    return 'Scheduled';
  }

  ReminderPriority get priority {
    if (isOverdue) return ReminderPriority.high;
    if (isDueSoon) return ReminderPriority.medium;
    if (isDueToday) return ReminderPriority.medium;
    return ReminderPriority.low;
  }

  // Get next occurrence for recurring reminders
  DateTime? getNextOccurrence() {
    if (frequency == ReminderFrequency.once || !isActive) return null;
    
    DateTime nextTime = scheduledTime;
    final now = DateTime.now();
    
    while (nextTime.isBefore(now)) {
      switch (frequency) {
        case ReminderFrequency.daily:
          nextTime = nextTime.add(const Duration(days: 1));
          break;
        case ReminderFrequency.weekly:
          nextTime = nextTime.add(const Duration(days: 7));
          break;
        case ReminderFrequency.monthly:
          nextTime = DateTime(
            nextTime.year,
            nextTime.month + 1,
            nextTime.day,
            nextTime.hour,
            nextTime.minute,
          );
          break;
        case ReminderFrequency.yearly:
          nextTime = DateTime(
            nextTime.year + 1,
            nextTime.month,
            nextTime.day,
            nextTime.hour,
            nextTime.minute,
          );
          break;
        case ReminderFrequency.custom:
          // Handle custom frequency based on metadata
          final customDays = metadata?['customDays'] as int? ?? 1;
          nextTime = nextTime.add(Duration(days: customDays));
          break;
        case ReminderFrequency.once:
          return null;
      }
    }
    
    return nextTime;
  }

  // Factory constructor from Firestore
  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReminderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      type: ReminderType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => ReminderType.other,
      ),
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      frequency: ReminderFrequency.values.firstWhere(
        (freq) => freq.toString() == data['frequency'],
        orElse: () => ReminderFrequency.once,
      ),
      isActive: data['isActive'] ?? true,
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      completedBy: data['completedBy'],
      snoozeCount: data['snoozeCount'] ?? 0,
      lastSnoozedAt: data['lastSnoozedAt'] != null 
          ? (data['lastSnoozedAt'] as Timestamp).toDate() 
          : null,
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      medicationName: data['medicationName'],
      dosage: data['dosage'],
      instructions: data['instructions'],
      medicationImageUrl: data['medicationImageUrl'],
      doctorName: data['doctorName'],
      hospitalName: data['hospitalName'],
      appointmentType: data['appointmentType'],
      location: data['location'],
      notes: data['notes'],
      vitalType: data['vitalType'],
      targetValue: data['targetValue'],
      unit: data['unit'],
    );
  }

  // Factory constructor from JSON
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: ReminderType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => ReminderType.other,
      ),
      scheduledTime: DateTime.parse(json['scheduledTime']),
      frequency: ReminderFrequency.values.firstWhere(
        (freq) => freq.toString() == json['frequency'],
        orElse: () => ReminderFrequency.once,
      ),
      isActive: json['isActive'] ?? true,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      completedBy: json['completedBy'],
      snoozeCount: json['snoozeCount'] ?? 0,
      lastSnoozedAt: json['lastSnoozedAt'] != null 
          ? DateTime.parse(json['lastSnoozedAt']) 
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      medicationName: json['medicationName'],
      dosage: json['dosage'],
      instructions: json['instructions'],
      medicationImageUrl: json['medicationImageUrl'],
      doctorName: json['doctorName'],
      hospitalName: json['hospitalName'],
      appointmentType: json['appointmentType'],
      location: json['location'],
      notes: json['notes'],
      vitalType: json['vitalType'],
      targetValue: json['targetValue'],
      unit: json['unit'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString(),
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'frequency': frequency.toString(),
      'isActive': isActive,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'snoozeCount': snoozeCount,
      'lastSnoozedAt': lastSnoozedAt != null ? Timestamp.fromDate(lastSnoozedAt!) : null,
      'tags': tags,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'medicationName': medicationName,
      'dosage': dosage,
      'instructions': instructions,
      'medicationImageUrl': medicationImageUrl,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'appointmentType': appointmentType,
      'location': location,
      'notes': notes,
      'vitalType': vitalType,
      'targetValue': targetValue,
      'unit': unit,
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
      'scheduledTime': scheduledTime.toIso8601String(),
      'frequency': frequency.toString(),
      'isActive': isActive,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'snoozeCount': snoozeCount,
      'lastSnoozedAt': lastSnoozedAt?.toIso8601String(),
      'tags': tags,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'medicationName': medicationName,
      'dosage': dosage,
      'instructions': instructions,
      'medicationImageUrl': medicationImageUrl,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'appointmentType': appointmentType,
      'location': location,
      'notes': notes,
      'vitalType': vitalType,
      'targetValue': targetValue,
      'unit': unit,
    };
  }

  // Copy with method
  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ReminderType? type,
    DateTime? scheduledTime,
    ReminderFrequency? frequency,
    bool? isActive,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    int? snoozeCount,
    DateTime? lastSnoozedAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? medicationName,
    String? dosage,
    String? instructions,
    String? medicationImageUrl,
    String? doctorName,
    String? hospitalName,
    String? appointmentType,
    String? location,
    String? notes,
    String? vitalType,
    String? targetValue,
    String? unit,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastSnoozedAt: lastSnoozedAt ?? this.lastSnoozedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      medicationImageUrl: medicationImageUrl ?? this.medicationImageUrl,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      appointmentType: appointmentType ?? this.appointmentType,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      vitalType: vitalType ?? this.vitalType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() {
    return 'ReminderModel(id: $id, title: $title, type: $type, scheduledTime: $scheduledTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Reminder type enum
enum ReminderType {
  medication,
  appointment,
  healthCheck,
  exercise,
  diet,
  other,
}

// Reminder frequency enum
enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

// Reminder priority enum
enum ReminderPriority {
  low,
  medium,
  high,
}

// Extension methods
extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.medication:
        return 'Medication';
      case ReminderType.appointment:
        return 'Appointment';
      case ReminderType.healthCheck:
        return 'Health Check';
      case ReminderType.exercise:
        return 'Exercise';
      case ReminderType.diet:
        return 'Diet';
      case ReminderType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.medication:
        return '💊';
      case ReminderType.appointment:
        return '👨‍⚕️';
      case ReminderType.healthCheck:
        return '🩺';
      case ReminderType.exercise:
        return '🏃‍♂️';
      case ReminderType.diet:
        return '🥗';
      case ReminderType.other:
        return '⏰';
    }
  }

  String get color {
    switch (this) {
      case ReminderType.medication:
        return '#FF5722'; // Deep Orange
      case ReminderType.appointment:
        return '#2196F3'; // Blue
      case ReminderType.healthCheck:
        return '#4CAF50'; // Green
      case ReminderType.exercise:
        return '#FF9800'; // Orange
      case ReminderType.diet:
        return '#9C27B0'; // Purple
      case ReminderType.other:
        return '#607D8B'; // Blue Grey
    }
  }
}

extension ReminderFrequencyExtension on ReminderFrequency {
  String get displayName {
    switch (this) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
      case ReminderFrequency.yearly:
        return 'Yearly';
      case ReminderFrequency.custom:
        return 'Custom';
    }
  }
}

extension ReminderPriorityExtension on ReminderPriority {
  String get displayName {
    switch (this) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.high:
        return 'High';
    }
  }

  String get color {
    switch (this) {
      case ReminderPriority.low:
        return '#4CAF50'; // Green
      case ReminderPriority.medium:
        return '#FF9800'; // Orange
      case ReminderPriority.high:
        return '#F44336'; // Red
    }
  }
}

// Reminder summary for dashboard
class ReminderSummary {
  final int totalReminders;
  final int activeReminders;
  final int completedToday;
  final int overdueReminders;
  final int upcomingReminders;
  final List<ReminderModel> todaysReminders;
  final Map<ReminderType, int> remindersByType;

  ReminderSummary({
    required this.totalReminders,
    required this.activeReminders,
    required this.completedToday,
    required this.overdueReminders,
    required this.upcomingReminders,
    required this.todaysReminders,
    required this.remindersByType,
  });

  double get completionRate {
    if (totalReminders == 0) return 0.0;
    return (completedToday / totalReminders) * 100;
  }

  bool get hasOverdueReminders => overdueReminders > 0;
  bool get hasUpcomingReminders => upcomingReminders > 0;
}

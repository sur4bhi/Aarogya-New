import 'package:cloud_firestore/cloud_firestore.dart';

class AshaModel {
  final String id;
  final String userId; // Reference to UserModel
  final String name;
  final String phoneNumber;
  final String email;
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final List<String> specializations;
  final int experienceYears;
  final String? profileImageUrl;
  final double rating;
  final int totalRatings;
  final int totalPatients;
  final int activePatients;
  final AshaStatus status;
  final bool isVerified;
  final DateTime verificationDate;
  final String? verifiedBy;
  
  // Location and service area
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double serviceRadius; // in kilometers
  final List<String> serviceAreas; // List of pincodes or area names
  
  // Availability
  final Map<String, WorkingHours> weeklySchedule;
  final List<String> languages;
  final bool isAvailable;
  final DateTime? lastActiveAt;
  
  // Performance metrics
  final int totalConsultations;
  final double averageResponseTime; // in minutes
  final int resolvedCases;
  final int referredCases;
  final DateTime createdAt;
  final DateTime updatedAt;

  AshaModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    this.specializations = const [],
    required this.experienceYears,
    this.profileImageUrl,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.totalPatients = 0,
    this.activePatients = 0,
    this.status = AshaStatus.active,
    this.isVerified = false,
    required this.verificationDate,
    this.verifiedBy,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.serviceRadius = 10.0,
    this.serviceAreas = const [],
    this.weeklySchedule = const {},
    this.languages = const [],
    this.isAvailable = true,
    this.lastActiveAt,
    this.totalConsultations = 0,
    this.averageResponseTime = 0.0,
    this.resolvedCases = 0,
    this.referredCases = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  String get displayName => name;
  
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts.first[0].toUpperCase();
    }
    return 'A';
  }

  bool get isLicenseValid => licenseExpiryDate.isAfter(DateTime.now());
  
  int get daysUntilLicenseExpiry => licenseExpiryDate.difference(DateTime.now()).inDays;
  
  bool get isOnline {
    if (lastActiveAt == null) return false;
    return DateTime.now().difference(lastActiveAt!).inMinutes < 15;
  }
  
  String get statusText {
    if (!isVerified) return 'Pending Verification';
    if (!isLicenseValid) return 'License Expired';
    if (!isAvailable) return 'Unavailable';
    if (isOnline) return 'Online';
    return 'Offline';
  }
  
  double get successRate {
    final total = resolvedCases + referredCases;
    if (total == 0) return 0.0;
    return (resolvedCases / total) * 100;
  }
  
  String get experienceText {
    if (experienceYears == 1) return '1 year';
    return '$experienceYears years';
  }
  
  // Check if ASHA is currently working
  bool get isCurrentlyWorking {
    if (!isAvailable || !isVerified) return false;
    
    final now = DateTime.now();
    final dayOfWeek = _getDayOfWeek(now.weekday);
    final workingHours = weeklySchedule[dayOfWeek];
    
    if (workingHours == null || !workingHours.isWorking) return false;
    
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    return workingHours.isWithinWorkingHours(currentTime);
  }
  
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  // Factory constructor from Firestore
  factory AshaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AshaModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      licenseExpiryDate: (data['licenseExpiryDate'] as Timestamp).toDate(),
      specializations: List<String>.from(data['specializations'] ?? []),
      experienceYears: data['experienceYears'] ?? 0,
      profileImageUrl: data['profileImageUrl'],
      rating: data['rating']?.toDouble() ?? 0.0,
      totalRatings: data['totalRatings'] ?? 0,
      totalPatients: data['totalPatients'] ?? 0,
      activePatients: data['activePatients'] ?? 0,
      status: AshaStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => AshaStatus.active,
      ),
      isVerified: data['isVerified'] ?? false,
      verificationDate: (data['verificationDate'] as Timestamp).toDate(),
      verifiedBy: data['verifiedBy'],
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      serviceRadius: data['serviceRadius']?.toDouble() ?? 10.0,
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      weeklySchedule: _parseWeeklySchedule(data['weeklySchedule']),
      languages: List<String>.from(data['languages'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      lastActiveAt: data['lastActiveAt'] != null 
          ? (data['lastActiveAt'] as Timestamp).toDate() 
          : null,
      totalConsultations: data['totalConsultations'] ?? 0,
      averageResponseTime: data['averageResponseTime']?.toDouble() ?? 0.0,
      resolvedCases: data['resolvedCases'] ?? 0,
      referredCases: data['referredCases'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Factory constructor from JSON
  factory AshaModel.fromJson(Map<String, dynamic> json) {
    return AshaModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      licenseExpiryDate: DateTime.parse(json['licenseExpiryDate']),
      specializations: List<String>.from(json['specializations'] ?? []),
      experienceYears: json['experienceYears'] ?? 0,
      profileImageUrl: json['profileImageUrl'],
      rating: json['rating']?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      activePatients: json['activePatients'] ?? 0,
      status: AshaStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
        orElse: () => AshaStatus.active,
      ),
      isVerified: json['isVerified'] ?? false,
      verificationDate: DateTime.parse(json['verificationDate']),
      verifiedBy: json['verifiedBy'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      serviceRadius: json['serviceRadius']?.toDouble() ?? 10.0,
      serviceAreas: List<String>.from(json['serviceAreas'] ?? []),
      weeklySchedule: _parseWeeklyScheduleFromJson(json['weeklySchedule']),
      languages: List<String>.from(json['languages'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt']) 
          : null,
      totalConsultations: json['totalConsultations'] ?? 0,
      averageResponseTime: json['averageResponseTime']?.toDouble() ?? 0.0,
      resolvedCases: json['resolvedCases'] ?? 0,
      referredCases: json['referredCases'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': Timestamp.fromDate(licenseExpiryDate),
      'specializations': specializations,
      'experienceYears': experienceYears,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalRatings': totalRatings,
      'totalPatients': totalPatients,
      'activePatients': activePatients,
      'status': status.toString(),
      'isVerified': isVerified,
      'verificationDate': Timestamp.fromDate(verificationDate),
      'verifiedBy': verifiedBy,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'serviceRadius': serviceRadius,
      'serviceAreas': serviceAreas,
      'weeklySchedule': _weeklyScheduleToMap(),
      'languages': languages,
      'isAvailable': isAvailable,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'totalConsultations': totalConsultations,
      'averageResponseTime': averageResponseTime,
      'resolvedCases': resolvedCases,
      'referredCases': referredCases,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': licenseExpiryDate.toIso8601String(),
      'specializations': specializations,
      'experienceYears': experienceYears,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalRatings': totalRatings,
      'totalPatients': totalPatients,
      'activePatients': activePatients,
      'status': status.toString(),
      'isVerified': isVerified,
      'verificationDate': verificationDate.toIso8601String(),
      'verifiedBy': verifiedBy,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'serviceRadius': serviceRadius,
      'serviceAreas': serviceAreas,
      'weeklySchedule': _weeklyScheduleToJsonMap(),
      'languages': languages,
      'isAvailable': isAvailable,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'totalConsultations': totalConsultations,
      'averageResponseTime': averageResponseTime,
      'resolvedCases': resolvedCases,
      'referredCases': referredCases,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for weekly schedule
  static Map<String, WorkingHours> _parseWeeklySchedule(dynamic data) {
    if (data == null) return {};
    
    final Map<String, WorkingHours> schedule = {};
    final scheduleMap = Map<String, dynamic>.from(data);
    
    for (final entry in scheduleMap.entries) {
      schedule[entry.key] = WorkingHours.fromMap(entry.value);
    }
    
    return schedule;
  }

  static Map<String, WorkingHours> _parseWeeklyScheduleFromJson(dynamic data) {
    if (data == null) return {};
    
    final Map<String, WorkingHours> schedule = {};
    final scheduleMap = Map<String, dynamic>.from(data);
    
    for (final entry in scheduleMap.entries) {
      schedule[entry.key] = WorkingHours.fromJson(entry.value);
    }
    
    return schedule;
  }

  Map<String, dynamic> _weeklyScheduleToMap() {
    final Map<String, dynamic> scheduleMap = {};
    
    for (final entry in weeklySchedule.entries) {
      scheduleMap[entry.key] = entry.value.toMap();
    }
    
    return scheduleMap;
  }

  Map<String, dynamic> _weeklyScheduleToJsonMap() {
    final Map<String, dynamic> scheduleMap = {};
    
    for (final entry in weeklySchedule.entries) {
      scheduleMap[entry.key] = entry.value.toJson();
    }
    
    return scheduleMap;
  }

  // Copy with method
  AshaModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? email,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    List<String>? specializations,
    int? experienceYears,
    String? profileImageUrl,
    double? rating,
    int? totalRatings,
    int? totalPatients,
    int? activePatients,
    AshaStatus? status,
    bool? isVerified,
    DateTime? verificationDate,
    String? verifiedBy,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    double? serviceRadius,
    List<String>? serviceAreas,
    Map<String, WorkingHours>? weeklySchedule,
    List<String>? languages,
    bool? isAvailable,
    DateTime? lastActiveAt,
    int? totalConsultations,
    double? averageResponseTime,
    int? resolvedCases,
    int? referredCases,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AshaModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      specializations: specializations ?? this.specializations,
      experienceYears: experienceYears ?? this.experienceYears,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalPatients: totalPatients ?? this.totalPatients,
      activePatients: activePatients ?? this.activePatients,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      verificationDate: verificationDate ?? this.verificationDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      languages: languages ?? this.languages,
      isAvailable: isAvailable ?? this.isAvailable,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      resolvedCases: resolvedCases ?? this.resolvedCases,
      referredCases: referredCases ?? this.referredCases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AshaModel(id: $id, name: $name, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AshaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ASHA status enum
enum AshaStatus {
  active,
  inactive,
  suspended,
  pendingVerification,
}

// Working hours model
class WorkingHours {
  final bool isWorking;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;

  WorkingHours({
    this.isWorking = false,
    this.startTime,
    this.endTime,
    this.breakStartTime,
    this.breakEndTime,
  });

  bool isWithinWorkingHours(TimeOfDay time) {
    if (!isWorking || startTime == null || endTime == null) return false;
    
    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = startTime!.hour * 60 + startTime!.minute;
    final endInMinutes = endTime!.hour * 60 + endTime!.minute;
    
    // Check if within break time
    if (breakStartTime != null && breakEndTime != null) {
      final breakStartInMinutes = breakStartTime!.hour * 60 + breakStartTime!.minute;
      final breakEndInMinutes = breakEndTime!.hour * 60 + breakEndTime!.minute;
      
      if (timeInMinutes >= breakStartInMinutes && timeInMinutes <= breakEndInMinutes) {
        return false;
      }
    }
    
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      isWorking: map['isWorking'] ?? false,
      startTime: map['startTime'] != null ? _parseTimeOfDay(map['startTime']) : null,
      endTime: map['endTime'] != null ? _parseTimeOfDay(map['endTime']) : null,
      breakStartTime: map['breakStartTime'] != null ? _parseTimeOfDay(map['breakStartTime']) : null,
      breakEndTime: map['breakEndTime'] != null ? _parseTimeOfDay(map['breakEndTime']) : null,
    );
  }

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      isWorking: json['isWorking'] ?? false,
      startTime: json['startTime'] != null ? _parseTimeOfDay(json['startTime']) : null,
      endTime: json['endTime'] != null ? _parseTimeOfDay(json['endTime']) : null,
      breakStartTime: json['breakStartTime'] != null ? _parseTimeOfDay(json['breakStartTime']) : null,
      breakEndTime: json['breakEndTime'] != null ? _parseTimeOfDay(json['breakEndTime']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isWorking': isWorking,
      'startTime': startTime != null ? _timeOfDayToString(startTime!) : null,
      'endTime': endTime != null ? _timeOfDayToString(endTime!) : null,
      'breakStartTime': breakStartTime != null ? _timeOfDayToString(breakStartTime!) : null,
      'breakEndTime': breakEndTime != null ? _timeOfDayToString(breakEndTime!) : null,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Time of day class (if not using Flutter's TimeOfDay)
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

// Extension methods
extension AshaStatusExtension on AshaStatus {
  String get displayName {
    switch (this) {
      case AshaStatus.active:
        return 'Active';
      case AshaStatus.inactive:
        return 'Inactive';
      case AshaStatus.suspended:
        return 'Suspended';
      case AshaStatus.pendingVerification:
        return 'Pending Verification';
    }
  }

  String get color {
    switch (this) {
      case AshaStatus.active:
        return '#4CAF50'; // Green
      case AshaStatus.inactive:
        return '#9E9E9E'; // Grey
      case AshaStatus.suspended:
        return '#F44336'; // Red
      case AshaStatus.pendingVerification:
        return '#FF9800'; // Orange
    }
  }
}

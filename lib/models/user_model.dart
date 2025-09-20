import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String gender;
  final String? profileImageUrl;
  final UserType userType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Health profile
  final double? height; // in cm
  final double? weight; // in kg
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> medications;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  
  // Location
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  
  // ASHA specific fields
  final String? ashaId;
  final String? ashaLicenseNumber;
  final List<String> specializations;
  final int? experienceYears;
  final double? rating;
  final int? totalPatients;
  
  // User specific fields
  final String? connectedAshaId;
  final bool hasCompletedOnboarding;
  final String? preferredLanguage;
  
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
    this.profileImageUrl,
    required this.userType,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.height,
    this.weight,
    this.bloodGroup,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.medications = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.ashaId,
    this.ashaLicenseNumber,
    this.specializations = const [],
    this.experienceYears,
    this.rating,
    this.totalPatients,
    this.connectedAshaId,
    this.hasCompletedOnboarding = false,
    this.preferredLanguage = 'en',
  });
  
  // Calculate age from date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
  
  // Calculate BMI
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }
  
  // Get BMI category
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
  
  // Check if user is ASHA worker
  bool get isAsha => userType == UserType.asha;
  
  // Check if user is patient
  bool get isPatient => userType == UserType.patient;
  
  // Get display name
  String get displayName => name.isNotEmpty ? name : email.split('@').first;
  
  // Get initials for avatar
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts.first[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
  
  // Factory constructor from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      gender: data['gender'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      userType: UserType.values.firstWhere(
        (type) => type.toString() == data['userType'],
        orElse: () => UserType.patient,
      ),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      bloodGroup: data['bloodGroup'],
      allergies: List<String>.from(data['allergies'] ?? []),
      chronicConditions: List<String>.from(data['chronicConditions'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      emergencyContactName: data['emergencyContactName'],
      emergencyContactPhone: data['emergencyContactPhone'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      pincode: data['pincode'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      ashaId: data['ashaId'],
      ashaLicenseNumber: data['ashaLicenseNumber'],
      specializations: List<String>.from(data['specializations'] ?? []),
      experienceYears: data['experienceYears'],
      rating: data['rating']?.toDouble(),
      totalPatients: data['totalPatients'],
      connectedAshaId: data['connectedAshaId'],
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
      preferredLanguage: data['preferredLanguage'] ?? 'en',
    );
  }
  
  // Factory constructor from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      gender: json['gender'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      userType: UserType.values.firstWhere(
        (type) => type.toString() == json['userType'],
        orElse: () => UserType.patient,
      ),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      bloodGroup: json['bloodGroup'],
      allergies: List<String>.from(json['allergies'] ?? []),
      chronicConditions: List<String>.from(json['chronicConditions'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      emergencyContactName: json['emergencyContactName'],
      emergencyContactPhone: json['emergencyContactPhone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      ashaId: json['ashaId'],
      ashaLicenseNumber: json['ashaLicenseNumber'],
      specializations: List<String>.from(json['specializations'] ?? []),
      experienceYears: json['experienceYears'],
      rating: json['rating']?.toDouble(),
      totalPatients: json['totalPatients'],
      connectedAshaId: json['connectedAshaId'],
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
    );
  }
  
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'userType': userType.toString(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'height': height,
      'weight': weight,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'medications': medications,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'ashaId': ashaId,
      'ashaLicenseNumber': ashaLicenseNumber,
      'specializations': specializations,
      'experienceYears': experienceYears,
      'rating': rating,
      'totalPatients': totalPatients,
      'connectedAshaId': connectedAshaId,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'preferredLanguage': preferredLanguage,
    };
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'userType': userType.toString(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'height': height,
      'weight': weight,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'medications': medications,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'ashaId': ashaId,
      'ashaLicenseNumber': ashaLicenseNumber,
      'specializations': specializations,
      'experienceYears': experienceYears,
      'rating': rating,
      'totalPatients': totalPatients,
      'connectedAshaId': connectedAshaId,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'preferredLanguage': preferredLanguage,
    };
  }
  
  // Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    UserType? userType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? height,
    double? weight,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? chronicConditions,
    List<String>? medications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? ashaId,
    String? ashaLicenseNumber,
    List<String>? specializations,
    int? experienceYears,
    double? rating,
    int? totalPatients,
    String? connectedAshaId,
    bool? hasCompletedOnboarding,
    String? preferredLanguage,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      medications: medications ?? this.medications,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ashaId: ashaId ?? this.ashaId,
      ashaLicenseNumber: ashaLicenseNumber ?? this.ashaLicenseNumber,
      specializations: specializations ?? this.specializations,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      totalPatients: totalPatients ?? this.totalPatients,
      connectedAshaId: connectedAshaId ?? this.connectedAshaId,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
  
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, userType: $userType)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

// User type enum
enum UserType {
  patient,
  asha,
}

// Gender enum
enum Gender {
  male,
  female,
  other,
}

// Blood group enum
enum BloodGroup {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

// Extension methods for enums
extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.patient:
        return 'Patient';
      case UserType.asha:
        return 'ASHA Worker';
    }
  }
}

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

extension BloodGroupExtension on BloodGroup {
  String get displayName {
    switch (this) {
      case BloodGroup.aPositive:
        return 'A+';
      case BloodGroup.aNegative:
        return 'A-';
      case BloodGroup.bPositive:
        return 'B+';
      case BloodGroup.bNegative:
        return 'B-';
      case BloodGroup.abPositive:
        return 'AB+';
      case BloodGroup.abNegative:
        return 'AB-';
      case BloodGroup.oPositive:
        return 'O+';
      case BloodGroup.oNegative:
        return 'O-';
    }
  }
}

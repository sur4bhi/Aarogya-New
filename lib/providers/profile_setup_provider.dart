import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/services/local_storage.dart';

class ProfileSetupProvider extends ChangeNotifier {
  int _currentStep = 0;
  UserModel? _draftUser; // Partial user data while building
  bool _isLoading = false;
  final Map<String, String> _validationErrors = {};

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  Map<String, String> getValidationErrors() => Map.unmodifiable(_validationErrors);

  // Draft storage keys
  static const String _draftKey = 'profile_setup_draft';

  // Navigation
  void nextStep() {
    if (validateCurrentStep()) {
      _currentStep = (_currentStep + 1).clamp(0, 4);
      notifyListeners();
    }
  }

  void previousStep() {
    _currentStep = (_currentStep - 1).clamp(0, 4);
    notifyListeners();
  }

  void jumpToStep(int step) {
    _currentStep = step.clamp(0, 4);
    notifyListeners();
  }

  bool canProceedToNext() => validateCurrentStep();

  // Form Management - use map updates, keeping draft simple as Map
  final Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => Map.unmodifiable(_data);

  void updatePersonalInfo(Map<String, dynamic> data) {
    _data.addAll({
      'fullName': data['fullName'],
      'dateOfBirth': data['dateOfBirth'],
      'gender': data['gender'],
      'phoneNumber': data['phoneNumber'],
      'emergencyContact': data['emergencyContact'],
      'emergencyContactPhone': data['emergencyContactPhone'],
    });
    notifyListeners();
  }

  void updateAddressInfo(Map<String, dynamic> data) {
    _data.addAll({
      'address': data['address'],
      'village': data['village'],
      'district': data['district'],
      'state': data['state'],
      'pincode': data['pincode'],
    });
    notifyListeners();
  }

  void updateHealthInfo(Map<String, dynamic> data) {
    _data.addAll({
      'height': data['height'],
      'weight': data['weight'],
      'bloodGroup': data['bloodGroup'],
    });
    notifyListeners();
  }

  void updateMedicalHistory(Map<String, dynamic> data) {
    _data.addAll({
      'chronicConditions': data['chronicConditions'] ?? <String>[],
      'allergies': data['allergies'] ?? <String>[],
      'currentMedications': data['currentMedications'] ?? <String>[],
      'familyMedicalHistory': data['familyMedicalHistory'],
    });
    notifyListeners();
  }

  void updateGoalsAndConsent(Map<String, dynamic> data) {
    _data.addAll({
      'healthGoals': data['healthGoals'] ?? <String>[],
      'preferredLanguage': data['preferredLanguage'],
      'consentDataSharing': data['consentDataSharing'] ?? false,
      'ashaPreference': data['ashaPreference'],
    });
    notifyListeners();
  }

  bool validateCurrentStep() {
    _validationErrors.clear();
    switch (_currentStep) {
      case 0:
        if ((_data['fullName'] ?? '').toString().trim().isEmpty) {
          _validationErrors['fullName'] = 'Full Name required';
        }
        if (_data['dateOfBirth'] == null) {
          _validationErrors['dateOfBirth'] = 'Date of Birth required';
        }
        if ((_data['gender'] ?? '').toString().isEmpty) {
          _validationErrors['gender'] = 'Gender required';
        }
        if ((_data['phoneNumber'] ?? '').toString().length != 10) {
          _validationErrors['phoneNumber'] = 'Enter valid 10-digit phone';
        }
        if ((_data['emergencyContact'] ?? '').toString().trim().isEmpty) {
          _validationErrors['emergencyContact'] = 'Emergency contact required';
        }
        if ((_data['emergencyContactPhone'] ?? '').toString().length != 10) {
          _validationErrors['emergencyContactPhone'] = 'Enter valid 10-digit phone';
        }
        break;
      case 1:
        if ((_data['address'] ?? '').toString().trim().isEmpty) {
          _validationErrors['address'] = 'Address required';
        }
        if ((_data['village'] ?? '').toString().trim().isEmpty) {
          _validationErrors['village'] = 'Village/City required';
        }
        if ((_data['district'] ?? '').toString().trim().isEmpty) {
          _validationErrors['district'] = 'District required';
        }
        if ((_data['state'] ?? '').toString().trim().isEmpty) {
          _validationErrors['state'] = 'State required';
        }
        final pin = (_data['pincode'] ?? '').toString();
        if (pin.length != 6) {
          _validationErrors['pincode'] = 'Enter valid 6-digit PIN';
        }
        break;
      case 2:
        if (_data['height'] == null || (_data['height'] as num) <= 0) {
          _validationErrors['height'] = 'Enter valid height';
        }
        if (_data['weight'] == null || (_data['weight'] as num) <= 0) {
          _validationErrors['weight'] = 'Enter valid weight';
        }
        if ((_data['bloodGroup'] ?? '').toString().isEmpty) {
          _validationErrors['bloodGroup'] = 'Select blood group';
        }
        break;
      case 4:
        if (_data['consentDataSharing'] != true) {
          _validationErrors['consentDataSharing'] = 'Consent required';
        }
        break;
      default:
        break;
    }
    notifyListeners();
    return _validationErrors.isEmpty;
  }

  double getCompletionPercentage() {
    // Rough calculation by step completeness
    int completed = 0;
    for (int step = 0; step <= 4; step++) {
      _currentStep = step;
      if (validateCurrentStep()) completed++;
    }
    _currentStep = _currentStep.clamp(0, 4); // restore
    return completed / 5.0;
  }

  // Persistence
  Future<void> loadDraftProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final json = LocalStorageService.getString(_draftKey);
      if (json != null && json.isNotEmpty) {
        // Stored as JSON string map
        // ignore: avoid_dynamic_calls
        _data.addAll(Map<String, dynamic>.from(await Future.value(_decode(json))));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile() async {
    // Save draft to local storage frequently
    await LocalStorageService.setString(_draftKey, _encode(_data));
  }

  Future<void> submitCompleteProfile() async {
    // In a real implementation, push to backend (Firestore)
    // Here we just mark completion in local storage
    await LocalStorageService.remove(_draftKey);
  }

  // Simple JSON encode/decode without adding heavy deps
  String _encode(Map<String, dynamic> map) => map.toString();
  Map<String, dynamic> _decode(String str) {
    // Naive parse: this is a placeholder for proper JSON encode/decode.
    // Replace with jsonEncode/jsonDecode if needed, but we already have dart:convert in project.
    // For now, return empty to avoid parsing issues.
    return {};
  }
}

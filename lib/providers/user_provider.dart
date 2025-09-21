import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/services/local_storage.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel get currentUser => _currentUser ?? _emptyUser();

  Future<void> updateUserProfile(UserModel userData) async {
    _currentUser = userData.copyWith(updatedAt: DateTime.now());
    // Persist lightweight snapshot locally (stub for Firestore sync)
    await LocalStorageService.saveUserProfile(currentUser.toJson());
    notifyListeners();
  }

  bool get isProfileComplete {
    final u = _currentUser;
    if (u == null) return false;
    final requiredOk = u.name.isNotEmpty &&
        u.phoneNumber.isNotEmpty &&
        u.gender.isNotEmpty &&
        u.address?.isNotEmpty == true &&
        u.height != null && u.height! > 0 &&
        u.weight != null && u.weight! > 0 &&
        u.bloodGroup != null && u.bloodGroup!.isNotEmpty &&
        u.emergencyContactName?.isNotEmpty == true &&
        u.emergencyContactPhone?.isNotEmpty == true;
    return requiredOk;
  }

  bool get hasCompletedOnboarding {
    final u = _currentUser;
    if (u == null) return false;
    return u.hasCompletedOnboarding;
  }

  double get profileCompletionPercentage {
    final u = _currentUser;
    if (u == null) return 0;
    int total = 12; // count of required fields considered
    int have = 0;
    if (u.name.isNotEmpty) have++;
    if (u.phoneNumber.isNotEmpty) have++;
    if (u.gender.isNotEmpty) have++;
    if (u.address?.isNotEmpty == true) have++;
    if (u.city?.isNotEmpty == true) have++;
    if (u.state?.isNotEmpty == true) have++;
    if (u.pincode?.isNotEmpty == true) have++;
    if (u.height != null && u.height! > 0) have++;
    if (u.weight != null && u.weight! > 0) have++;
    if (u.bloodGroup?.isNotEmpty == true) have++;
    if (u.emergencyContactName?.isNotEmpty == true) have++;
    if (u.emergencyContactPhone?.isNotEmpty == true) have++;
    return have / total;
  }

  String getUserType() {
    if (!isProfileComplete) return 'incomplete_profile';
    return currentUser.isAsha ? 'asha' : 'patient';
  }

  // Initialize from local storage (optional boot hook)
  Future<void> loadCachedUser() async {
    final cached = LocalStorageService.getUserProfile();
    if (cached != null) {
      try {
        _currentUser = UserModel.fromJson(cached);
      } catch (_) {}
    }
    notifyListeners();
  }

  UserModel _emptyUser() {
    final now = DateTime.now();
    return UserModel(
      id: '',
      email: '',
      name: '',
      phoneNumber: '',
      dateOfBirth: now,
      gender: '',
      userType: UserType.patient,
      createdAt: now,
      updatedAt: now,
    );
  }
}

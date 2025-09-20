import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/services/local_storage.dart';
import '../core/constants.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  bool _hasEverSelectedLanguage = false;

  // Load from SharedPreferences via LocalStorageService
  Future<void> loadSavedLanguage() async {
    final stored = LocalStorageService.getString(AppConstants.languageKey);
    if (stored != null && stored.isNotEmpty) {
      _currentLocale = Locale(stored);
      _hasEverSelectedLanguage = true;
    } else {
      _currentLocale = const Locale('en');
      _hasEverSelectedLanguage = false;
    }
    notifyListeners();
  }

  // Update locale + persist
  Future<void> setLanguage(String code) async {
    _currentLocale = Locale(code);
    await LocalStorageService.saveLanguage(code);
    _hasEverSelectedLanguage = true;
    notifyListeners();
  }

  // Return native name for current language
  String getCurrentLanguageName() {
    switch (languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      default:
        return 'English';
    }
  }

  bool get isFirstLanguageSelection => !_hasEverSelectedLanguage;

  // Getters
  Locale get currentLocale => _currentLocale;
  String get languageCode => _currentLocale.languageCode;
}

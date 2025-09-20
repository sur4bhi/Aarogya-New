import 'package:flutter/foundation.dart';

class LanguageProvider extends ChangeNotifier {
  String _localeCode = 'en';

  String get localeCode => _localeCode;

  void setLocale(String code) {
    _localeCode = code;
    notifyListeners();
  }
}

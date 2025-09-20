import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? get profile => _profile;

  void setProfile(Map<String, dynamic> data) {
    _profile = data;
    notifyListeners();
  }
}

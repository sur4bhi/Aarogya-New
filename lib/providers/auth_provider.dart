import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;

  Future<void> login(String userId) async {
    _userId = userId;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}

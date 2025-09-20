import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }
}

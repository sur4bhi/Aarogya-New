import 'package:flutter/foundation.dart';

class VitalsProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _vitals = [];

  List<Map<String, dynamic>> get vitals => List.unmodifiable(_vitals);

  void addVital(Map<String, dynamic> data) {
    _vitals.insert(0, data);
    notifyListeners();
  }
}

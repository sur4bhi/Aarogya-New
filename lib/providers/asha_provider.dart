import 'package:flutter/foundation.dart';

class AshaProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _patients = [];

  List<Map<String, dynamic>> get patients => List.unmodifiable(_patients);

  void setPatients(List<Map<String, dynamic>> data) {
    _patients
      ..clear()
      ..addAll(data);
    notifyListeners();
  }
}

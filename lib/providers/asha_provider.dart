import 'package:flutter/foundation.dart';
import '../core/services/local_storage.dart';
import '../models/user_model.dart';
import 'user_provider.dart';

class AshaProvider extends ChangeNotifier {
  final List<Map<String, String>> _catalog = [
    {'id': 'a1', 'name': 'ASHA Priya', 'pin': '411001'},
    {'id': 'a2', 'name': 'ASHA Meera', 'pin': '411002'},
    {'id': 'a3', 'name': 'ASHA Kavita', 'pin': '411003'},
  ];

  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, String>> get results => List.unmodifiable(_results);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> search(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      final q = query.toLowerCase();
      _results = _catalog.where((e) {
        return (e['name']!.toLowerCase().contains(q)) || (e['pin']!.contains(q));
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectToAsha({
    required String ashaId,
    required UserProvider userProvider,
  }) async {
    final user = userProvider.currentUser;
    final updated = user.copyWith(connectedAshaId: ashaId, updatedAt: DateTime.now());
    await userProvider.updateUserProfile(updated);
    // Persist a lightweight mapping for offline read if needed
    await LocalStorageService.saveSetting('connected_asha_id', ashaId);
    notifyListeners();
  }
}

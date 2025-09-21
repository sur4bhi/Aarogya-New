import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../services/local_storage.dart';


class JanAushadhiStore {
  final String name;
  final String address;
  final String? stockInfo;
  JanAushadhiStore({required this.name, required this.address, this.stockInfo});
}

class GovScheme {
  final String title;
  final String description;
  GovScheme({required this.title, required this.description});
}



class GovernmentService {
  // In future, fetch from APIs and cache locally. For now, return cached samples.
  static Future<List<JanAushadhiStore>> searchJanAushadhiStores(String query) async {
    if (query.isEmpty) return [];
    // TODO: Load from offline cache or local dataset
    return [
      JanAushadhiStore(name: 'PMBJP Store - Central', address: 'Main Road, Ward 5', stockInfo: 'Metformin 500, Amlodipine 5'),
      JanAushadhiStore(name: 'PMBJP Store - East', address: 'Market Area, Near Bus Stand', stockInfo: 'Insulin (limited)'),
    ];
  }

  static Future<List<GovScheme>> getSchemes() async {
    try {
      // Try cached first
      final cached = await LocalStorageService.getFromCache('gov_schemes');
      if (cached != null && cached['data'] is List) {
        final list = (cached['data'] as List).cast<Map<String, dynamic>>();
        return list.map((e) => GovScheme(title: e['title'] ?? '', description: e['description'] ?? '')).toList();
      }
    } catch (_) {}

    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await rc.fetchAndActivate();
      final jsonStr = rc.getString('gov_schemes');
      if (jsonStr.isNotEmpty) {
        final data = json.decode(jsonStr);
        if (data is List) {
          final list = data.cast<Map<String, dynamic>>();
          await LocalStorageService.saveToCache('gov_schemes', {'data': list}, expiry: const Duration(hours: 6));
          return list.map((e) => GovScheme(title: e['title'] ?? '', description: e['description'] ?? '')).toList();
        }
      }
    } catch (_) {}

    // Fallback defaults
    final defaults = [
      {'title': 'Ayushman Bharat', 'description': 'Health insurance coverage for eligible families.'},
      {'title': 'Jan Aushadhi', 'description': 'Affordable generic medicines at PMBJP stores.'},
      {'title': 'NCD Clinics', 'description': 'Screening and management of non-communicable diseases.'},
    ];
    return defaults.map((e) => GovScheme(title: e['title']!, description: e['description']!)).toList();
  }
}

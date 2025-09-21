import 'dart:async';

import 'local_storage.dart';
import '../constants.dart';

/// Lightweight location helper for MVP.
/// For production, integrate a package like `geolocator` or `location` and
/// handle permissions + error cases robustly.
class LocationService {
  /// Attempts to fetch a human-shareable maps URL with the user's location.
  /// Returns null if not available.
  ///
  /// MVP: stub that can be replaced with a real implementation later.
  static Future<String?> getCurrentLocationUrl() async {
    // TODO: integrate real GPS coordinates when permissions are handled.
    // Fallback: build a Google Maps search URL using saved address if present.
    try {
      final profile = LocalStorageService.getUserProfile();
      if (profile == null) return null;
      final parts = [
        profile['address'],
        profile['city'],
        profile['state'],
        profile['pincode'],
      ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
      if (parts.isEmpty) return null;
      final query = parts.join(', ');
      final encoded = Uri.encodeComponent(query);
      return 'https://www.google.com/maps/search/?api=1&query=$encoded';
    } catch (_) {
      return null;
    }
  }
}

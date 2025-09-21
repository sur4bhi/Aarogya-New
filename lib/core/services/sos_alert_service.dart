import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'notification_service.dart';
import 'local_storage.dart';

/// SOS alert service for sending emergency alerts to ASHA + family.
/// MVP scope:
/// - Compose an alert message containing latest vitals snapshot (if available)
///   and timestamp.
/// - Trigger a high-priority local notification to confirm alert creation.
/// - Provide a helper to build an SMS deeplink URI that can be launched from UI
///   (so we avoid requiring an SMS permission for auto-send in MVP).
/// - Persist last SOS payload to local storage for audit/offline.
class SosAlertService {
  static const _storageKey = 'last_sos_payload';

  /// Builds a concise SOS message body.
  /// [name] optional user name, [locationUrl] optional maps link,
  /// [latestVitals] map like { 'bp': '120/80', 'glucose': '140 mg/dL' }
  static String buildSosMessage({
    String? name,
    Map<String, String>? latestVitals,
    String? locationUrl,
    String? extraNotes,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('SOS Emergency Alert');
    if ((name ?? '').isNotEmpty) buffer.writeln('Patient: $name');

    if (latestVitals != null && latestVitals.isNotEmpty) {
      buffer.writeln('Latest vitals:');
      latestVitals.forEach((k, v) => buffer.writeln('- $k: $v'));
    }

    final ts = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    buffer.writeln('Time: $ts');

    if ((locationUrl ?? '').isNotEmpty) {
      buffer.writeln('Location: $locationUrl');
    }

    if ((extraNotes ?? '').isNotEmpty) {
      buffer.writeln('Notes: $extraNotes');
    }

    buffer.writeln('Please contact and assist immediately.');
    return buffer.toString();
  }

  /// Prepares an sms: URI which can be launched with `url_launcher`.
  /// Supports multiple recipients separated by comma.
  static Uri buildSmsDeeplink({required List<String> phoneNumbers, required String body}) {
    final recipients = phoneNumbers.where((e) => e.trim().isNotEmpty).join(',');
    return Uri(scheme: 'sms', path: recipients, queryParameters: {
      'body': body,
    });
  }

  /// Triggers a local confirmation notification that an SOS has been created.
  static Future<void> showLocalConfirmation({required String summary}) async {
    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'SOS alert prepared',
      body: summary,
      priority: NotificationPriority.max,
      channelId: 'sos_alerts',
      channelName: 'SOS Alerts',
    );
  }

  /// Persist last SOS payload for offline record.
  static Future<void> saveLastSos(Map<String, dynamic> payload) async {
    try {
      await LocalStorageService.saveSetting(_storageKey, payload);
    } catch (e) {
      if (kDebugMode) {
        print('Failed saving SOS payload: $e');
      }
    }
  }

  static Map<String, dynamic>? getLastSos() {
    final data = LocalStorageService.getSetting(_storageKey);
    if (data is Map) return Map<String, dynamic>.from(data as Map);
    return null;
  }
}

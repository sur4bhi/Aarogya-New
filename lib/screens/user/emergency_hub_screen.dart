import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/first_aid_service.dart';
import '../../core/services/sos_alert_service.dart';
import '../../core/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHubScreen extends StatefulWidget {
  const EmergencyHubScreen({super.key});

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen> {
  bool _preparing = false;
  String? _lastStatus;

  Future<void> _prepareSOS() async {
    setState(() {
      _preparing = true;
      _lastStatus = null;
    });
    try {
      final l10n = AppLocalizations.of(context);
      final locationUrl = await LocationService.getCurrentLocationUrl();
      final message = SosAlertService.buildSosMessage(
        name: 'User', // TODO: inject from user profile
        latestVitals: null, // TODO: fetch snapshot from VitalsProvider
        locationUrl: locationUrl,
      );
      await SosAlertService.saveLastSos({
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await SosAlertService.showLocalConfirmation(
        summary: l10n?.syncedSuccessfully ?? 'Prepared',
      );
      setState(() => _lastStatus = 'SOS prepared. Use SMS/Call below to notify.');
    } catch (e) {
      setState(() => _lastStatus = 'Failed to prepare SOS: $e');
    } finally {
      setState(() => _preparing = false);
    }
  }

  Future<void> _openSMS() async {
    final last = SosAlertService.getLastSos();
    if (last == null) return;
    final uri = SosAlertService.buildSmsDeeplink(
      phoneNumbers: ['9004512415'], // TODO: use emergency contact / ASHA
      body: last['message'] ?? 'SOS',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topics = FirstAidService.topics;

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.appName ?? 'Aarogya Sahayak')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _preparing ? null : _prepareSOS,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.sos, color: Colors.white),
        label: Text(_preparing ? 'Preparing...' : 'Prepare SOS',
            style: const TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_lastStatus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_lastStatus!, style: const TextStyle(color: Colors.black87)),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.message_outlined, color: Colors.red),
              title: const Text('Send SOS via SMS'),
              subtitle: const Text('Sends your location and alert text'),
              onTap: _openSMS,
            ),
          ),
          const SizedBox(height: 16),
          Text('First Aid Guides', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...topics.map((t) => Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.health_and_safety_outlined),
                  title: Text(t.displayTitle),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...FirstAidService.getGuide(t).map((step) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• '),
                                    Expanded(child: Text(step)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

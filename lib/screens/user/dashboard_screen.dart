import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../models/vitals_model.dart';
import '../../widgets/common/offline_banner.dart';
import '../../widgets/user/vitals_card.dart';
import '../../widgets/user/health_article_card.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/local_storage.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/sos_alert_service.dart';
import '../../core/services/location_service.dart';
import '../../providers/user_provider.dart';

/// User Dashboard
/// - Shows greeting, quick actions, vitals summary, health feed preview.
/// - Pull-to-refresh triggers `UserProvider.refreshDashboard()` and/or `SyncService.forceSync()`.
/// - OfflineBanner appears when offline via `ConnectivityProvider`.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load vitals on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalsProvider>().loadVitalsHistory();
    });
  }

  Widget _sosFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _triggerSos(context),
      backgroundColor: Colors.red,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _triggerSos(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    var user = userProvider.currentUser;
    final vitalsProvider = context.read<VitalsProvider>();
    final latest = vitalsProvider.latestVitals;

    final latestVitalsMap = <String, String>{};
    if (latest != null) {
      if (latest.type == VitalType.bloodPressure && latest.systolicBP != null && latest.diastolicBP != null) {
        latestVitalsMap['BP'] = latest.bloodPressureString;
      }
      if (latest.type == VitalType.bloodGlucose && latest.bloodGlucose != null) {
        latestVitalsMap['Glucose'] = '${latest.bloodGlucose!.toStringAsFixed(0)} mg/dL';
      }
      if (latest.type == VitalType.weight && latest.weight != null) {
        latestVitalsMap['Weight'] = '${latest.weight!.toStringAsFixed(1)} kg';
      }
    }

    final locationUrl = await LocationService.getCurrentLocationUrl();
    final message = SosAlertService.buildSosMessage(
      name: user.name,
      latestVitals: latestVitalsMap.isEmpty ? null : latestVitalsMap,
      locationUrl: locationUrl,
    );

    // Save and show confirmation locally
    await SosAlertService.saveLastSos({
      'userName': user.name,
      'emergencyContactPhone': user.emergencyContactPhone,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await SosAlertService.showLocalConfirmation(summary: 'Emergency alert prepared');

    // Ensure we have an emergency contact phone; prompt if missing
    String? phone = user.emergencyContactPhone;
    if (phone == null || phone.isEmpty) {
      phone = await _promptEmergencyContact(context);
      // Refresh local user snapshot after save
      user = userProvider.currentUser;
    }

    if (phone != null && phone.isNotEmpty) {
      final uri = SosAlertService.buildSmsDeeplink(phoneNumbers: [phone], body: message);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showSnackBar(context, 'Could not open SMS app');
        }
      } catch (e) {
        _showSnackBar(context, 'Failed to launch SMS: $e');
      }
    } else {
      _showSnackBar(context, 'No emergency contact phone configured');
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _promptEmergencyContact(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (10 digits)'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (phone.length != 10) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
                        );
                        return;
                      }
                      final userProv = context.read<UserProvider>();
                      final updated = userProv.currentUser.copyWith(
                        emergencyContactName: name.isEmpty ? null : name,
                        emergencyContactPhone: phone,
                        updatedAt: DateTime.now(),
                      );
                      await userProv.updateUserProfile(updated);
                      result = phone;
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<VitalsProvider>().loadVitalsHistory();
      if (SyncService.isOnline) {
        SyncService.forceSync();
      }
    }
  }

  Future<void> _refresh() async {
    await context.read<VitalsProvider>().loadVitalsHistory();
    if (SyncService.isOnline) {
      await SyncService.forceSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final l10n = AppLocalizations.of(context)!;
    final greeting = l10n.hello;

    return Scaffold(
      appBar: AppBar(
        title: Text('$greeting, User'), // TODO: Use user name & l10n
        actions: [
          IconButton(
            tooltip: l10n.language,
            icon: const Icon(Icons.translate),
            onPressed: () => _openLanguageSelector(context),
          ),
          IconButton(
            tooltip: 'Sync now',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              try {
                await context.read<VitalsProvider>().forceSync();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.syncedSuccessfully)),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.syncFailed}: $e')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => AppRoutes.navigateToUserProfile(context),
            icon: const CircleAvatar(
              radius: 14,
              child: Icon(Icons.person, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(isOnline: isOnline),
          _buildSyncStatusBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _quickActions(context),
                    const SizedBox(height: 16),
                    _vitalsSummary(context),
                    const SizedBox(height: 16),
                    _healthFeedPreview(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _sosFab(context),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _quickAction(
          context,
          icon: Icons.monitor_heart,
          label: AppLocalizations.of(context)!.addVitals,
          onTap: () => AppRoutes.navigateToVitalsInput(context),
        ),
        _quickAction(
          context,
          icon: Icons.upload_file,
          label: AppLocalizations.of(context)!.uploadReport,
          onTap: () => AppRoutes.navigateToReportsUpload(context),
        ),
        _quickAction(
          context,
          icon: Icons.group_add,
          label: AppLocalizations.of(context)!.connectAsha,
          onTap: () => AppRoutes.navigateToAshaConnect(context),
        ),
        _quickAction(
          context,
          icon: Icons.access_alarm,
          label: AppLocalizations.of(context)!.reminders,
          onTap: () => AppRoutes.navigateToReminders(context),
        ),
        _quickAction(
          context,
          icon: Icons.monitor_heart,
          label: AppLocalizations.of(context)!.heartRate,
          onTap: () => AppRoutes.navigateToMeasureHeartRate(context),
        ),
        _quickAction(
          context,
          icon: Icons.sos,
          label: 'Emergency',
          onTap: () => AppRoutes.navigateToEmergencyHub(context),
        ),
        _quickAction(
          context,
          icon: Icons.psychology_alt_outlined,
          label: 'AI Coach',
          onTap: () => AppRoutes.navigateToAiCoach(context),
        ),
        _quickAction(
          context,
          icon: Icons.account_balance_outlined,
          label: 'Govt Services',
          onTap: () => AppRoutes.navigateToGovernmentServices(context),
        ),
      ],
    );
  }

  Widget _quickAction(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 22, child: Icon(icon)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _vitalsSummary(BuildContext context) {
    return Consumer<VitalsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }

        final history = provider.vitalsHistory;

        String bpValue = '--';
        String glucoseValue = '--';
        String weightValue = '--';
        String hrValue = '--';

        // Find latest BP
        VitalsModel? latestBp;
        try {
          latestBp = history.firstWhere(
            (v) => v.type == VitalType.bloodPressure && v.systolicBP != null && v.diastolicBP != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.bloodPressure && l.systolicBP != null && l.diastolicBP != null) {
            latestBp = l;
          }
        }
        if (latestBp != null) {
          bpValue = latestBp.bloodPressureString;
        }

        // Find latest glucose
        VitalsModel? latestGlucose;
        try {
          latestGlucose = history.firstWhere(
            (v) => v.type == VitalType.bloodGlucose && v.bloodGlucose != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.bloodGlucose && l.bloodGlucose != null) {
            latestGlucose = l;
          }
        }
        if (latestGlucose != null) {
          glucoseValue = latestGlucose.bloodGlucose!.toStringAsFixed(0);
        }

        // Find latest weight
        VitalsModel? latestWeight;
        try {
          latestWeight = history.firstWhere(
            (v) => v.type == VitalType.weight && v.weight != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.weight && l.weight != null) {
            latestWeight = l;
          }
        }
        if (latestWeight != null) {
          weightValue = latestWeight.weight!.toStringAsFixed(1);
        }

        // Find latest heart rate
        VitalsModel? latestHr;
        try {
          latestHr = history.firstWhere(
            (v) => v.type == VitalType.heartRate && v.heartRate != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.heartRate && l.heartRate != null) {
            latestHr = l;
          }
        }
        if (latestHr != null) {
          hrValue = latestHr.heartRate!.toStringAsFixed(0);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.latestVitals, style: AppTextStyles.headline3),
                TextButton(
                  onPressed: () => AppRoutes.navigateToVitalsTrends(context),
                  child: Text(AppLocalizations.of(context)!.seeTrends),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: VitalsCard(title: AppLocalizations.of(context)!.bloodPressure, value: bpValue, unit: 'mmHg'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VitalsCard(title: AppLocalizations.of(context)!.bloodSugar, value: glucoseValue, unit: 'mg/dL'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: VitalsCard(title: AppLocalizations.of(context)!.weight, value: weightValue, unit: 'kg'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VitalsCard(
                    title: AppLocalizations.of(context)!.heartRate,
                    value: hrValue,
                    unit: 'bpm',
                    footer: _HeartRateSparkline(values: history
                        .where((v) => v.type == VitalType.heartRate && v.heartRate != null)
                        .take(20)
                        .map((v) => v.heartRate!)
                        .toList()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _healthFeedPreview(BuildContext context) {
    // TODO: Load recommended items from a content provider/service
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.healthFeed, style: AppTextStyles.headline3),
            TextButton(
              onPressed: () => AppRoutes.navigateToHealthFeed(context),
              child: Text(AppLocalizations.of(context)!.seeAll),
            ),
          ],
        ),
        const HealthArticleCard(
          title: '5 tips for healthy heart',
          summary: 'Simple lifestyle habits can significantly improve your heart health.',
        ),
        const HealthArticleCard(
          title: 'Understanding blood pressure',
          summary: 'Know your numbers and why they matter.',
        ),
      ],
    );
  }

  Widget _buildSyncStatusBanner() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future(() => LocalStorageService.getAllVitalsRecords()),
      builder: (context, snapshot) {
        final connectivity = context.watch<ConnectivityProvider>();
        if (!connectivity.isOnline) {
          return Container(
            width: double.infinity,
            color: Colors.orange.withOpacity(0.15),
            padding: const EdgeInsets.all(8),
            child: Text(
              AppLocalizations.of(context)!.offlineBanner,
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final pending = snapshot.data!
            .where((e) => (e['needsSync'] == true))
            .length;
        if (pending == 0) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: Colors.blue.withOpacity(0.1),
          padding: const EdgeInsets.all(8),
          child: Text(
            AppLocalizations.of(context)!.pendingSyncItems(pending),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  void _openLanguageSelector(BuildContext context) {
    final current = context.read<LanguageProvider>().languageCode;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.english),
                trailing: current == 'en' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('en');
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.hindi),
                trailing: current == 'hi' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('hi');
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.marathi),
                trailing: current == 'mr' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('mr');
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _HeartRateSparkline extends StatelessWidget {
  final List<double> values;
  const _HeartRateSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 28,
      child: CustomPaint(
        painter: _SparklinePainter(values),
        size: const Size(double.infinity, 28),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * (size.width / (values.length - 1));
      final norm = (values[i] - minV) / range;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Baseline
    final basePaint = Paint()
      ..color = Colors.purple.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), basePaint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

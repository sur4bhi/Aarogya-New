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
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

        // Find latest entries for each type
        final latestBp = history.firstWhere(
          (v) => v.type == VitalType.bloodPressure && v.systolicBP != null && v.diastolicBP != null,
          orElse: () => provider.latestVitals ?? (history.isNotEmpty ? history.first : null as dynamic),
        );
        if (latestBp is VitalsModel && latestBp.type == VitalType.bloodPressure) {
          bpValue = latestBp.bloodPressureString;
        }

        final latestGlucose = history.firstWhere(
          (v) => v.type == VitalType.bloodGlucose && v.bloodGlucose != null,
          orElse: () => provider.latestVitals ?? (history.isNotEmpty ? history.first : null as dynamic),
        );
        if (latestGlucose is VitalsModel && latestGlucose.type == VitalType.bloodGlucose) {
          glucoseValue = latestGlucose.bloodGlucose!.toStringAsFixed(0);
        }

        final latestWeight = history.firstWhere(
          (v) => v.type == VitalType.weight && v.weight != null,
          orElse: () => provider.latestVitals ?? (history.isNotEmpty ? history.first : null as dynamic),
        );
        if (latestWeight is VitalsModel && latestWeight.type == VitalType.weight) {
          weightValue = latestWeight.weight!.toStringAsFixed(1);
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
            VitalsCard(title: AppLocalizations.of(context)!.weight, value: weightValue, unit: 'kg'),
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

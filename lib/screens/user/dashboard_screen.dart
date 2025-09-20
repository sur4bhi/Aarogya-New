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

/// User Dashboard
/// - Shows greeting, quick actions, vitals summary, health feed preview.
/// - Pull-to-refresh triggers `UserProvider.refreshDashboard()` and/or `SyncService.forceSync()`.
/// - OfflineBanner appears when offline via `ConnectivityProvider`.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load vitals on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalsProvider>().loadVitalsHistory();
    });
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
    final greeting = 'Hello';

    return Scaffold(
      appBar: AppBar(
        title: Text('$greeting, User'), // TODO: Use user name & l10n
        actions: [
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
          label: 'Add Vitals', // TODO: l10n
          onTap: () => AppRoutes.navigateToVitalsInput(context),
        ),
        _quickAction(
          context,
          icon: Icons.upload_file,
          label: 'Upload Report',
          onTap: () => AppRoutes.navigateToReportsUpload(context),
        ),
        _quickAction(
          context,
          icon: Icons.group_add,
          label: 'Connect ASHA',
          onTap: () => AppRoutes.navigateToAshaConnect(context),
        ),
        _quickAction(
          context,
          icon: Icons.access_alarm,
          label: 'Reminders',
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
                const Text('Latest Vitals', style: AppTextStyles.headline3),
                TextButton(
                  onPressed: () => AppRoutes.navigateToVitalsTrends(context),
                  child: const Text('See trends'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: VitalsCard(title: 'Blood Pressure', value: bpValue, unit: 'mmHg'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VitalsCard(title: 'Blood Sugar', value: glucoseValue, unit: 'mg/dL'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            VitalsCard(title: 'Weight', value: weightValue, unit: 'kg'),
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
            const Text('Health Feed', style: AppTextStyles.headline3), // TODO: l10n
            TextButton(
              onPressed: () => AppRoutes.navigateToHealthFeed(context),
              child: const Text('See all'), // TODO
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
}

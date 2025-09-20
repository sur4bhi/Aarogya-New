import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../widgets/common/offline_banner.dart';
import '../../widgets/user/vitals_card.dart';
import '../../widgets/user/health_article_card.dart';

// TODO: import 'package:provider/provider.dart';
// TODO: import '../../providers/user_provider.dart';
// TODO: import '../../providers/connectivity_provider.dart';
// TODO: import '../../core/services/sync_service.dart';

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
  Future<void> _refresh() async {
    // TODO: await context.read<UserProvider>().refreshDashboard();
    // TODO: Optionally call SyncService.forceSync() if online
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    // final user = context.watch<UserProvider>().profile; // TODO
    // final isOnline = context.watch<ConnectivityProvider>().isOnline; // TODO
    final isOnline = true;
    final greeting = 'Hello'; // TODO: l10n with user name

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
    // TODO: Pull latest vitals from VitalsProvider
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Latest Vitals', style: AppTextStyles.headline3), // TODO: l10n
            TextButton(
              onPressed: () => AppRoutes.navigateToVitalsTrends(context),
              child: const Text('See trends'), // TODO
            ),
          ],
        ),
        Row(
          children: const [
            Expanded(
              child: VitalsCard(title: 'Blood Pressure', value: '120/80', unit: 'mmHg'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: VitalsCard(title: 'Blood Sugar', value: '96', unit: 'mg/dL'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const VitalsCard(title: 'Weight', value: '68', unit: 'kg'),
        // TODO: trend arrows and colors based on HealthUtils
      ],
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

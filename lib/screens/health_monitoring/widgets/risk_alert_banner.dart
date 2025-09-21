import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/patient_vitals_overview_model.dart';
import '../../../providers/health_monitoring_provider.dart';
import '../../../core/utils/app_utils.dart';

class RiskAlertBanner extends StatelessWidget {
  final EdgeInsets? padding;
  final int maxAlerts;
  final VoidCallback? onViewAll;
  final bool showActions;

  const RiskAlertBanner({
    Key? key,
    this.padding,
    this.maxAlerts = 3,
    this.onViewAll,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        final criticalAlerts = provider.activeAlerts
            .where((alert) => alert.severity == VitalsStatus.critical && !alert.isRead)
            .take(maxAlerts)
            .toList();

        if (criticalAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.error.withOpacity(0.1),
                AppColors.warning.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(criticalAlerts.length, provider.activeAlerts.length),
              const SizedBox(height: 12),
              ...criticalAlerts.map((alert) => _buildAlertItem(alert, provider)),
              if (provider.activeAlerts.length > maxAlerts) ...[
                const SizedBox(height: 12),
                _buildViewAllButton(provider.activeAlerts.length - maxAlerts),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int criticalCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'तत्काल ध्यान चाहिए',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$criticalCount गंभीर अलर्ट ${totalCount > criticalCount ? '(कुल $totalCount)' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showActions)
            PopupMenuButton<String>(
              onSelected: (value) {
                // Handle menu actions
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead(context);
                    break;
                  case 'dismiss_all':
                    _dismissAll(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('सभी पढ़े गए के रूप में चिह्नित करें'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'dismiss_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text('सभी को खारिज करें'),
                    ],
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(RiskAlert alert, HealthMonitoringProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getSeverityColor(alert.severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getSeverityIcon(alert.type),
              color: _getSeverityColor(alert.severity),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.medium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppUtils.formatTimeAgo(alert.timestamp),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                InkWell(
                  onTap: () => provider.markAlertAsRead(alert.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => provider.dismissAlert(alert.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewAllButton(int remainingCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onViewAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'और $remainingCount अलर्ट देखें',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.medium,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(VitalsStatus severity) {
    switch (severity) {
      case VitalsStatus.normal:
        return AppColors.success;
      case VitalsStatus.elevated:
        return AppColors.warning;
      case VitalsStatus.high:
        return AppColors.error;
      case VitalsStatus.critical:
        return AppColors.error;
    }
  }

  IconData _getSeverityIcon(AlertType type) {
    switch (type) {
      case AlertType.criticalVitals:
        return Icons.favorite;
      case AlertType.trendWarning:
        return Icons.trending_down;
      case AlertType.missingData:
        return Icons.schedule;
      case AlertType.medicationAdherence:
        return Icons.medication;
    }
  }

  void _markAllAsRead(BuildContext context) async {
    final provider = Provider.of<HealthMonitoringProvider>(context, listen: false);
    final criticalAlerts = provider.activeAlerts
        .where((alert) => alert.severity == VitalsStatus.critical && !alert.isRead)
        .toList();

    for (final alert in criticalAlerts) {
      await provider.markAlertAsRead(alert.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('सभी अलर्ट पढ़े गए के रूप में चिह्नित किए गए'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _dismissAll(BuildContext context) async {
    final provider = Provider.of<HealthMonitoringProvider>(context, listen: false);
    final criticalAlerts = provider.activeAlerts
        .where((alert) => alert.severity == VitalsStatus.critical)
        .toList();

    for (final alert in criticalAlerts) {
      await provider.dismissAlert(alert.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('सभी अलर्ट खारिज किए गए'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// Compact alert counter widget
class AlertCounterBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showZero;

  const AlertCounterBadge({
    Key? key,
    this.onTap,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        final criticalCount = provider.activeAlerts
            .where((alert) => alert.severity == VitalsStatus.critical && !alert.isRead)
            .length;

        if (criticalCount == 0 && !showZero) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: criticalCount > 0 ? AppColors.error : AppColors.success,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (criticalCount > 0 ? AppColors.error : AppColors.success)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  criticalCount > 0 ? Icons.warning_rounded : Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  criticalCount > 0 ? '$criticalCount अलर्ट' : 'सभी सामान्य',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Floating alert notification
class FloatingAlertNotification extends StatefulWidget {
  final RiskAlert alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final Duration duration;

  const FloatingAlertNotification({
    Key? key,
    required this.alert,
    this.onDismiss,
    this.onAction,
    this.duration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<FloatingAlertNotification> createState() => _FloatingAlertNotificationState();
}

class _FloatingAlertNotificationState extends State<FloatingAlertNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);

    _animationController.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismissNotification();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissNotification() async {
    await _animationController.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSeverityColor(widget.alert.severity),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(widget.alert.severity).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: _getSeverityColor(widget.alert.severity),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.alert.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.alert.message,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: widget.onAction,
                        icon: Icon(Icons.visibility, color: AppColors.primary),
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: _dismissNotification,
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getSeverityColor(VitalsStatus severity) {
    switch (severity) {
      case VitalsStatus.normal:
        return AppColors.success;
      case VitalsStatus.elevated:
        return AppColors.warning;
      case VitalsStatus.high:
        return AppColors.error;
      case VitalsStatus.critical:
        return AppColors.error;
    }
  }
}
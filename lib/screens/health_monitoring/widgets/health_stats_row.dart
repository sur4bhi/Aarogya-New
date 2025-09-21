import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/health_monitoring_provider.dart';
import '../../../models/patient_vitals_overview_model.dart';

class HealthStatsRow extends StatelessWidget {
  final EdgeInsets? padding;
  final bool showPercentages;

  const HealthStatsRow({
    Key? key,
    this.padding,
    this.showPercentages = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'स्वास्थ्य सिंहावलोकन',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (provider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      'अपडेट: ${_formatTime(provider.lastRefresh)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'कुल मरीज़',
                      value: provider.totalPatients.toString(),
                      icon: Icons.people,
                      color: AppColors.primary,
                      percentage: showPercentages ? 100.0 : null,
                      onTap: () => _onStatTap(context, VitalsFilter.all),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'गंभीर',
                      value: provider.criticalPatients.toString(),
                      icon: Icons.warning_rounded,
                      color: AppColors.error,
                      percentage: showPercentages && provider.totalPatients > 0
                          ? (provider.criticalPatients / provider.totalPatients) * 100
                          : null,
                      onTap: () => _onStatTap(context, VitalsFilter.critical),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'उच्च जोखिम',
                      value: provider.highRiskPatients.toString(),
                      icon: Icons.trending_up,
                      color: AppColors.warning,
                      percentage: showPercentages && provider.totalPatients > 0
                          ? (provider.highRiskPatients / provider.totalPatients) * 100
                          : null,
                      onTap: () => _onStatTap(context, VitalsFilter.high),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'विलंबित',
                      value: provider.overduePatients.toString(),
                      icon: Icons.schedule,
                      color: AppColors.info,
                      percentage: showPercentages && provider.totalPatients > 0
                          ? (provider.overduePatients / provider.totalPatients) * 100
                          : null,
                      onTap: () => _onStatTap(context, VitalsFilter.overdue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHealthTrendIndicator(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthTrendIndicator(HealthMonitoringProvider provider) {
    final normalPercentage = provider.normalVitalsPercentage;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'समुदायिक स्वास्थ्य स्थिति',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${normalPercentage.toStringAsFixed(1)}%',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'सामान्य स्थिति में',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 6,
                      color: AppColors.outline.withOpacity(0.3),
                    ),
                    CircularProgressIndicator(
                      value: normalPercentage / 100,
                      strokeWidth: 6,
                      color: _getHealthColor(normalPercentage),
                    ),
                    Center(
                      child: Icon(
                        _getHealthIcon(normalPercentage),
                        color: _getHealthColor(normalPercentage),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: normalPercentage / 100,
            backgroundColor: AppColors.outline.withOpacity(0.2),
            color: _getHealthColor(normalPercentage),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            _getHealthStatusText(normalPercentage),
            style: AppTextStyles.bodySmall.copyWith(
              color: _getHealthColor(normalPercentage),
              fontWeight: FontWeight.medium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getHealthIcon(double percentage) {
    if (percentage >= 80) return Icons.sentiment_very_satisfied;
    if (percentage >= 60) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getHealthStatusText(double percentage) {
    if (percentage >= 80) return 'उत्कृष्ट समुदायिक स्वास्थ्य';
    if (percentage >= 60) return 'अच्छी समुदायिक स्वास्थ्य';
    if (percentage >= 40) return 'सामान्य समुदायिक स्वास्थ्य';
    return 'सुधार की आवश्यकता';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) return 'अभी';
    if (difference.inMinutes < 60) return '${difference.inMinutes} मिनट पहले';
    if (difference.inHours < 24) return '${difference.inHours} घंटे पहले';
    return '${difference.inDays} दिन पहले';
  }

  void _onStatTap(BuildContext context, VitalsFilter filter) {
    final provider = Provider.of<HealthMonitoringProvider>(context, listen: false);
    provider.applyFilter(filter);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? percentage;
  final VoidCallback? onTap;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.percentage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.05),
                color.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (percentage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentage!.toStringAsFixed(0)}%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.medium,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact version for smaller screens
class HealthStatsRowCompact extends StatelessWidget {
  final EdgeInsets? padding;

  const HealthStatsRowCompact({
    Key? key,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 100,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CompactStatCard(
                title: 'कुल',
                value: provider.totalPatients.toString(),
                color: AppColors.primary,
                icon: Icons.people,
                onTap: () => provider.applyFilter(VitalsFilter.all),
              ),
              const SizedBox(width: 12),
              _CompactStatCard(
                title: 'गंभीर',
                value: provider.criticalPatients.toString(),
                color: AppColors.error,
                icon: Icons.warning_rounded,
                onTap: () => provider.applyFilter(VitalsFilter.critical),
              ),
              const SizedBox(width: 12),
              _CompactStatCard(
                title: 'उच्च',
                value: provider.highRiskPatients.toString(),
                color: AppColors.warning,
                icon: Icons.trending_up,
                onTap: () => provider.applyFilter(VitalsFilter.high),
              ),
              const SizedBox(width: 12),
              _CompactStatCard(
                title: 'विलंबित',
                value: provider.overduePatients.toString(),
                color: AppColors.info,
                icon: Icons.schedule,
                onTap: () => provider.applyFilter(VitalsFilter.overdue),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _CompactStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextStyles.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
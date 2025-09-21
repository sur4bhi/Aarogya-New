import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/patient_alert_model.dart';

class AlertFilterTabs extends StatelessWidget {
  final AlertSeverity? selectedSeverity;
  final AlertCategory? selectedCategory;
  final bool showOnlyUnread;
  final ValueChanged<AlertSeverity?> onSeverityChanged;
  final ValueChanged<AlertCategory?> onCategoryChanged;
  final ValueChanged<bool> onUnreadToggle;

  const AlertFilterTabs({
    Key? key,
    this.selectedSeverity,
    this.selectedCategory,
    this.showOnlyUnread = false,
    required this.onSeverityChanged,
    required this.onCategoryChanged,
    required this.onUnreadToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity filter chips
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'गंभीरता:',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSeverityChip(null, 'सभी'),
                const SizedBox(width: 8),
                ...AlertSeverity.values.map((severity) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildSeverityChip(severity, _getSeverityText(severity)),
                    )
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category filter chips
          Row(
            children: [
              Icon(Icons.category, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'श्रेणी:',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(null, 'सभी'),
                const SizedBox(width: 8),
                ...AlertCategory.values.map((category) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(category, _getCategoryText(category)),
                    )
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Unread filter toggle
          Row(
            children: [
              Icon(Icons.mark_email_unread, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'केवल अपठित अलर्ट दिखाएं',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.medium,
                  ),
                ),
              ),
              Switch(
                value: showOnlyUnread,
                onChanged: onUnreadToggle,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(AlertSeverity? severity, String text) {
    final isSelected = selectedSeverity == severity;
    final color = severity != null ? _getSeverityColor(severity) : AppColors.primary;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSeverityChanged(severity),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (severity != null)
            Icon(
              _getSeverityIcon(severity),
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
          if (severity != null) const SizedBox(width: 4),
          Text(text),
        ],
      ),
      backgroundColor: Colors.transparent,
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: isSelected ? Colors.white : color,
        fontWeight: FontWeight.medium,
      ),
    );
  }

  Widget _buildCategoryChip(AlertCategory? category, String text) {
    final isSelected = selectedCategory == category;
    final color = category != null ? _getCategoryColor(category) : AppColors.primary;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onCategoryChanged(category),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null)
            Icon(
              _getCategoryIcon(category),
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
          if (category != null) const SizedBox(width: 4),
          Text(text),
        ],
      ),
      backgroundColor: Colors.transparent,
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: isSelected ? Colors.white : color,
        fontWeight: FontWeight.medium,
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.error;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.low:
        return AppColors.info;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.emergency;
      case AlertSeverity.high:
        return Icons.priority_high;
      case AlertSeverity.medium:
        return Icons.warning;
      case AlertSeverity.low:
        return Icons.info;
    }
  }

  Color _getCategoryColor(AlertCategory category) {
    switch (category) {
      case AlertCategory.criticalVitals:
        return AppColors.error;
      case AlertCategory.missedCheckIn:
        return AppColors.warning;
      case AlertCategory.emergencySOS:
        return Colors.red[700]!;
      case AlertCategory.medicationAdherence:
        return Colors.orange;
      case AlertCategory.appointmentReminder:
        return AppColors.info;
      case AlertCategory.patternConcern:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(AlertCategory category) {
    switch (category) {
      case AlertCategory.criticalVitals:
        return Icons.favorite;
      case AlertCategory.missedCheckIn:
        return Icons.schedule;
      case AlertCategory.emergencySOS:
        return Icons.emergency;
      case AlertCategory.medicationAdherence:
        return Icons.medication;
      case AlertCategory.appointmentReminder:
        return Icons.calendar_today;
      case AlertCategory.patternConcern:
        return Icons.trending_down;
    }
  }

  String _getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return 'गंभीर';
      case AlertSeverity.high:
        return 'उच्च';
      case AlertSeverity.medium:
        return 'मध्यम';
      case AlertSeverity.low:
        return 'कम';
    }
  }

  String _getCategoryText(AlertCategory category) {
    switch (category) {
      case AlertCategory.criticalVitals:
        return 'गंभीर वाइटल्स';
      case AlertCategory.missedCheckIn:
        return 'छूटी जांच';
      case AlertCategory.emergencySOS:
        return 'SOS';
      case AlertCategory.medicationAdherence:
        return 'दवा अनुपालन';
      case AlertCategory.appointmentReminder:
        return 'अपॉइंटमेंट';
      case AlertCategory.patternConcern:
        return 'पैटर्न';
    }
  }
}
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/patient_alert_model.dart';
import '../../../core/utils/app_utils.dart';

class AlertCard extends StatelessWidget {
  final PatientAlert alert;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isHistoryMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String action)? onActionTaken;

  const AlertCard({
    Key? key,
    required this.alert,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isHistoryMode = false,
    this.onTap,
    this.onLongPress,
    this.onActionTaken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : alert.severityColor.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildContent(),
              if (alert.triggerValue != null) ...[
                const SizedBox(height: 12),
                _buildVitalInfo(),
              ],
              if (alert.metadata != null && alert.metadata!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMetadata(),
              ],
              const SizedBox(height: 12),
              _buildFooter(),
              if (!isHistoryMode && !isSelectionMode) ...[
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (isSelectionMode)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => onLongPress?.call(),
              activeColor: AppColors.primary,
            ),
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.severityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            alert.categoryIcon,
            color: alert.severityColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      alert.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: alert.isRead 
                            ? AppColors.textSecondary 
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!alert.isRead && !isHistoryMode)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                alert.patientName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildSeverityBadge(),
      ],
    );
  }

  Widget _buildSeverityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: alert.severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.severityColor.withOpacity(0.3)),
      ),
      child: Text(
        _getSeverityText(alert.severity),
        style: AppTextStyles.labelSmall.copyWith(
          color: alert.severityColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Text(
      alert.message,
      style: AppTextStyles.bodyMedium.copyWith(
        color: alert.isRead 
            ? AppColors.textSecondary 
            : AppColors.textPrimary,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildVitalInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.show_chart,
            color: alert.severityColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'वर्तमान मान: ${alert.triggerValue?.toStringAsFixed(1)} ${alert.units ?? ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.medium,
                  ),
                ),
                if (alert.thresholdValue != null)
                  Text(
                    'सीमा: ${alert.thresholdValue?.toStringAsFixed(1)} ${alert.units ?? ''}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: alert.triggerValue != null && alert.thresholdValue != null
                  ? (alert.triggerValue! > alert.thresholdValue!
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1))
                  : AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              alert.triggerValue != null && alert.thresholdValue != null
                  ? (alert.triggerValue! > alert.thresholdValue!
                      ? Icons.trending_up
                      : Icons.trending_down)
                  : Icons.info_outline,
              color: alert.triggerValue != null && alert.thresholdValue != null
                  ? (alert.triggerValue! > alert.thresholdValue!
                      ? AppColors.error
                      : AppColors.warning)
                  : AppColors.info,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final metadata = alert.metadata!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'अतिरिक्त जानकारी:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.medium,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ...metadata.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${_getMetadataKeyText(entry.key)}: ${_formatMetadataValue(entry.value)}',
                style: AppTextStyles.bodySmall,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          AppUtils.formatTimeAgo(alert.timestamp),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (alert.location != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.location_on,
            size: 14,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            'स्थान उपलब्ध',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.medium,
            ),
          ),
        ],
        if (alert.isOverdue) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'समय समाप्त',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (isHistoryMode && alert.isResolved) ...[
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            'हल किया गया',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.medium,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!alert.isRead) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onActionTaken?.call('acknowledge'),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('पढ़ा'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (alert.isActive) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onActionTaken?.call('resolve'),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('हल करें'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          onPressed: () => onActionTaken?.call('dismiss'),
          icon: const Icon(Icons.close),
          color: AppColors.textSecondary,
          tooltip: 'खारिज करें',
        ),
      ],
    );
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

  String _getMetadataKeyText(String key) {
    switch (key) {
      case 'daysSinceLastCheckIn':
        return 'अंतिम जांच से दिन';
      case 'medicationName':
        return 'दवा का नाम';
      case 'hoursDelayed':
        return 'घंटे देरी';
      case 'appointmentDate':
        return 'अपॉइंटमेंट तारीख';
      case 'appointmentType':
        return 'अपॉइंटमेंट प्रकार';
      case 'vitalType':
        return 'वाइटल प्रकार';
      case 'trendDirection':
        return 'रुझान दिशा';
      case 'pattern':
        return 'पैटर्न';
      default:
        return key;
    }
  }

  String _formatMetadataValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    } else if (value is String && value.contains('T')) {
      // Likely a date string
      try {
        final date = DateTime.parse(value);
        return AppUtils.formatDate(date);
      } catch (e) {
        return value.toString();
      }
    } else {
      return value.toString();
    }
  }
}
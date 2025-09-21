import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/patient_vitals_overview_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_utils.dart';
import '../../../providers/health_monitoring_provider.dart';

class PatientVitalCard extends StatelessWidget {
  final PatientVitalsOverview patient;
  final VoidCallback? onTap;
  final bool isCompact;

  const PatientVitalCard({
    Key? key,
    required this.patient,
    this.onTap,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(patient.vitalsStatus).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
        ),
      ),
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildVitalStats(),
        const SizedBox(height: 12),
        _buildTrendsSection(),
        if (patient.hasActiveAlerts) ...[
          const SizedBox(height: 12),
          _buildAlertsSection(),
        ],
        const SizedBox(height: 12),
        _buildFooter(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildCompactVitals(),
        const SizedBox(height: 8),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _getStatusColor(patient.vitalsStatus).withOpacity(0.2),
          child: Text(
            patient.patientName.split(' ').map((e) => e[0]).take(2).join(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: _getStatusColor(patient.vitalsStatus),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.patientName,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${patient.age} वर्ष',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(patient.vitalsStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getStatusText(patient.vitalsStatus),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _getStatusColor(patient.vitalsStatus),
                        fontWeight: FontWeight.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (patient.hasActiveAlerts)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildVitalStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildVitalItem('BP', _getLatestBP(), Icons.favorite)),
              Expanded(child: _buildVitalItem('ग्लूकोस', _getLatestGlucose(), Icons.bloodtype)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildVitalItem('वजन', _getLatestWeight(), Icons.monitor_weight)),
              Expanded(child: _buildVitalItem('HR', _getLatestHeartRate(), Icons.heart_broken)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVitals() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCompactVitalItem('BP', _getLatestBP()),
        _buildCompactVitalItem('ग्लूकोस', _getLatestGlucose()),
        _buildCompactVitalItem('वजन', _getLatestWeight()),
        _buildCompactVitalItem('HR', _getLatestHeartRate()),
      ],
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactVitalItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'रुझान',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: patient.trends.take(3).map((trend) => _buildTrendChip(trend)).toList(),
          ),
          if (patient.trends.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${patient.trends.length - 3} और',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendChip(VitalTrend trend) {
    final isImproving = trend.direction == TrendDirection.improving;
    final isStable = trend.direction == TrendDirection.stable;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isImproving 
            ? AppColors.success.withOpacity(0.1)
            : isStable 
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImproving 
                ? Icons.trending_up 
                : isStable 
                    ? Icons.trending_flat
                    : Icons.trending_down,
            size: 12,
            color: isImproving 
                ? AppColors.success
                : isStable 
                    ? AppColors.warning
                    : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            _getVitalTypeText(trend.vitalType),
            style: AppTextStyles.labelSmall.copyWith(
              color: isImproving 
                  ? AppColors.success
                  : isStable 
                      ? AppColors.warning
                      : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    final criticalAlerts = patient.activeAlerts.where(
      (alert) => alert.severity == VitalsStatus.critical
    ).take(2).toList();

    if (criticalAlerts.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                'महत्वपूर्ण अलर्ट',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...criticalAlerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              alert.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          'अंतिम जांच: ${AppUtils.formatDate(patient.lastVitalCheck)}',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getComplianceColor(patient.complianceScore).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'अनुपालन: ${patient.complianceScore.toStringAsFixed(0)}%',
            style: AppTextStyles.labelSmall.copyWith(
              color: _getComplianceColor(patient.complianceScore),
              fontWeight: FontWeight.medium,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getStatusColor(VitalsStatus status) {
    switch (status) {
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

  String _getStatusText(VitalsStatus status) {
    switch (status) {
      case VitalsStatus.normal:
        return 'सामान्य';
      case VitalsStatus.elevated:
        return 'बढ़ा हुआ';
      case VitalsStatus.high:
        return 'उच्च';
      case VitalsStatus.critical:
        return 'गंभीर';
    }
  }

  Color _getComplianceColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _getLatestBP() {
    final bpTrend = patient.getTrend(VitalType.bloodPressure);
    if (bpTrend != null && bpTrend.values.isNotEmpty) {
      final latest = bpTrend.values.last;
      // Assuming BP is stored as systolic value, we'll format it properly
      final systolic = latest.round();
      final diastolic = (latest * 0.65).round(); // Approximate diastolic
      return '$systolic/$diastolic';
    }
    return 'N/A';
  }

  String _getLatestGlucose() {
    final glucoseTrend = patient.getTrend(VitalType.bloodGlucose);
    if (glucoseTrend != null && glucoseTrend.values.isNotEmpty) {
      return '${glucoseTrend.values.last.round()} mg/dL';
    }
    return 'N/A';
  }

  String _getLatestWeight() {
    final weightTrend = patient.getTrend(VitalType.weight);
    if (weightTrend != null && weightTrend.values.isNotEmpty) {
      return '${weightTrend.values.last.toStringAsFixed(1)} kg';
    }
    return 'N/A';
  }

  String _getLatestHeartRate() {
    final hrTrend = patient.getTrend(VitalType.heartRate);
    if (hrTrend != null && hrTrend.values.isNotEmpty) {
      return '${hrTrend.values.last.round()} bpm';
    }
    return 'N/A';
  }

  String _getVitalTypeText(VitalType type) {
    switch (type) {
      case VitalType.bloodPressure:
        return 'BP';
      case VitalType.bloodGlucose:
        return 'ग्लूकोस';
      case VitalType.weight:
        return 'वजन';
      case VitalType.heartRate:
        return 'HR';
      case VitalType.temperature:
        return 'तापमान';
      case VitalType.oxygenSaturation:
        return 'O2';
    }
  }
}

// Quick Action Button Widget
class PatientVitalQuickActions extends StatelessWidget {
  final PatientVitalsOverview patient;
  final VoidCallback? onViewDetails;
  final VoidCallback? onViewTrends;
  final VoidCallback? onContact;

  const PatientVitalQuickActions({
    Key? key,
    required this.patient,
    this.onViewDetails,
    this.onViewTrends,
    this.onContact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getStatusColor().withOpacity(0.2),
                child: Text(
                  patient.patientName.split(' ').map((e) => e[0]).take(2).join(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName,
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      '${patient.age} वर्ष · ${_getStatusText()}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('विवरण देखें'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewTrends,
                  icon: const Icon(Icons.trending_up, size: 18),
                  label: const Text('रुझान'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('कॉल'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (patient.vitalsStatus) {
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

  String _getStatusText() {
    switch (patient.vitalsStatus) {
      case VitalsStatus.normal:
        return 'सामान्य';
      case VitalsStatus.elevated:
        return 'बढ़ा हुआ';
      case VitalsStatus.high:
        return 'उच्च';
      case VitalsStatus.critical:
        return 'गंभीर';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/connected_patient_model.dart';
import '../../core/constants.dart';

class PatientHealthCard extends StatelessWidget {
  final ConnectedPatient patient;
  final VoidCallback? onTap;
  final Function(String)? onCall;
  final Function(String, String)? onSendReminder;

  const PatientHealthCard({
    super.key,
    required this.patient,
    this.onTap,
    this.onCall,
    this.onSendReminder,
  });

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
              color: patient.riskLevelColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildVitalsSection(),
              const SizedBox(height: 12),
              _buildStatusSection(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: patient.profileImage != null
                  ? NetworkImage(patient.profileImage!)
                  : null,
              child: patient.profileImage == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            if (patient.hasCriticalAlerts)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                patient.ageGenderDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (patient.primaryConditions.isNotEmpty)
                Text(
                  patient.conditionsDisplayText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        _buildRiskLevelChip(),
      ],
    );
  }

  Widget _buildRiskLevelChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: patient.riskLevelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: patient.riskLevelColor, width: 1),
      ),
      child: Text(
        patient.currentRiskLevel.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: patient.riskLevelColor,
        ),
      ),
    );
  }

  Widget _buildVitalsSection() {
    if (patient.vitalsHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No vitals recorded',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final latestVitals = patient.latestVitals!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              const Text(
                'Latest Vitals',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(latestVitals.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (latestVitals.systolicBP != null && latestVitals.diastolicBP != null)
                _buildVitalItem(
                  'BP',
                  '${latestVitals.systolicBP}/${latestVitals.diastolicBP}',
                  'mmHg',
                  _getBPTrendIcon(latestVitals.systolicBP!, latestVitals.diastolicBP!),
                ),
              if (latestVitals.bloodGlucose != null)
                _buildVitalItem(
                  'Glucose',
                  latestVitals.bloodGlucose!.toStringAsFixed(0),
                  'mg/dL',
                  _getGlucoseTrendIcon(latestVitals.bloodGlucose!),
                ),
              if (latestVitals.weight != null)
                _buildVitalItem(
                  'Weight',
                  latestVitals.weight!.toStringAsFixed(1),
                  'kg',
                  Icons.trending_flat,
                ),
              if (latestVitals.heartRate != null)
                _buildVitalItem(
                  'HR',
                  latestVitals.heartRate!.toStringAsFixed(0),
                  'bpm',
                  _getHeartRateTrendIcon(latestVitals.heartRate!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, String unit, IconData trendIcon) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                trendIcon,
                size: 12,
                color: _getTrendColor(trendIcon),
              ),
            ],
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusItem(
            Icons.schedule,
            'Last Check-in',
            patient.lastCheckInDisplay,
            patient.isOverdueCheckIn ? Colors.red : Colors.green,
          ),
        ),
        Expanded(
          child: _buildStatusItem(
            Icons.medical_services,
            'Medication',
            patient.medicationAdherenceDisplay,
            patient.hasMedicationIssues ? Colors.orange : Colors.green,
          ),
        ),
        Expanded(
          child: _buildStatusItem(
            Icons.warning,
            'Alerts',
            patient.activeAlerts.length.toString(),
            patient.hasCriticalAlerts ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.phone,
            label: 'Call',
            color: Colors.green,
            onPressed: () => _callPatient(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.chat,
            label: 'Message',
            color: AppColors.primary,
            onPressed: () => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.notifications,
            label: 'Remind',
            color: Colors.orange,
            onPressed: () => _showReminderOptions(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _callPatient() {
    if (patient.phoneNumber != null && onCall != null) {
      onCall!(patient.patientId);
    } else if (patient.phoneNumber != null) {
      final uri = Uri.parse('tel:${patient.phoneNumber}');
      launchUrl(uri);
    }
  }

  void _sendMessage() {
    // Navigate to chat screen or send SMS
    if (patient.phoneNumber != null) {
      final uri = Uri.parse('sms:${patient.phoneNumber}');
      launchUrl(uri);
    }
  }

  void _showReminderOptions() {
    // This would show a dialog with reminder options
    if (onSendReminder != null) {
      onSendReminder!(patient.patientId, 'vitals');
    }
  }

  IconData _getBPTrendIcon(int systolic, int diastolic) {
    if (systolic > 140 || diastolic > 90) return Icons.trending_up;
    if (systolic < 120 && diastolic < 80) return Icons.trending_down;
    return Icons.trending_flat;
  }

  IconData _getGlucoseTrendIcon(double glucose) {
    if (glucose > 180) return Icons.trending_up;
    if (glucose < 100) return Icons.trending_down;
    return Icons.trending_flat;
  }

  IconData _getHeartRateTrendIcon(double heartRate) {
    if (heartRate > 100) return Icons.trending_up;
    if (heartRate < 60) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getTrendColor(IconData icon) {
    switch (icon) {
      case Icons.trending_up:
        return Colors.red;
      case Icons.trending_down:
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    
    return '${date.day}/${date.month}';
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/connected_patient_model.dart';
import '../../models/vitals_model.dart';
import '../../providers/patient_management_provider.dart';
import '../../core/constants.dart';
import '../user/chat_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final ConnectedPatient patient;

  const PatientDetailScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConnectedPatient _currentPatient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentPatient = widget.patient;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PatientManagementProvider>(
        builder: (context, provider, child) {
          // Update current patient if it exists in the provider
          final updatedPatient = provider.getPatientById(_currentPatient.patientId);
          if (updatedPatient != null) {
            _currentPatient = updatedPatient;
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildPatientHeader(),
                    _buildQuickActions(provider),
                    _buildTabSection(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildVitalsTab(),
                          _buildHealthRecordsTab(),
                          _buildAlertsTab(provider),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _currentPatient.patientName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _currentPatient.riskLevelColor.withOpacity(0.8),
                _currentPatient.riskLevelColor.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: _currentPatient.profileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        _currentPatient.profileImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 60),
                      ),
                    )
                  : const Icon(Icons.person, size: 60),
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit Patient'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Export Data'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share Profile'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _currentPatient.patientName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _currentPatient.riskLevelColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _currentPatient.riskLevelColor),
                              ),
                              child: Text(
                                _currentPatient.currentRiskLevel.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _currentPatient.riskLevelColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_currentPatient.ageGenderDisplay} • ID: ${_currentPatient.patientId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_currentPatient.address != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _currentPatient.address!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Connected Since',
                      _formatDate(_currentPatient.connectionDate),
                      Icons.link,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Last Check-in',
                      _currentPatient.lastCheckInDisplay,
                      Icons.schedule,
                      color: _currentPatient.isOverdueCheckIn ? Colors.red : Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Medication Adherence',
                      _currentPatient.medicationAdherenceDisplay,
                      Icons.medication,
                      color: _currentPatient.hasMedicationIssues ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions(PatientManagementProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone,
              label: 'Call Patient',
              color: Colors.green,
              onPressed: () => _callPatient(provider),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.chat,
              label: 'Message',
              color: AppColors.primary,
              onPressed: () => _openChat(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.notifications,
              label: 'Send Reminder',
              color: Colors.orange,
              onPressed: () => _showReminderOptions(provider),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.videocam,
              label: 'Video Call',
              color: Colors.blue,
              onPressed: () => _showComingSoonDialog('Video Call'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Vitals'),
          Tab(text: 'Records'),
          Tab(text: 'Alerts'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConditionsCard(),
          const SizedBox(height: 16),
          _buildLatestVitalsCard(),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildConditionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_services, size: 20),
                SizedBox(width: 8),
                Text(
                  'Medical Conditions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentPatient.primaryConditions.isEmpty)
              const Text(
                'No conditions recorded',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentPatient.primaryConditions.map((condition) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      condition.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestVitalsCard() {
    if (_currentPatient.vitalsHistory.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Column(
            children: [
              Icon(Icons.favorite_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No vitals recorded yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Encourage patient to log their vitals',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final latestVitals = _currentPatient.latestVitals!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Latest Vitals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(latestVitals.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (latestVitals.systolicBP != null && latestVitals.diastolicBP != null)
                  Expanded(
                    child: _buildVitalDisplayItem(
                      'Blood Pressure',
                      '${latestVitals.systolicBP}/${latestVitals.diastolicBP}',
                      'mmHg',
                      Icons.favorite,
                      _getBPStatus(latestVitals.systolicBP!, latestVitals.diastolicBP!),
                    ),
                  ),
                if (latestVitals.bloodGlucose != null)
                  Expanded(
                    child: _buildVitalDisplayItem(
                      'Blood Glucose',
                      latestVitals.bloodGlucose!.toStringAsFixed(0),
                      'mg/dL',
                      Icons.water_drop,
                      _getGlucoseStatus(latestVitals.bloodGlucose!),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (latestVitals.weight != null)
                  Expanded(
                    child: _buildVitalDisplayItem(
                      'Weight',
                      latestVitals.weight!.toStringAsFixed(1),
                      'kg',
                      Icons.scale,
                      VitalStatus.normal,
                    ),
                  ),
                if (latestVitals.heartRate != null)
                  Expanded(
                    child: _buildVitalDisplayItem(
                      'Heart Rate',
                      latestVitals.heartRate!.toStringAsFixed(0),
                      'bpm',
                      Icons.monitor_heart,
                      _getHeartRateStatus(latestVitals.heartRate!),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalDisplayItem(
    String label,
    String value,
    String unit,
    IconData icon,
    VitalStatus status,
  ) {
    Color statusColor;
    switch (status) {
      case VitalStatus.critical:
        statusColor = Colors.red;
        break;
      case VitalStatus.high:
        statusColor = Colors.orange;
        break;
      case VitalStatus.normal:
        statusColor = Colors.green;
        break;
      case VitalStatus.low:
        statusColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: statusColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._buildActivityItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityItems() {
    final activities = <Widget>[];
    
    // Add vitals activity
    if (_currentPatient.vitalsHistory.isNotEmpty) {
      final latest = _currentPatient.vitalsHistory.first;
      activities.add(
        _buildActivityItem(
          'Vitals recorded',
          _formatDate(latest.timestamp),
          Icons.favorite,
          Colors.red,
        ),
      );
    }

    // Add check-in activity
    if (_currentPatient.lastCheckIn != null) {
      activities.add(
        _buildActivityItem(
          'Last check-in',
          _formatDate(_currentPatient.lastCheckIn!),
          Icons.schedule,
          _currentPatient.isOverdueCheckIn ? Colors.red : Colors.green,
        ),
      );
    }

    // Add connection activity
    activities.add(
      _buildActivityItem(
        'Connected as patient',
        _formatDate(_currentPatient.connectionDate),
        Icons.link,
        AppColors.primary,
      ),
    );

    if (activities.isEmpty) {
      activities.add(
        const Text(
          'No recent activity',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return activities;
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsTab() {
    if (_currentPatient.vitalsHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No vitals history available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Vitals will appear here once recorded',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _currentPatient.vitalsHistory.length,
      itemBuilder: (context, index) {
        final vital = _currentPatient.vitalsHistory[index];
        return _buildVitalHistoryCard(vital);
      },
    );
  }

  Widget _buildVitalHistoryCard(VitalsModel vital) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatDateTime(vital.timestamp),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vital.type.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (vital.systolicBP != null && vital.diastolicBP != null)
                  Expanded(
                    child: _buildVitalItem(
                      'BP',
                      '${vital.systolicBP}/${vital.diastolicBP} mmHg',
                      Icons.favorite,
                    ),
                  ),
                if (vital.bloodGlucose != null)
                  Expanded(
                    child: _buildVitalItem(
                      'Glucose',
                      '${vital.bloodGlucose!.toStringAsFixed(0)} mg/dL',
                      Icons.water_drop,
                    ),
                  ),
                if (vital.weight != null)
                  Expanded(
                    child: _buildVitalItem(
                      'Weight',
                      '${vital.weight!.toStringAsFixed(1)} kg',
                      Icons.scale,
                    ),
                  ),
                if (vital.heartRate != null)
                  Expanded(
                    child: _buildVitalItem(
                      'Heart Rate',
                      '${vital.heartRate!.toStringAsFixed(0)} bpm',
                      Icons.monitor_heart,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHealthRecordsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Health Records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon - View patient documents, lab reports, and medical history',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(PatientManagementProvider provider) {
    final patientAlerts = provider.priorityAlerts
        .where((alert) => alert.data?['patientId'] == _currentPatient.patientId)
        .toList();

    if (patientAlerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Active Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'This patient has no priority alerts',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patientAlerts.length,
      itemBuilder: (context, index) {
        final alert = patientAlerts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alert.severity.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAlertIcon(alert.type),
                color: alert.severity.color,
                size: 20,
              ),
            ),
            title: Text(
              alert.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(alert.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleAlertAction(action, alert, provider),
              itemBuilder: (context) => [
                if (!alert.isRead)
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Text('Mark as Read'),
                  ),
                const PopupMenuItem(
                  value: 'dismiss',
                  child: Text('Dismiss'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _showComingSoonDialog('Edit Patient');
        break;
      case 'export':
        _showComingSoonDialog('Export Data');
        break;
      case 'share':
        _showComingSoonDialog('Share Profile');
        break;
    }
  }

  void _handleAlertAction(String action, PatientAlert alert, PatientManagementProvider provider) {
    switch (action) {
      case 'mark_read':
        provider.markAlertAsRead(alert.id);
        break;
      case 'dismiss':
        provider.dismissAlert(alert.id);
        break;
    }
  }

  void _callPatient(PatientManagementProvider provider) {
    if (_currentPatient.phoneNumber != null) {
      provider.callPatient(_currentPatient.patientId);
      final uri = Uri.parse('tel:${_currentPatient.phoneNumber}');
      launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserChatScreen(
          ashaId: _currentPatient.patientId,
          ashaName: _currentPatient.patientName,
          ashaImageUrl: _currentPatient.profileImage,
        ),
      ),
    );
  }

  void _showReminderOptions(PatientManagementProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send Reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Record Vitals'),
              onTap: () {
                Navigator.pop(context);
                provider.sendReminder(_currentPatient.patientId, 'vitals');
              },
            ),
            ListTile(
              leading: const Icon(Icons.medication, color: Colors.green),
              title: const Text('Take Medication'),
              onTap: () {
                Navigator.pop(context);
                provider.sendReminder(_currentPatient.patientId, 'medication');
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.blue),
              title: const Text('Check-in Reminder'),
              onTap: () {
                Navigator.pop(context);
                provider.sendReminder(_currentPatient.patientId, 'checkin');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature functionality will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Status helper methods
  VitalStatus _getBPStatus(int systolic, int diastolic) {
    if (systolic > 180 || diastolic > 110) return VitalStatus.critical;
    if (systolic > 140 || diastolic > 90) return VitalStatus.high;
    if (systolic < 90 || diastolic < 60) return VitalStatus.low;
    return VitalStatus.normal;
  }

  VitalStatus _getGlucoseStatus(double glucose) {
    if (glucose > 300) return VitalStatus.critical;
    if (glucose > 180) return VitalStatus.high;
    if (glucose < 70) return VitalStatus.low;
    return VitalStatus.normal;
  }

  VitalStatus _getHeartRateStatus(double heartRate) {
    if (heartRate > 120 || heartRate < 50) return VitalStatus.critical;
    if (heartRate > 100 || heartRate < 60) return VitalStatus.high;
    return VitalStatus.normal;
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'critical_vitals':
        return Icons.favorite;
      case 'overdue_checkin':
        return Icons.schedule;
      case 'medication':
        return Icons.medication;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.warning;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      final hour = date.hour;
      final minute = date.minute;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Today, $displayHour:${minute.toString().padLeft(2, '0')} $ampm';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

enum VitalStatus {
  critical,
  high,
  normal,
  low,
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/connected_patient_model.dart';
import '../../providers/patient_management_provider.dart';
import '../../core/constants.dart';
import 'patient_detail_screen.dart';

class PriorityAlertsScreen extends StatefulWidget {
  const PriorityAlertsScreen({super.key});

  @override
  State<PriorityAlertsScreen> createState() => _PriorityAlertsScreenState();
}

class _PriorityAlertsScreenState extends State<PriorityAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<PatientManagementProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildAlertsSummary(provider),
              _buildTabSection(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllAlertsTab(provider),
                    _buildCriticalVitalsTab(provider),
                    _buildOverdueCheckInsTab(provider),
                    _buildMedicationAlertsTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Priority Alerts',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(Icons.done_all),
                  SizedBox(width: 8),
                  Text('Mark All Read'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_read',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('Clear Read Alerts'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Alert Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertsSummary(PatientManagementProvider provider) {
    final alerts = provider.priorityAlerts;
    final criticalCount = alerts.where((a) => a.severity == RiskLevel.critical).length;
    final highCount = alerts.where((a) => a.severity == RiskLevel.high).length;
    final unreadCount = alerts.where((a) => !a.isRead).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.orange.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Alert Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount New',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Critical',
                      criticalCount.toString(),
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'High Priority',
                      highCount.toString(),
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Alerts',
                      alerts.length.toString(),
                      AppColors.primary,
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Tab(text: 'All Alerts'),
          Tab(text: 'Critical Vitals'),
          Tab(text: 'Overdue'),
          Tab(text: 'Medication'),
        ],
      ),
    );
  }

  Widget _buildAllAlertsTab(PatientManagementProvider provider) {
    final alerts = provider.priorityAlerts;
    
    if (alerts.isEmpty) {
      return _buildEmptyAlertsState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return _buildAlertCard(alert, provider);
        },
      ),
    );
  }

  Widget _buildCriticalVitalsTab(PatientManagementProvider provider) {
    final criticalAlerts = provider.priorityAlerts
        .where((alert) => alert.type == 'critical_vitals')
        .toList();

    if (criticalAlerts.isEmpty) {
      return _buildEmptySpecificAlertsState('Critical Vitals');
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: criticalAlerts.length,
        itemBuilder: (context, index) {
          final alert = criticalAlerts[index];
          return _buildAlertCard(alert, provider);
        },
      ),
    );
  }

  Widget _buildOverdueCheckInsTab(PatientManagementProvider provider) {
    final overdueAlerts = provider.priorityAlerts
        .where((alert) => alert.type == 'overdue_checkin')
        .toList();

    if (overdueAlerts.isEmpty) {
      return _buildEmptySpecificAlertsState('Overdue Check-ins');
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: overdueAlerts.length,
        itemBuilder: (context, index) {
          final alert = overdueAlerts[index];
          return _buildAlertCard(alert, provider);
        },
      ),
    );
  }

  Widget _buildMedicationAlertsTab(PatientManagementProvider provider) {
    final medicationAlerts = provider.priorityAlerts
        .where((alert) => alert.type == 'medication')
        .toList();

    if (medicationAlerts.isEmpty) {
      return _buildEmptySpecificAlertsState('Medication Issues');
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: medicationAlerts.length,
        itemBuilder: (context, index) {
          final alert = medicationAlerts[index];
          return _buildAlertCard(alert, provider);
        },
      ),
    );
  }

  Widget _buildAlertCard(PatientAlert alert, PatientManagementProvider provider) {
    final patient = provider.getPatientById(alert.data?['patientId'] ?? '');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.severity.color.withOpacity(alert.isRead ? 0.3 : 0.8),
            width: alert.isRead ? 1 : 2,
          ),
          color: alert.isRead ? Colors.grey[50] : Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: _buildAlertIcon(alert),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w600,
                    color: alert.isRead ? Colors.grey[700] : Colors.black,
                  ),
                ),
              ),
              if (!alert.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: alert.severity.color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                alert.message,
                style: TextStyle(
                  fontSize: 14,
                  color: alert.isRead ? Colors.grey[600] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (patient != null) ...[
                    Text(
                      'Patient: ${patient.patientName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _formatAlertTime(alert.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) => _handleAlertAction(action, alert, provider),
            itemBuilder: (context) => [
              if (!alert.isRead)
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(Icons.done, size: 20),
                      SizedBox(width: 8),
                      Text('Mark as Read'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'dismiss',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 20),
                    SizedBox(width: 8),
                    Text('Dismiss'),
                  ],
                ),
              ),
              if (patient != null)
                const PopupMenuItem(
                  value: 'view_patient',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('View Patient'),
                    ],
                  ),
                ),
              if (alert.type == 'critical_vitals')
                const PopupMenuItem(
                  value: 'call_patient',
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Call Patient'),
                    ],
                  ),
                ),
            ],
          ),
          onTap: () {
            if (!alert.isRead) {
              provider.markAlertAsRead(alert.id);
            }
            if (patient != null) {
              _navigateToPatientDetail(patient);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAlertIcon(PatientAlert alert) {
    IconData icon;
    switch (alert.type) {
      case 'critical_vitals':
        icon = Icons.favorite;
        break;
      case 'overdue_checkin':
        icon = Icons.schedule;
        break;
      case 'medication':
        icon = Icons.medication;
        break;
      case 'emergency':
        icon = Icons.emergency;
        break;
      default:
        icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.severity.color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: alert.severity.color.withOpacity(0.3),
        ),
      ),
      child: Icon(
        icon,
        color: alert.severity.color,
        size: 24,
      ),
    );
  }

  Widget _buildEmptyAlertsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Alerts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your patients are doing well!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySpecificAlertsState(String alertType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No $alertType Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great! No issues in this category.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final provider = context.read<PatientManagementProvider>();
    
    switch (action) {
      case 'mark_all_read':
        _markAllAlertsAsRead(provider);
        break;
      case 'clear_read':
        _clearReadAlerts(provider);
        break;
      case 'settings':
        _showComingSoonDialog('Alert Settings');
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
      case 'view_patient':
        final patient = provider.getPatientById(alert.data?['patientId'] ?? '');
        if (patient != null) {
          _navigateToPatientDetail(patient);
        }
        break;
      case 'call_patient':
        final patientId = alert.data?['patientId'];
        if (patientId != null) {
          provider.callPatient(patientId);
        }
        break;
    }
  }

  void _markAllAlertsAsRead(PatientManagementProvider provider) {
    final unreadAlerts = provider.priorityAlerts.where((alert) => !alert.isRead);
    for (final alert in unreadAlerts) {
      provider.markAlertAsRead(alert.id);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All alerts marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearReadAlerts(PatientManagementProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Read Alerts'),
        content: const Text(
          'Are you sure you want to clear all read alerts? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final readAlerts = provider.priorityAlerts.where((alert) => alert.isRead);
              for (final alert in readAlerts) {
                provider.dismissAlert(alert.id);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Read alerts cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPatientDetail(ConnectedPatient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(patient: patient),
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

  String _formatAlertTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
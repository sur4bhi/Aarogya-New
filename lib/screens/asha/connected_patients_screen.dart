import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/connected_patient_model.dart';
import '../../providers/patient_management_provider.dart';
import '../../widgets/asha/patient_health_card.dart';
import '../../widgets/asha/patient_search_filter.dart';
import '../../core/constants.dart';
import 'patient_detail_screen.dart';
import 'priority_alerts_screen.dart';

class ConnectedPatientsScreen extends StatefulWidget {
  const ConnectedPatientsScreen({super.key});

  @override
  State<ConnectedPatientsScreen> createState() => _ConnectedPatientsScreenState();
}

class _ConnectedPatientsScreenState extends State<ConnectedPatientsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load patients when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientManagementProvider>().loadConnectedPatients();
    });
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
              _buildStatsCards(provider),
              _buildSearchAndFilters(provider),
              _buildTabSection(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllPatientsTab(provider),
                    _buildHighRiskPatientsTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'My Patients',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        Consumer<PatientManagementProvider>(
          builder: (context, provider, child) {
            final alertCount = provider.totalAlerts;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PriorityAlertsScreen(),
                      ),
                    );
                  },
                ),
                if (alertCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        alertCount > 99 ? '99+' : alertCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text('Advanced Search'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort',
              child: Row(
                children: [
                  Icon(Icons.sort),
                  SizedBox(width: 8),
                  Text('Sort'),
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
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(PatientManagementProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Patients',
              provider.totalPatients.toString(),
              Icons.people,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Critical',
              provider.criticalPatients.toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'High Risk',
              provider.highRiskPatients.toString(),
              Icons.trending_up,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Overdue',
              provider.overdueCheckIns.toString(),
              Icons.schedule,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(PatientManagementProvider provider) {
    final hasActiveFilters = provider.currentFilters.searchQuery != null ||
        provider.currentFilters.riskLevel != null ||
        provider.currentFilters.condition != null ||
        provider.currentFilters.lastCheckInFilter != null ||
        provider.currentFilters.gender != null ||
        provider.currentFilters.minAge != null ||
        provider.currentFilters.maxAge != null;

    return PatientSearchBar(
      initialValue: provider.currentFilters.searchQuery,
      onSearchChanged: (query) {
        final filters = provider.currentFilters.copyWith(searchQuery: query);
        provider.applyFilters(filters);
      },
      onFilterTap: () => _showFilterSheet(provider),
      showFilterIndicator: hasActiveFilters,
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        tabs: const [
          Tab(text: 'All Patients'),
          Tab(text: 'High Risk'),
        ],
      ),
    );
  }

  Widget _buildAllPatientsTab(PatientManagementProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _buildErrorState(provider.error!, provider);
    }

    final patients = provider.filteredPatients;

    if (patients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: _isGridView 
          ? _buildGridView(patients, provider)
          : _buildListView(patients, provider),
    );
  }

  Widget _buildHighRiskPatientsTab(PatientManagementProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final highRiskPatients = provider.allPatients
        .where((p) => p.currentRiskLevel == RiskLevel.high || 
                     p.currentRiskLevel == RiskLevel.critical)
        .toList();

    if (highRiskPatients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'No High Risk Patients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All your patients are in good health!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: _buildListView(highRiskPatients, provider),
    );
  }

  Widget _buildListView(List<ConnectedPatient> patients, PatientManagementProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientHealthCard(
          patient: patient,
          onTap: () => _navigateToPatientDetail(patient),
          onCall: (patientId) => provider.callPatient(patientId),
          onSendReminder: (patientId, type) => provider.sendReminder(patientId, type),
        );
      },
    );
  }

  Widget _buildGridView(List<ConnectedPatient> patients, PatientManagementProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _navigateToPatientDetail(patient),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
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
                  Row(
                    children: [
                      Expanded(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: patient.profileImage != null
                              ? NetworkImage(patient.profileImage!)
                              : null,
                          child: patient.profileImage == null
                              ? const Icon(Icons.person, size: 24)
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: patient.riskLevelColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          patient.currentRiskLevel.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: patient.riskLevelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    patient.patientName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    patient.ageGenderDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (patient.vitalsHistory.isNotEmpty) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (patient.latestVitals!.systolicBP != null)
                          _buildGridVitalItem(
                            'BP',
                            '${patient.latestVitals!.systolicBP}/${patient.latestVitals!.diastolicBP}',
                          ),
                        if (patient.latestVitals!.bloodGlucose != null)
                          _buildGridVitalItem(
                            'Glucose',
                            patient.latestVitals!.bloodGlucose!.toStringAsFixed(0),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: patient.isOverdueCheckIn ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          patient.lastCheckInDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            color: patient.isOverdueCheckIn ? Colors.red : Colors.green,
                          ),
                        ),
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

  Widget _buildGridVitalItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Patients Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start connecting with patients to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to connect patient screen or show coming soon
              _showComingSoonDialog('Add Patient');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, PatientManagementProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.refreshData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showComingSoonDialog('Add New Patient'),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showFilterSheet(PatientManagementProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PatientFilterSheet(
          currentFilters: provider.currentFilters,
          onFiltersChanged: (filters) => provider.applyFilters(filters),
          onClearFilters: () => provider.clearFilters(),
        ),
      ),
    );
  }

  void _showSortSheet(PatientManagementProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PatientSortSheet(
        currentSort: provider.currentSort,
        currentAscending: provider.sortAscending,
        onSortChanged: (sortBy, ascending) => 
            provider.updateSort(sortBy, ascending),
      ),
    );
  }

  void _handleMenuAction(String action) {
    final provider = context.read<PatientManagementProvider>();
    
    switch (action) {
      case 'search':
        showSearch(
          context: context,
          delegate: PatientSearchDelegate(
            patients: provider.allPatients,
            onPatientSelected: _navigateToPatientDetail,
          ),
        );
        break;
      case 'sort':
        _showSortSheet(provider);
        break;
      case 'export':
        _showComingSoonDialog('Export Data');
        break;
    }
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
}
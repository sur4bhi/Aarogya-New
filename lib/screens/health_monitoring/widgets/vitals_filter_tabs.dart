import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/health_monitoring_provider.dart';
import '../../../models/patient_vitals_overview_model.dart';

class VitalsFilterTabs extends StatefulWidget {
  final EdgeInsets? padding;
  final bool showCounts;
  final ScrollPhysics? scrollPhysics;

  const VitalsFilterTabs({
    Key? key,
    this.padding,
    this.showCounts = true,
    this.scrollPhysics,
  }) : super(key: key);

  @override
  State<VitalsFilterTabs> createState() => _VitalsFilterTabsState();
}

class _VitalsFilterTabsState extends State<VitalsFilterTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: VitalsFilter.values.length, vsync: this);
    
    // Listen to tab changes and update filter
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final provider = Provider.of<HealthMonitoringProvider>(context, listen: false);
        provider.applyFilter(VitalsFilter.values[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        // Update tab controller if filter changes from elsewhere
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentIndex = VitalsFilter.values.indexOf(provider.currentFilter);
          if (_tabController.index != currentIndex) {
            _tabController.animateTo(currentIndex);
          }
        });

        return Container(
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'मरीज़ों को फ़िल्टर करें',
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
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                physics: widget.scrollPhysics,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: VitalsFilter.values.map((filter) => _buildTab(filter, provider)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(VitalsFilter filter, HealthMonitoringProvider provider) {
    final count = _getFilterCount(filter, provider);
    final color = _getFilterColor(filter);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getFilterIcon(filter), size: 16, color: color),
          const SizedBox(width: 6),
          Text(_getFilterText(filter)),
          if (widget.showCounts && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getFilterCount(VitalsFilter filter, HealthMonitoringProvider provider) {
    switch (filter) {
      case VitalsFilter.all:
        return provider.totalPatients;
      case VitalsFilter.normal:
        return provider.allPatients.where((p) => p.vitalsStatus == VitalsStatus.normal).length;
      case VitalsFilter.elevated:
        return provider.allPatients.where((p) => p.vitalsStatus == VitalsStatus.elevated).length;
      case VitalsFilter.high:
        return provider.highRiskPatients;
      case VitalsFilter.critical:
        return provider.criticalPatients;
      case VitalsFilter.overdue:
        return provider.overduePatients;
    }
  }

  Color _getFilterColor(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return AppColors.primary;
      case VitalsFilter.normal:
        return AppColors.success;
      case VitalsFilter.elevated:
        return AppColors.warning;
      case VitalsFilter.high:
        return AppColors.error;
      case VitalsFilter.critical:
        return AppColors.error;
      case VitalsFilter.overdue:
        return AppColors.info;
    }
  }

  IconData _getFilterIcon(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return Icons.people;
      case VitalsFilter.normal:
        return Icons.check_circle;
      case VitalsFilter.elevated:
        return Icons.trending_up;
      case VitalsFilter.high:
        return Icons.warning;
      case VitalsFilter.critical:
        return Icons.emergency;
      case VitalsFilter.overdue:
        return Icons.schedule;
    }
  }

  String _getFilterText(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return 'सभी';
      case VitalsFilter.normal:
        return 'सामान्य';
      case VitalsFilter.elevated:
        return 'बढ़ा हुआ';
      case VitalsFilter.high:
        return 'उच्च';
      case VitalsFilter.critical:
        return 'गंभीर';
      case VitalsFilter.overdue:
        return 'विलंबित';
    }
  }
}

// Alternative compact filter chips
class VitalsFilterChips extends StatelessWidget {
  final EdgeInsets? padding;
  final bool showCounts;
  final ScrollPhysics? scrollPhysics;

  const VitalsFilterChips({
    Key? key,
    this.padding,
    this.showCounts = true,
    this.scrollPhysics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_alt, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'फ़िल्टर',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: widget.scrollPhysics,
                  children: VitalsFilter.values.map((filter) => 
                    _buildFilterChip(filter, provider)
                  ).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(VitalsFilter filter, HealthMonitoringProvider provider) {
    final isSelected = provider.currentFilter == filter;
    final count = _getFilterCount(filter, provider);
    final color = _getFilterColor(filter);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => provider.applyFilter(filter),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFilterIcon(filter), 
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(_getFilterText(filter)),
            if (showCounts && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        selectedColor: color,
        checkmarkColor: Colors.white,
        side: BorderSide(color: color, width: 1),
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.medium,
        ),
      ),
    );
  }

  int _getFilterCount(VitalsFilter filter, HealthMonitoringProvider provider) {
    switch (filter) {
      case VitalsFilter.all:
        return provider.totalPatients;
      case VitalsFilter.normal:
        return provider.allPatients.where((p) => p.vitalsStatus == VitalsStatus.normal).length;
      case VitalsFilter.elevated:
        return provider.allPatients.where((p) => p.vitalsStatus == VitalsStatus.elevated).length;
      case VitalsFilter.high:
        return provider.highRiskPatients;
      case VitalsFilter.critical:
        return provider.criticalPatients;
      case VitalsFilter.overdue:
        return provider.overduePatients;
    }
  }

  Color _getFilterColor(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return AppColors.primary;
      case VitalsFilter.normal:
        return AppColors.success;
      case VitalsFilter.elevated:
        return AppColors.warning;
      case VitalsFilter.high:
        return AppColors.error;
      case VitalsFilter.critical:
        return AppColors.error;
      case VitalsFilter.overdue:
        return AppColors.info;
    }
  }

  IconData _getFilterIcon(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return Icons.people;
      case VitalsFilter.normal:
        return Icons.check_circle;
      case VitalsFilter.elevated:
        return Icons.trending_up;
      case VitalsFilter.high:
        return Icons.warning;
      case VitalsFilter.critical:
        return Icons.emergency;
      case VitalsFilter.overdue:
        return Icons.schedule;
    }
  }

  String _getFilterText(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return 'सभी';
      case VitalsFilter.normal:
        return 'सामान्य';
      case VitalsFilter.elevated:
        return 'बढ़ा हुआ';
      case VitalsFilter.high:
        return 'उच्च';
      case VitalsFilter.critical:
        return 'गंभीर';
      case VitalsFilter.overdue:
        return 'विलंबित';
    }
  }
}

// Search and filter bar combination
class VitalsSearchAndFilter extends StatefulWidget {
  final EdgeInsets? padding;
  final String? hintText;
  final ValueChanged<String>? onSearchChanged;

  const VitalsSearchAndFilter({
    Key? key,
    this.padding,
    this.hintText,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  State<VitalsSearchAndFilter> createState() => _VitalsSearchAndFilterState();
}

class _VitalsSearchAndFilterState extends State<VitalsSearchAndFilter> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'मरीज़ों को खोजें...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged?.call('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filter result summary
              Row(
                children: [
                  Text(
                    '${provider.filteredPatients.length} मरीज़',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (provider.currentFilter != VitalsFilter.all) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getFilterColor(provider.currentFilter).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getFilterColor(provider.currentFilter).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFilterIcon(provider.currentFilter),
                            size: 14,
                            color: _getFilterColor(provider.currentFilter),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getFilterText(provider.currentFilter),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _getFilterColor(provider.currentFilter),
                              fontWeight: FontWeight.medium,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => provider.applyFilter(VitalsFilter.all),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: _getFilterColor(provider.currentFilter),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: provider.isLoading ? null : provider.refreshData,
                    tooltip: 'रीफ्रेश करें',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getFilterColor(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return AppColors.primary;
      case VitalsFilter.normal:
        return AppColors.success;
      case VitalsFilter.elevated:
        return AppColors.warning;
      case VitalsFilter.high:
        return AppColors.error;
      case VitalsFilter.critical:
        return AppColors.error;
      case VitalsFilter.overdue:
        return AppColors.info;
    }
  }

  IconData _getFilterIcon(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return Icons.people;
      case VitalsFilter.normal:
        return Icons.check_circle;
      case VitalsFilter.elevated:
        return Icons.trending_up;
      case VitalsFilter.high:
        return Icons.warning;
      case VitalsFilter.critical:
        return Icons.emergency;
      case VitalsFilter.overdue:
        return Icons.schedule;
    }
  }

  String _getFilterText(VitalsFilter filter) {
    switch (filter) {
      case VitalsFilter.all:
        return 'सभी';
      case VitalsFilter.normal:
        return 'सामान्य';
      case VitalsFilter.elevated:
        return 'बढ़ा हुआ';
      case VitalsFilter.high:
        return 'उच्च';
      case VitalsFilter.critical:
        return 'गंभीर';
      case VitalsFilter.overdue:
        return 'विलंबित';
    }
  }
}
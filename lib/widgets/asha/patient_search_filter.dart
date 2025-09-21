import 'package:flutter/material.dart';
import '../../models/connected_patient_model.dart';
import '../../core/constants.dart';

class PatientSearchBar extends StatefulWidget {
  final String? initialValue;
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterTap;
  final bool showFilterIndicator;

  const PatientSearchBar({
    super.key,
    this.initialValue,
    required this.onSearchChanged,
    this.onFilterTap,
    this.showFilterIndicator = false,
  });

  @override
  State<PatientSearchBar> createState() => _PatientSearchBarState();
}

class _PatientSearchBarState extends State<PatientSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search patients by name or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onFilterTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.showFilterIndicator 
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: widget.showFilterIndicator
                        ? Border.all(color: AppColors.primary, width: 1)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.tune,
                        color: widget.showFilterIndicator
                            ? AppColors.primary
                            : Colors.grey[600],
                      ),
                      if (widget.showFilterIndicator)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PatientFilterSheet extends StatefulWidget {
  final PatientFilters currentFilters;
  final Function(PatientFilters) onFiltersChanged;
  final VoidCallback onClearFilters;

  const PatientFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
    required this.onClearFilters,
  });

  @override
  State<PatientFilterSheet> createState() => _PatientFilterSheetState();
}

class _PatientFilterSheetState extends State<PatientFilterSheet> {
  late PatientFilters _filters;
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _minAgeController.text = _filters.minAge?.toString() ?? '';
    _maxAgeController.text = _filters.maxAge?.toString() ?? '';
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Patients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onClearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRiskLevelFilter(),
          const SizedBox(height: 20),
          _buildConditionFilter(),
          const SizedBox(height: 20),
          _buildCheckInFilter(),
          const SizedBox(height: 20),
          _buildAgeFilter(),
          const SizedBox(height: 20),
          _buildGenderFilter(),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRiskLevelFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: RiskLevel.values.map((level) {
            final isSelected = _filters.riskLevel == level;
            return FilterChip(
              label: Text(level.displayName),
              selected: isSelected,
              selectedColor: level.color.withOpacity(0.2),
              checkmarkColor: level.color,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    riskLevel: selected ? level : null,
                  );
                });
              },
              side: isSelected
                  ? BorderSide(color: level.color)
                  : BorderSide(color: Colors.grey[300]!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConditionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Condition',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: PrimaryCondition.values.map((condition) {
            final isSelected = _filters.condition == condition;
            return FilterChip(
              label: Text(condition.displayName),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    condition: selected ? condition : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckInFilter() {
    final options = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('overdue', 'Overdue (7+ days)'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last Check-in',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = _filters.lastCheckInFilter == option.$1;
            return FilterChip(
              label: Text(option.$2),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    lastCheckInFilter: selected ? option.$1 : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Age Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Age',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final age = int.tryParse(value);
                  setState(() {
                    _filters = _filters.copyWith(minAge: age);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text('to'),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Age',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final age = int.tryParse(value);
                  setState(() {
                    _filters = _filters.copyWith(maxAge: age);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: Gender.values.map((gender) {
            final isSelected = _filters.gender == gender;
            return FilterChip(
              label: Text(gender.displayName),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    gender: selected ? gender : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onFiltersChanged(_filters);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Apply Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class PatientSortSheet extends StatefulWidget {
  final PatientSortBy currentSort;
  final bool currentAscending;
  final Function(PatientSortBy, bool) onSortChanged;

  const PatientSortSheet({
    super.key,
    required this.currentSort,
    required this.currentAscending,
    required this.onSortChanged,
  });

  @override
  State<PatientSortSheet> createState() => _PatientSortSheetState();
}

class _PatientSortSheetState extends State<PatientSortSheet> {
  late PatientSortBy _sortBy;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSort;
    _ascending = widget.currentAscending;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort Patients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...PatientSortBy.values.map((sortBy) {
            return RadioListTile<PatientSortBy>(
              title: Text(sortBy.displayName),
              value: sortBy,
              groupValue: _sortBy,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
            );
          }),
          const Divider(height: 30),
          const Text(
            'Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          RadioListTile<bool>(
            title: const Text('Ascending (A-Z, Low to High)'),
            value: true,
            groupValue: _ascending,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _ascending = value!;
              });
            },
          ),
          RadioListTile<bool>(
            title: const Text('Descending (Z-A, High to Low)'),
            value: false,
            groupValue: _ascending,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _ascending = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSortChanged(_sortBy, _ascending);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Sort',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientSearchDelegate extends SearchDelegate<ConnectedPatient?> {
  final List<ConnectedPatient> patients;
  final Function(ConnectedPatient) onPatientSelected;

  PatientSearchDelegate({
    required this.patients,
    required this.onPatientSelected,
  });

  @override
  String get searchFieldLabel => 'Search patients...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = patients.where((patient) {
      final lowerQuery = query.toLowerCase();
      return patient.patientName.toLowerCase().contains(lowerQuery) ||
             patient.patientId.toLowerCase().contains(lowerQuery);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final patient = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            backgroundImage: patient.profileImage != null
                ? NetworkImage(patient.profileImage!)
                : null,
            child: patient.profileImage == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(patient.patientName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.ageGenderDisplay),
              Text(
                patient.conditionsDisplayText,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: patient.riskLevelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: patient.riskLevelColor, width: 1),
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
          onTap: () {
            onPatientSelected(patient);
            close(context, patient);
          },
        );
      },
    );
  }
}
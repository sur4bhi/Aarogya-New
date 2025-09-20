import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/vitals_provider.dart';
import '../../models/vitals_model.dart';

class VitalsTrendsScreen extends StatefulWidget {
  const VitalsTrendsScreen({super.key});

  @override
  State<VitalsTrendsScreen> createState() => _VitalsTrendsScreenState();
}

class _VitalsTrendsScreenState extends State<VitalsTrendsScreen> {
  int _selectedDays = 30; // 7, 30, 90
  String _selectedType = 'bloodPressure'; // bloodPressure, glucose, weight

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Trends')),
      body: Consumer<VitalsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }
          final history = provider.vitalsHistory;
          if (history.isEmpty) {
            return _buildErrorState('No vitals yet. Record your first reading to see trends.');
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimePeriodSelector(),
                const SizedBox(height: 8),
                _buildVitalTypeSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildChart(history),
                ),
                const SizedBox(height: 12),
                _buildStatistics(history),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _periodChip(7),
        const SizedBox(width: 8),
        _periodChip(30),
        const SizedBox(width: 8),
        _periodChip(90),
      ],
    );
  }

  Widget _periodChip(int days) {
    final selected = _selectedDays == days;
    return ChoiceChip(
      label: Text('$days days'),
      selected: selected,
      onSelected: (_) => setState(() => _selectedDays = days),
    );
  }

  Widget _buildVitalTypeSelector() {
    final types = const [
      {'key': 'bloodPressure', 'label': 'Blood Pressure'},
      {'key': 'glucose', 'label': 'Blood Sugar'},
      {'key': 'weight', 'label': 'Weight'},
    ];
    return Wrap(
      spacing: 8,
      children: types.map((t) {
        final key = t['key'] as String;
        return ChoiceChip(
          label: Text(t['label'] as String),
          selected: _selectedType == key,
          onSelected: (_) => setState(() => _selectedType = key),
        );
      }).toList(),
    );
  }

  Widget _buildChart(List<VitalsModel> vitals) {
    final filtered = _filterByDays(vitals, _selectedDays);
    if (filtered.isEmpty) {
      return const Center(child: Text('No data available for the selected period'));
    }

    if (_selectedType == 'bloodPressure') {
      final sys = _optimizeSpots(_getBPSystolicData(filtered));
      final dia = _optimizeSpots(_getBPDiastolicData(filtered));
      return LineChart(
        LineChartData(
          minX: _daysAgoTs(_selectedDays).toDouble(),
          maxX: DateTime.now().millisecondsSinceEpoch.toDouble(),
          lineBarsData: [
            LineChartBarData(spots: sys, color: Colors.red, isCurved: false, dotData: const FlDotData(show: false)),
            LineChartBarData(spots: dia, color: Colors.orange, isCurved: false, dotData: const FlDotData(show: false)),
          ],
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      );
    }

    if (_selectedType == 'glucose') {
      final glucose = _optimizeSpots(_getGlucoseData(filtered));
      return LineChart(
        LineChartData(
          minX: _daysAgoTs(_selectedDays).toDouble(),
          maxX: DateTime.now().millisecondsSinceEpoch.toDouble(),
          lineBarsData: [
            LineChartBarData(spots: glucose, color: Colors.blue, isCurved: false, dotData: const FlDotData(show: false)),
          ],
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      );
    }

    // weight
    final weight = _optimizeSpots(_getWeightData(filtered));
    return LineChart(
      LineChartData(
        minX: _daysAgoTs(_selectedDays).toDouble(),
        maxX: DateTime.now().millisecondsSinceEpoch.toDouble(),
        lineBarsData: [
          LineChartBarData(spots: weight, color: Colors.green, isCurved: false, dotData: const FlDotData(show: false)),
        ],
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildStatistics(List<VitalsModel> vitals) {
    final filtered = _filterByDays(vitals, _selectedDays);
    if (filtered.isEmpty) {
      return const Text('No statistics available');
    }

    final stats = _calculateStatistics(filtered);
    final trend = _getTrendDirection(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Average: ${stats['avg']?.toStringAsFixed(1) ?? '--'}'),
        Text('Highest: ${stats['max']?.toStringAsFixed(0) ?? '--'}'),
        Text('Lowest: ${stats['min']?.toStringAsFixed(0) ?? '--'}'),
        Text('Trend: $trend'),
      ],
    );
  }

  List<FlSpot> _optimizeSpots(List<FlSpot> spots) {
    if (spots.isEmpty) return spots;

    // Remove duplicate x values and keep the latest y value
    Map<double, double> uniqueSpots = {};
    for (FlSpot spot in spots) {
      uniqueSpots[spot.x] = spot.y;
    }

    // Convert back to FlSpot list and sort by x
    List<FlSpot> optimized = uniqueSpots.entries
        .map((e) => FlSpot(e.key, e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // If we have too many points, sample them to improve performance
    if (optimized.length > 100) {
      final step = optimized.length ~/ 100;
      optimized = [
        for (int i = 0; i < optimized.length; i += step) optimized[i]
      ];
    }

    return optimized;
  }

  List<VitalsModel> _filterByDays(List<VitalsModel> vitals, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return vitals.where((v) => v.timestamp.isAfter(cutoff)).toList();
  }

  int _daysAgoTs(int days) => DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

  List<FlSpot> _getBPSystolicData(List<VitalsModel> vitals) {
    final bp = vitals.where((v) => v.type == VitalType.bloodPressure && v.systolicBP != null);
    return bp.map((v) => FlSpot(v.timestamp.millisecondsSinceEpoch.toDouble(), v.systolicBP!.toDouble())).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> _getBPDiastolicData(List<VitalsModel> vitals) {
    final bp = vitals.where((v) => v.type == VitalType.bloodPressure && v.diastolicBP != null);
    return bp.map((v) => FlSpot(v.timestamp.millisecondsSinceEpoch.toDouble(), v.diastolicBP!.toDouble())).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> _getGlucoseData(List<VitalsModel> vitals) {
    final gl = vitals.where((v) => v.type == VitalType.bloodGlucose && v.bloodGlucose != null);
    return gl.map((v) => FlSpot(v.timestamp.millisecondsSinceEpoch.toDouble(), v.bloodGlucose!.toDouble())).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<FlSpot> _getWeightData(List<VitalsModel> vitals) {
    final w = vitals.where((v) => v.type == VitalType.weight && v.weight != null);
    return w.map((v) => FlSpot(v.timestamp.millisecondsSinceEpoch.toDouble(), v.weight!.toDouble())).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  Map<String, double> _calculateStatistics(List<VitalsModel> vitals) {
    List<double> values;
    if (_selectedType == 'bloodPressure') {
      values = vitals
          .where((v) => v.type == VitalType.bloodPressure && v.systolicBP != null)
          .map((v) => v.systolicBP!)
          .toList();
    } else if (_selectedType == 'glucose') {
      values = vitals
          .where((v) => v.type == VitalType.bloodGlucose && v.bloodGlucose != null)
          .map((v) => v.bloodGlucose!)
          .toList();
    } else {
      values = vitals
          .where((v) => v.type == VitalType.weight && v.weight != null)
          .map((v) => v.weight!)
          .toList();
    }
    if (values.isEmpty) return {};
    final avg = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    return {'avg': avg, 'max': max, 'min': min};
  }

  String _getTrendDirection(List<VitalsModel> vitals) {
    final sorted = List<VitalsModel>.from(vitals)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (sorted.length < 2) return 'insufficient data';
    if (_selectedType == 'bloodPressure') {
      final first = sorted.firstWhere((v) => v.type == VitalType.bloodPressure && v.systolicBP != null, orElse: () => sorted.first);
      final last = sorted.lastWhere((v) => v.type == VitalType.bloodPressure && v.systolicBP != null, orElse: () => sorted.last);
      if (first.systolicBP == null || last.systolicBP == null) return 'insufficient data';
      return last.systolicBP! < first.systolicBP! ? 'improving' : (last.systolicBP! > first.systolicBP! ? 'declining' : 'stable');
    } else if (_selectedType == 'glucose') {
      final first = sorted.firstWhere((v) => v.type == VitalType.bloodGlucose && v.bloodGlucose != null, orElse: () => sorted.first);
      final last = sorted.lastWhere((v) => v.type == VitalType.bloodGlucose && v.bloodGlucose != null, orElse: () => sorted.last);
      if (first.bloodGlucose == null || last.bloodGlucose == null) return 'insufficient data';
      return last.bloodGlucose! < first.bloodGlucose! ? 'improving' : (last.bloodGlucose! > first.bloodGlucose! ? 'declining' : 'stable');
    } else {
      final first = sorted.firstWhere((v) => v.type == VitalType.weight && v.weight != null, orElse: () => sorted.first);
      final last = sorted.lastWhere((v) => v.type == VitalType.weight && v.weight != null, orElse: () => sorted.last);
      if (first.weight == null || last.weight == null) return 'insufficient data';
      return last.weight! < first.weight! ? 'improving' : (last.weight! > first.weight! ? 'declining' : 'stable');
    }
  }
}
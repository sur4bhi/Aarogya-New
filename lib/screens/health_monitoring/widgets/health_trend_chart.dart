import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/patient_vitals_overview_model.dart';
import '../../../providers/health_monitoring_provider.dart';
import '../../../core/utils/app_utils.dart';

class HealthTrendChart extends StatefulWidget {
  final VitalType vitalType;
  final String? patientId; // For individual patient trends
  final int days;
  final bool showLegend;
  final bool isPopulation; // For population-level trends
  final double? height;

  const HealthTrendChart({
    Key? key,
    required this.vitalType,
    this.patientId,
    this.days = 30,
    this.showLegend = true,
    this.isPopulation = false,
    this.height,
  }) : super(key: key);

  @override
  State<HealthTrendChart> createState() => _HealthTrendChartState();
}

class _HealthTrendChartState extends State<HealthTrendChart> {
  int _selectedDays = 30;
  bool _showDataPoints = true;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.days;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        return Container(
          height: widget.height ?? 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(child: _buildChart(provider)),
              if (widget.showLegend) ...[
                const SizedBox(height: 12),
                _buildLegend(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _getVitalIcon(widget.vitalType),
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getVitalTitle(widget.vitalType),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.patientId != null)
                Text(
                  'व्यक्तिगत रुझान',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Text(
                  widget.isPopulation ? 'समुदायिक रुझान' : 'सामान्य रुझान',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        _buildTimePeriodSelector(),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            _showDataPoints ? Icons.scatter_plot : Icons.show_chart,
            color: AppColors.primary,
          ),
          onPressed: () {
            setState(() {
              _showDataPoints = !_showDataPoints;
            });
          },
          tooltip: _showDataPoints ? 'लाइन व्यू' : 'पॉइंट व्यू',
        ),
      ],
    );
  }

  Widget _buildTimePeriodSelector() {
    return PopupMenuButton<int>(
      initialValue: _selectedDays,
      onSelected: (days) {
        setState(() {
          _selectedDays = days;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 7, child: Text('7 दिन')),
        PopupMenuItem(value: 14, child: Text('2 सप्ताह')),
        PopupMenuItem(value: 30, child: Text('1 महीना')),
        PopupMenuItem(value: 90, child: Text('3 महीने')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedDays} दिन',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.medium,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(HealthMonitoringProvider provider) {
    final chartData = _getChartData(provider);
    
    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'डेटा उपलब्ध नहीं',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getGridInterval(widget.vitalType),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getBottomInterval(),
              getTitlesWidget: (value, meta) => _buildBottomTitle(value),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: _getGridInterval(widget.vitalType),
              getTitlesWidget: (value, meta) => _buildLeftTitle(value),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.outline.withOpacity(0.2)),
        ),
        minX: 0,
        maxX: (_selectedDays - 1).toDouble(),
        minY: _getMinY(chartData),
        maxY: _getMaxY(chartData),
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            color: _getVitalColor(widget.vitalType),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: _showDataPoints,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getVitalColor(widget.vitalType),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _getVitalColor(widget.vitalType).withOpacity(0.1),
            ),
          ),
          if (widget.vitalType == VitalType.bloodPressure) ...[
            // Add systolic/diastolic lines for BP
            _buildDiastolicLine(provider),
          ],
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            // Handle touch interactions
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.surface.withOpacity(0.9),
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date = DateTime.now().subtract(
                  Duration(days: _selectedDays - barSpot.x.toInt() - 1)
                );
                return LineTooltipItem(
                  '${AppUtils.formatDate(date)}\n${barSpot.y.toStringAsFixed(1)} ${_getUnit(widget.vitalType)}',
                  AppTextStyles.bodySmall.copyWith(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildDiastolicLine(HealthMonitoringProvider provider) {
    // This would be implemented for blood pressure diastolic readings
    final diastolicData = _getDiastolicData(provider);
    
    return LineChartBarData(
      spots: diastolicData,
      isCurved: true,
      color: _getVitalColor(widget.vitalType).withOpacity(0.6),
      barWidth: 2,
      isStrokeCapRound: true,
      dashArray: [5, 5],
      dotData: FlDotData(
        show: _showDataPoints,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: _getVitalColor(widget.vitalType).withOpacity(0.6),
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      children: [
        _LegendItem(
          color: _getVitalColor(widget.vitalType),
          label: widget.vitalType == VitalType.bloodPressure 
              ? 'सिस्टोलिक' 
              : _getVitalTitle(widget.vitalType),
        ),
        if (widget.vitalType == VitalType.bloodPressure)
          _LegendItem(
            color: _getVitalColor(widget.vitalType).withOpacity(0.6),
            label: 'डायस्टोलिक',
            isDashed: true,
          ),
      ],
    );
  }

  Widget _buildBottomTitle(double value) {
    final date = DateTime.now().subtract(
      Duration(days: _selectedDays - value.toInt() - 1)
    );
    
    String label;
    if (_selectedDays <= 7) {
      label = '${date.day}/${date.month}';
    } else if (_selectedDays <= 30) {
      label = value.toInt() % 7 == 0 ? '${date.day}/${date.month}' : '';
    } else {
      label = value.toInt() % 14 == 0 ? '${date.day}/${date.month}' : '';
    }
    
    return Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLeftTitle(double value) {
    return Text(
      value.toInt().toString(),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  List<FlSpot> _getChartData(HealthMonitoringProvider provider) {
    if (widget.isPopulation) {
      return _getPopulationTrendData(provider);
    } else if (widget.patientId != null) {
      return _getPatientTrendData(provider, widget.patientId!);
    } else {
      return _getAverageTrendData(provider);
    }
  }

  List<FlSpot> _getPopulationTrendData(HealthMonitoringProvider provider) {
    final data = provider.getPopulationTrendData(widget.vitalType, _selectedDays);
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  List<FlSpot> _getPatientTrendData(HealthMonitoringProvider provider, String patientId) {
    final patient = provider.getPatientById(patientId);
    if (patient == null) return [];

    final trend = patient.getTrend(widget.vitalType);
    if (trend == null || trend.values.isEmpty) return [];

    // Take the most recent data points up to _selectedDays
    final recentData = trend.values.take(_selectedDays).toList().reversed.toList();
    return recentData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  List<FlSpot> _getAverageTrendData(HealthMonitoringProvider provider) {
    // Calculate average across all patients for this vital
    final spots = <FlSpot>[];
    
    for (int i = 0; i < _selectedDays; i++) {
      final dayValues = <double>[];
      
      for (final patient in provider.allPatients) {
        final trend = patient.getTrend(widget.vitalType);
        if (trend != null && trend.values.length > i) {
          dayValues.add(trend.values.reversed.toList()[i]);
        }
      }
      
      if (dayValues.isNotEmpty) {
        final average = dayValues.reduce((a, b) => a + b) / dayValues.length;
        spots.add(FlSpot(i.toDouble(), average));
      }
    }
    
    return spots;
  }

  List<FlSpot> _getDiastolicData(HealthMonitoringProvider provider) {
    // For blood pressure, we'll approximate diastolic from systolic
    final systolicData = _getChartData(provider);
    return systolicData.map((spot) {
      final diastolic = spot.y * 0.65; // Approximate diastolic
      return FlSpot(spot.x, diastolic);
    }).toList();
  }

  double _getBottomInterval() {
    if (_selectedDays <= 7) return 1;
    if (_selectedDays <= 30) return 7;
    return 14;
  }

  double _getGridInterval(VitalType vitalType) {
    switch (vitalType) {
      case VitalType.bloodPressure:
        return 20;
      case VitalType.bloodGlucose:
        return 50;
      case VitalType.weight:
        return 5;
      case VitalType.heartRate:
        return 20;
      case VitalType.temperature:
        return 1;
      case VitalType.oxygenSaturation:
        return 5;
    }
  }

  double _getMinY(List<FlSpot> data) {
    if (data.isEmpty) return 0;
    final minValue = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    return (minValue * 0.9).floorToDouble();
  }

  double _getMaxY(List<FlSpot> data) {
    if (data.isEmpty) return 100;
    final maxValue = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.1).ceilToDouble();
  }

  Color _getVitalColor(VitalType vitalType) {
    switch (vitalType) {
      case VitalType.bloodPressure:
        return AppColors.error;
      case VitalType.bloodGlucose:
        return AppColors.warning;
      case VitalType.weight:
        return AppColors.info;
      case VitalType.heartRate:
        return AppColors.primary;
      case VitalType.temperature:
        return AppColors.success;
      case VitalType.oxygenSaturation:
        return AppColors.primary;
    }
  }

  IconData _getVitalIcon(VitalType vitalType) {
    switch (vitalType) {
      case VitalType.bloodPressure:
        return Icons.favorite;
      case VitalType.bloodGlucose:
        return Icons.bloodtype;
      case VitalType.weight:
        return Icons.monitor_weight;
      case VitalType.heartRate:
        return Icons.heart_broken;
      case VitalType.temperature:
        return Icons.thermostat;
      case VitalType.oxygenSaturation:
        return Icons.air;
    }
  }

  String _getVitalTitle(VitalType vitalType) {
    switch (vitalType) {
      case VitalType.bloodPressure:
        return 'रक्तचाप';
      case VitalType.bloodGlucose:
        return 'रक्त शर्करा';
      case VitalType.weight:
        return 'वजन';
      case VitalType.heartRate:
        return 'हृदय गति';
      case VitalType.temperature:
        return 'तापमान';
      case VitalType.oxygenSaturation:
        return 'ऑक्सीजन';
    }
  }

  String _getUnit(VitalType vitalType) {
    switch (vitalType) {
      case VitalType.bloodPressure:
        return 'mmHg';
      case VitalType.bloodGlucose:
        return 'mg/dL';
      case VitalType.weight:
        return 'kg';
      case VitalType.heartRate:
        return 'bpm';
      case VitalType.temperature:
        return '°F';
      case VitalType.oxygenSaturation:
        return '%';
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    Key? key,
    required this.color,
    required this.label,
    this.isDashed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                  size: const Size(20, 3),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Compact trend chart for overview
class CompactTrendChart extends StatelessWidget {
  final VitalType vitalType;
  final List<double> data;
  final double? height;
  final bool showCurrentValue;

  const CompactTrendChart({
    Key? key,
    required this.vitalType,
    required this.data,
    this.height,
    this.showCurrentValue = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height ?? 60,
        child: Center(
          child: Text(
            'No data',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return Container(
      height: height ?? 60,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: data.reduce((a, b) => a < b ? a : b) * 0.95,
          maxY: data.reduce((a, b) => a > b ? a : b) * 1.05,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _getVitalColor(vitalType),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: _getVitalColor(vitalType).withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }

  Color _getVitalColor(VitalType vitalType) {
    switch (vitalType) {
      case VitalType.bloodPressure:
        return AppColors.error;
      case VitalType.bloodGlucose:
        return AppColors.warning;
      case VitalType.weight:
        return AppColors.info;
      case VitalType.heartRate:
        return AppColors.primary;
      case VitalType.temperature:
        return AppColors.success;
      case VitalType.oxygenSaturation:
        return AppColors.primary;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/patient_alert_model.dart';

class EmergencyAlertBanner extends StatefulWidget {
  final List<PatientAlert> emergencyAlerts;
  final VoidCallback onViewAll;
  final Function(PatientAlert) onAlertTap;

  const EmergencyAlertBanner({
    Key? key,
    required this.emergencyAlerts,
    required this.onViewAll,
    required this.onAlertTap,
  }) : super(key: key);

  @override
  State<EmergencyAlertBanner> createState() => _EmergencyAlertBannerState();
}

class _EmergencyAlertBannerState extends State<EmergencyAlertBanner>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  PageController? _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.emergencyAlerts.isNotEmpty) {
      _pulseController.repeat(reverse: true);
      
      if (widget.emergencyAlerts.length > 1) {
        _pageController = PageController();
        _startAutoScroll();
      }
    }
  }

  void _startAutoScroll() {
    if (_pageController != null && widget.emergencyAlerts.length > 1) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _pageController != null) {
          final nextPage = (_currentPage + 1) % widget.emergencyAlerts.length;
          _pageController!.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentPage = nextPage;
          });
          _startAutoScroll();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.emergencyAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red[700]!,
                  Colors.red[600]!,
                  Colors.red[500]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emergency,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'आपातकालीन अलर्ट',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.emergencyAlerts.length} सक्रिय आपातकालीन स्थिति',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onViewAll,
                        child: Text(
                          'सभी देखें',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Emergency alerts carousel
                if (widget.emergencyAlerts.length == 1)
                  _buildSingleAlert(widget.emergencyAlerts.first)
                else
                  _buildAlertsCarousel(),

                // Page indicators for multiple alerts
                if (widget.emergencyAlerts.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.emergencyAlerts.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleAlert(PatientAlert alert) {
    return GestureDetector(
      onTap: () => widget.onAlertTap(alert),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _buildAlertContent(alert),
      ),
    );
  }

  Widget _buildAlertsCarousel() {
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.emergencyAlerts.length,
        itemBuilder: (context, index) {
          final alert = widget.emergencyAlerts[index];
          return GestureDetector(
            onTap: () => widget.onAlertTap(alert),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _buildAlertContent(alert),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertContent(PatientAlert alert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(alert.category),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.patientName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getTimeDifference(alert.timestamp),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.medium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.95),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (alert.vitals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatVitals(alert.vitals),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(AlertCategory category) {
    switch (category) {
      case AlertCategory.emergencySOS:
        return Icons.emergency;
      case AlertCategory.criticalVitals:
        return Icons.favorite;
      case AlertCategory.missedCheckIn:
        return Icons.schedule;
      case AlertCategory.medicationAdherence:
        return Icons.medication;
      case AlertCategory.appointmentReminder:
        return Icons.calendar_today;
      case AlertCategory.patternConcern:
        return Icons.trending_down;
    }
  }

  String _getTimeDifference(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'अभी';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}मिनट';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}घंटे';
    } else {
      return DateFormat('dd/MM').format(timestamp);
    }
  }

  String _formatVitals(Map<String, dynamic> vitals) {
    final List<String> vitalStrings = [];
    
    if (vitals['heartRate'] != null) {
      vitalStrings.add('HR: ${vitals['heartRate']}');
    }
    if (vitals['bloodPressure'] != null) {
      vitalStrings.add('BP: ${vitals['bloodPressure']}');
    }
    if (vitals['bloodGlucose'] != null) {
      vitalStrings.add('Glucose: ${vitals['bloodGlucose']}');
    }
    if (vitals['temperature'] != null) {
      vitalStrings.add('Temp: ${vitals['temperature']}°C');
    }
    
    return vitalStrings.take(2).join(' • ');
  }
}
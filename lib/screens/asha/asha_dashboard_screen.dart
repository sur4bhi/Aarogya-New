import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/utils/health_utils.dart';
import '../../models/vitals_model.dart';
import '../../providers/auth_provider.dart';

class AshaDashboardScreen extends StatefulWidget {
  const AshaDashboardScreen({super.key});

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final ashaId = context.read<AuthProvider>().userId;
    if (ashaId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login as ASHA to view dashboard')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .where('ashaId', isEqualTo: ashaId)
        .where('userType', isEqualTo: 'patient')
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ASHA Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load patients'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red)),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No patients assigned yet'));
          }

          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsHeader(docs),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final patientId = docs[index].id;
                      final name = data['name'] ?? 'Patient';
                      final age = data['age'];

                      return _PatientCard(
                        patientId: patientId,
                        name: name,
                        age: (age is int) ? age : null,
                        onTap: () => _navigateToPatientDetails(context, patientId),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(List<QueryDocumentSnapshot> docs) {
    final total = docs.length;
    int abnormal = 0;
    int overdue = 0;

    // We do a rough pass using stored fields if present; detailed check per card
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final lastVitalsAt = data['lastVitalsAt'];
      if (lastVitalsAt is Timestamp) {
        final days = DateTime.now().difference(lastVitalsAt.toDate()).inDays;
        if (days >= 7) overdue++;
      }
      if ((data['hasRecentAbnormal'] ?? false) == true) abnormal++;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statChip('Patients', total.toString(), Colors.blue),
        _statChip('Abnormal', abnormal.toString(), Colors.red),
        _statChip('Overdue', overdue.toString(), Colors.orange),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.4)),
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
    );
  }

  void _navigateToPatientDetails(BuildContext context, String patientId) {
    AppRoutes.navigateToPatientDetails(context, patientId: patientId);
  }
}

class _PatientCard extends StatelessWidget {
  final String patientId;
  final String name;
  final int? age;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patientId,
    required this.name,
    required this.age,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (age != null) Text('Age: $age'),
                    const SizedBox(height: 4),
                    _LatestVitalsBadge(patientId: patientId),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Message',
                icon: const Icon(Icons.message_outlined),
                onPressed: () {
                  // Navigate to ASHA chat
                  AppRoutes.navigateToAshaChat(context, patientId: patientId);
                },
              ),
              IconButton(
                tooltip: 'Details',
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestVitalsBadge extends StatelessWidget {
  final String patientId;
  const _LatestVitalsBadge({required this.patientId});

  @override
  Widget build(BuildContext context) {
    final vitalsRef = FirebaseFirestore.instance
        .collection('users/$patientId/vitals')
        .orderBy('timestamp', descending: true)
        .limit(1);

    return StreamBuilder<QuerySnapshot>(
      stream: vitalsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No vitals yet');
        }
        final doc = snapshot.data!.docs.first;
        final latest = VitalsModel.fromFirestore(doc);

        final status = _calculateAlertStatus(latest);
        final timeStr = latest.timestamp.toLocal().toString();

        Color color;
        String label;
        switch (status) {
          case _AlertType.critical:
            color = Colors.red;
            label = 'Critical';
            break;
          case _AlertType.warning:
            color = Colors.orange;
            label = 'Warning';
            break;
          case _AlertType.overdue:
            color = Colors.grey;
            label = 'Overdue';
            break;
          case _AlertType.normal:
          default:
            color = Colors.green;
            label = 'Normal';
        }

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last: $timeStr',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  _AlertType _calculateAlertStatus(VitalsModel vitals) {
    // Overdue handled if no data; with latest data, check critical/warning rules
    if (vitals.type == VitalType.bloodPressure &&
        vitals.systolicBP != null && vitals.diastolicBP != null) {
      final s = vitals.systolicBP!;
      final d = vitals.diastolicBP!;
      if (s >= 180 || d >= 110) return _AlertType.critical;
      if (s >= 140 || d >= 90) return _AlertType.warning;
    }
    if (vitals.type == VitalType.bloodGlucose && vitals.bloodGlucose != null) {
      final g = vitals.bloodGlucose!;
      if (g > 300) return _AlertType.critical;
      if (g > 200) return _AlertType.warning;
    }

    // Overdue if older than 7 days
    if (DateTime.now().difference(vitals.timestamp).inDays >= 7) {
      return _AlertType.overdue;
    }
    return _AlertType.normal;
  }
}

enum _AlertType { normal, warning, critical, overdue }

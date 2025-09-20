import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  final String name;
  final String lastUpdate;
  const PatientCard({super.key, required this.name, required this.lastUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('Last update: $lastUpdate'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

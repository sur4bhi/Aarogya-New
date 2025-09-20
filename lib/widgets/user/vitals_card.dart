import 'package:flutter/material.dart';

class VitalsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  const VitalsCard({super.key, required this.title, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$value $unit', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

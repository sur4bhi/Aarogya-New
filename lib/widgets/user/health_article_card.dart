import 'package:flutter/material.dart';

class HealthArticleCard extends StatelessWidget {
  final String title;
  final String summary;
  const HealthArticleCard({super.key, required this.title, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(summary),
      ),
    );
  }
}

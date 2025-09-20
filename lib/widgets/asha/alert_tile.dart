import 'package:flutter/material.dart';

class AlertTile extends StatelessWidget {
  final String message;
  final Color color;
  const AlertTile({super.key, required this.message, this.color = Colors.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.warning, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

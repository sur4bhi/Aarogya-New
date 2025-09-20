import 'package:flutter/material.dart';

class ReminderTile extends StatelessWidget {
  final String title;
  final String time;
  final bool isOverdue;
  const ReminderTile({super.key, required this.title, required this.time, this.isOverdue = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(title),
      subtitle: Text(time),
      trailing: isOverdue ? const Icon(Icons.warning, color: Colors.red) : null,
    );
  }
}

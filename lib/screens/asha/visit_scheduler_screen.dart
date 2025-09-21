import 'package:flutter/material.dart';

class VisitSchedulerScreen extends StatefulWidget {
  const VisitSchedulerScreen({super.key});

  @override
  State<VisitSchedulerScreen> createState() => _VisitSchedulerScreenState();
}

class _VisitSchedulerScreenState extends State<VisitSchedulerScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _address = TextEditingController();
  bool _saving = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visit scheduled (stub)')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _notes.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Scheduler')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Select date'),
              subtitle: Text('${_selectedDate.toLocal()}'.split(' ').first),
              onTap: _pickDate,
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Visit address (optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save'),
            )
          ],
        ),
      ),
    );
  }
}

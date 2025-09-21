import 'package:flutter/material.dart';

class QueueBookingScreen extends StatefulWidget {
  const QueueBookingScreen({super.key});

  @override
  State<QueueBookingScreen> createState() => _QueueBookingScreenState();
}

class _QueueBookingScreenState extends State<QueueBookingScreen> {
  final _facilityCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _emergency = false;
  String? _ticketId;

  @override
  void dispose() {
    _facilityCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinQueue() async {
    if (_facilityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a facility name')));
      return;
    }
    // Simulate ticket creation locally. In production, call backend.
    final id = 'Q${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    setState(() => _ticketId = id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined queue at ${_facilityCtrl.text.trim()}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Queue Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _facilityCtrl,
              decoration: const InputDecoration(labelText: 'Facility name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason / Notes (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Emergency priority'),
              value: _emergency,
              onChanged: (v) => setState(() => _emergency = v),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _joinQueue,
              icon: const Icon(Icons.queue_play_next),
              label: const Text('Join Queue'),
            ),
            const SizedBox(height: 16),
            if (_ticketId != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: Text('Ticket: $_ticketId'),
                  subtitle: Text(_emergency ? 'Priority: Emergency' : 'Priority: Normal'),
                ),
              )
          ],
        ),
      ),
    );
  }
}

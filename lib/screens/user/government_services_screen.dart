import 'package:flutter/material.dart';
import '../../core/services/government_service.dart';

class GovernmentServicesScreen extends StatefulWidget {
  const GovernmentServicesScreen({super.key});

  @override
  State<GovernmentServicesScreen> createState() => _GovernmentServicesScreenState();
}

class _GovernmentServicesScreenState extends State<GovernmentServicesScreen> {
  final TextEditingController _query = TextEditingController();
  List<JanAushadhiStore> _stores = [];
  List<GovScheme> _schemes = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    final s = await GovernmentService.getSchemes();
    if (!mounted) return;
    setState(() => _schemes = s);
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    try {
      final stores = await GovernmentService.searchJanAushadhiStores(_query.text.trim());
      if (!mounted) return;
      setState(() => _stores = stores);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Services')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _query,
              decoration: InputDecoration(
                labelText: 'Find Jan Aushadhi stores (city/pincode)',
                suffixIcon: IconButton(
                  onPressed: _busy ? null : _search,
                  icon: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_stores.isNotEmpty) ...[
              Text('Stores', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._stores.map((s) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_pharmacy_outlined),
                      title: Text(s.name),
                      subtitle: Text('${s.address}\nStock info: ${s.stockInfo ?? 'N/A'}'),
                      isThreeLine: true,
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            Text('Health Schemes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._schemes.map((sch) => Card(
                  child: ListTile(
                    title: Text(sch.title),
                    subtitle: Text(sch.description),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/user/queue-booking'),
              icon: const Icon(Icons.queue_play_next),
              label: const Text('Queue Booking'),
            ),
          ],
        ),
      ),
    );
  }
}

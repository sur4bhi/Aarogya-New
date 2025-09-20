import 'package:flutter/material.dart';
import '../../core/constants.dart';

// TODO: import 'package:provider/provider.dart';
// TODO: import '../../providers/asha_provider.dart';
// TODO: import '../../core/services/local_storage.dart';

/// ASHA Connect
/// - Search by name, PIN, or location.
/// - Shows list of nearby ASHA with Connect buttons.
/// - Offline cache via LocalStorage (TODO).
class AshaConnectScreen extends StatefulWidget {
  const AshaConnectScreen({super.key});

  @override
  State<AshaConnectScreen> createState() => _AshaConnectScreenState();
}

class _AshaConnectScreenState extends State<AshaConnectScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, String>> _results = const [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _searchCtrl.text.trim();
      // TODO: final res = await context.read<AshaProvider>().searchAsha(q);
      final res = [
        {'id': 'a1', 'name': 'ASHA Priya', 'pin': '411001'},
        {'id': 'a2', 'name': 'ASHA Meera', 'pin': '411002'},
      ];
      setState(() => _results = res);
      // TODO: cache results to LocalStorage
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _connect(String ashaId) async {
    setState(() => _loading = true);
    try {
      // TODO: await context.read<AshaProvider>().sendConnectionRequest(ashaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scanQr() {
    // TODO: Implement QR scanning flow
  }

  void _enterCode() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter ASHA code'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(ctx); /* TODO: lookup by code */ }, child: const Text('Submit')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect ASHA')), // TODO: l10n
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or PIN', // TODO
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _loading ? null : _search, child: const Text('Search')),
              ],
            ),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                TextButton.icon(onPressed: _scanQr, icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan QR')),
                TextButton.icon(onPressed: _enterCode, icon: const Icon(Icons.pin), label: const Text('Enter Code')),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final asha = _results[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.medical_services)),
                        title: Text(asha['name'] ?? ''),
                        subtitle: Text('PIN: ${asha['pin']}'),
                        trailing: ElevatedButton(
                          onPressed: _loading ? null : () => _connect(asha['id']!),
                          child: const Text('Connect'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:provider/provider.dart';
import '../../providers/asha_provider.dart';
import '../../providers/user_provider.dart';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    await context.read<AshaProvider>().search(q);
  }

  Future<void> _connect(String ashaId) async {
    try {
      await context.read<AshaProvider>().connectToAsha(
            ashaId: ashaId,
            userProvider: context.read<UserProvider>(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to ASHA')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
    final ashaProvider = context.watch<AshaProvider>();
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
                ElevatedButton(onPressed: ashaProvider.isLoading ? null : _search, child: const Text('Search')),
              ],
            ),
          ),
          if (ashaProvider.error != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(ashaProvider.error!, style: const TextStyle(color: Colors.red)),
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
            child: ashaProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: ashaProvider.results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final asha = ashaProvider.results[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.medical_services)),
                        title: Text(asha['name'] ?? ''),
                        subtitle: Text('PIN: ${asha['pin']}'),
                        trailing: ElevatedButton(
                          onPressed: ashaProvider.isLoading ? null : () => _connect(asha['id']!),
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

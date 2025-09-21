import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/services/local_storage.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  Future<void> _select(BuildContext context, String role) async {
    debugPrint('Role Select Screen: Role selected: $role');
    await LocalStorageService.saveSetting('user_role', role);
    debugPrint('Role Select Screen: Role saved, navigating to dashboard');
    // After selecting role, go directly to respective dashboard
    if (role == 'asha') {
      AppRoutes.navigateToAshaDashboard(context);
    } else {
      AppRoutes.navigateToUserDashboard(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Role Select Screen: Building UI');
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Role')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text('Who are you?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Normal User'),
                subtitle: const Text('Track vitals, reminders, reports, and contact ASHA'),
                onTap: () => _select(context, 'user'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: const Text('ASHA Worker'),
                subtitle: const Text('Monitor patients, get alerts, manage visits and chat'),
                onTap: () => _select(context, 'asha'),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                // Clear saved role
                await LocalStorageService.deleteSetting('user_role');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role preference cleared')));
              },
              child: const Text('Clear selection'),
            )
          ],
        ),
      ),
    );
  }
}

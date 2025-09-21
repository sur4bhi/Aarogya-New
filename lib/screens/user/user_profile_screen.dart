import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/routes.dart';
import '../../l10n/app_localizations.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langProvider = context.watch<LanguageProvider>();
    final userProvider = context.watch<UserProvider>();
    final incomplete = !userProvider.isProfileComplete;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          if (incomplete)
            Card(
              color: Colors.orange.withOpacity(0.1),
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.orange),
                title: const Text('Complete your profile'),
                subtitle: const Text('Add your basic details to personalize your health insights'),
                trailing: FilledButton(
                  onPressed: () => AppRoutes.navigateToProfileSetup(context),
                  child: const Text('Complete'),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.language),
            subtitle: Text(langProvider.getCurrentLanguageName()),
            onTap: () => _openLanguageSheet(context),
          ),
          const Divider(height: 1),
          // Other settings tiles can go here
        ],
      ),
    );
  }

  void _openLanguageSheet(BuildContext context) {
    final current = context.read<LanguageProvider>().languageCode;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.english),
                trailing: current == 'en' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('en');
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.hindi),
                trailing: current == 'hi' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('hi');
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.marathi),
                trailing: current == 'mr' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('mr');
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

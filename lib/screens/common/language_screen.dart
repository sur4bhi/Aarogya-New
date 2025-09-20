import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/services/local_storage.dart';

// TODO: import 'package:provider/provider.dart';
// TODO: import '../../providers/language_provider.dart';

/// Language selection screen used for first run or settings.
/// - Allows user to pick English/Hindi/Marathi.
/// - On selection, updates `LanguageProvider` and persists via `LocalStorageService`.
/// - Confirm button proceeds to next route.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = LocalStorageService.getLanguage();

  void _onSelect(String code) {
    setState(() {
      _selected = code;
    });
    // TODO: context.read<LanguageProvider>().setLocale(code);
  }

  Future<void> _confirm() async {
    await LocalStorageService.saveLanguage(_selected);
    if (!mounted) return;
    // In onboarding flow, go to auth; if from settings, pop
    AppRoutes.navigateToAuth(context);
  }

  Widget _preview(String code) {
    switch (code) {
      case 'hi':
        return const Text('यह एक पूर्वावलोकन पाठ है');
      case 'mr':
        return const Text('हा पूर्वावलोकन मजकूर आहे');
      default:
        return const Text('This is a preview text');
    }
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n; // TODO: generated l10n
    return Scaffold(
      appBar: AppBar(title: const Text('Select Language')), // TODO: l10n.selectLanguage
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        children: [
          // English
          Semantics(
            label: 'English option selected: ${false}', // TODO: Announce via l10n
            child: RadioListTile<String>(
              value: 'en',
              groupValue: _selected,
              onChanged: (v) => _onSelect(v ?? 'en'),
              title: const Text('English'),
              subtitle: _preview('en'),
              secondary: const Icon(Icons.language),
            ),
          ),
          // Hindi
          Semantics(
            label: 'Hindi option',
            child: RadioListTile<String>(
              value: 'hi',
              groupValue: _selected,
              onChanged: (v) => _onSelect(v ?? 'hi'),
              title: const Text('हिन्दी'),
              subtitle: _preview('hi'),
              secondary: const Icon(Icons.translate),
            ),
          ),
          // Marathi
          Semantics(
            label: 'Marathi option',
            child: RadioListTile<String>(
              value: 'mr',
              groupValue: _selected,
              onChanged: (v) => _onSelect(v ?? 'mr'),
              title: const Text('मराठी'),
              subtitle: _preview('mr'),
              secondary: const Icon(Icons.text_fields),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              child: const Text('Confirm'), // TODO: l10n.confirm
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/services/local_storage.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

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
    context.read<LanguageProvider>().setLanguage(code);
  }

  Future<void> _confirm() async {
    await context.read<LanguageProvider>().setLanguage(_selected);
    await LocalStorageService.setFirstTimeLaunch(false);
    if (!mounted) return;
    // In onboarding flow, go to auth; if from settings, pop
    if (Navigator.canPop(context)) {
      Navigator.pop(context, _selected);
    } else {
      AppRoutes.navigateToAuth(context);
    }
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
    final l10n = AppLocalizations.of(context)!;
    final isFirstFlow = LocalStorageService.isFirstTimeLaunch();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectLanguage)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        children: [
          // English
          Semantics(
            label: '${l10n.english} option',
            child: RadioListTile<String>(
              value: 'en',
              groupValue: _selected,
              onChanged: (v) => _onSelect(v ?? 'en'),
              title: Text(l10n.english),
              subtitle: _preview('en'),
              secondary: const Icon(Icons.language),
            ),
          ),
          // Hindi
          Semantics(
            label: '${l10n.hindi} option',
            child: RadioListTile<String>(
              value: 'hi',
              groupValue: _selected,
              onChanged: (v) => _onSelect(v ?? 'hi'),
              title: Text(l10n.hindi),
              subtitle: _preview('hi'),
              secondary: const Icon(Icons.translate),
            ),
          ),
          // Marathi
          Semantics(
            label: '${l10n.marathi} option',
            child: RadioListTile<String>(
              value: 'mr',
              groupValue: _selected,
              onChanged: (v) => _onSelect(v ?? 'mr'),
              title: Text(l10n.marathi),
              subtitle: _preview('mr'),
              secondary: const Icon(Icons.text_fields),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              child: Text(l10n.continueLabel),
            ),
          ),
          if (isFirstFlow) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                // Default to English and proceed
                await context.read<LanguageProvider>().setLanguage('en');
                await LocalStorageService.setFirstTimeLaunch(false);
                if (!mounted) return;
                AppRoutes.navigateToAuth(context);
              },
              child: Text(l10n.skipForNow),
            ),
          ],
        ],
      ),
    );
  }
}

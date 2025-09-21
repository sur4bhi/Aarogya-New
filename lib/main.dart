import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/services/notification_service.dart';
import 'core/services/local_storage.dart';
import 'core/services/sync_service.dart';
import 'providers/auth_provider.dart';
import 'providers/vitals_provider.dart';
import 'providers/user_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/language_provider.dart';
import 'providers/profile_setup_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/asha_provider.dart';
import 'providers/reports_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Production-only configurations
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

  // Initialize core services
  await NotificationService.init();
  await LocalStorageService.init();
  await SyncService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VitalsProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..loadSavedLanguage()),
        ChangeNotifierProvider(create: (_) => ProfileSetupProvider()),
        ChangeNotifierProvider(create: (_) => RemindersProvider()..loadReminders()),
        ChangeNotifierProvider(create: (_) => AshaProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()..loadReports()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Aarogya Sahayak',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              extensions: const [HealthColors.light],
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              extensions: const [HealthColors.dark],
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: context.watch<LanguageProvider>().currentLocale,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}

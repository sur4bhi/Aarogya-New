// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Aarogya Sahayak';

  @override
  String get hello => 'Hello';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get continueLabel => 'Continue';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get marathi => 'Marathi';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get bloodPressure => 'Blood Pressure';

  @override
  String get bloodSugar => 'Blood Sugar';

  @override
  String get weight => 'Weight';

  @override
  String get latestVitals => 'Latest Vitals';

  @override
  String get seeTrends => 'See trends';

  @override
  String get healthFeed => 'Health Feed';

  @override
  String get seeAll => 'See all';

  @override
  String get addVitals => 'Add Vitals';

  @override
  String get uploadReport => 'Upload Report';

  @override
  String get connectAsha => 'Connect ASHA';

  @override
  String get reminders => 'Reminders';

  @override
  String get syncedSuccessfully => 'Synced successfully';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get offlineBanner => 'Offline - Data will sync when online';

  @override
  String pendingSyncItems(int count) => 'Pending sync items: $count';
}

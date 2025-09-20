// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'आरोग्य सहायक';

  @override
  String get hello => 'नमस्ते';

  @override
  String get login => 'लॉगिन';

  @override
  String get register => 'रजिस्टर';

  @override
  String get selectLanguage => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get continueLabel => 'जारी रखें';

  @override
  String get skipForNow => 'अभी के लिए छोड़ें';

  @override
  String get languageChanged => 'भाषा सफलतापूर्वक बदल दी गई';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी';

  @override
  String get marathi => 'मराठी';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get bloodPressure => 'रक्तचाप';

  @override
  String get bloodSugar => 'ब्लड शुगर';

  @override
  String get weight => 'वज़न';

  @override
  String get latestVitals => 'नवीनतम स्वास्थ्य मान';

  @override
  String get seeTrends => 'रुझान देखें';

  @override
  String get healthFeed => 'स्वास्थ्य सामग्री';

  @override
  String get seeAll => 'सब देखें';

  @override
  String get addVitals => 'वाइटल्स जोड़ें';

  @override
  String get uploadReport => 'रिपोर्ट अपलोड करें';

  @override
  String get connectAsha => 'आशा से जुड़ें';

  @override
  String get reminders => 'रिमाइंडर्स';

  @override
  String get syncedSuccessfully => 'सफलतापूर्वक सिंक हो गया';

  @override
  String get syncFailed => 'सिंक विफल';

  @override
  String get offlineBanner => 'ऑफलाइन - ऑनलाइन होने पर डेटा सिंक होगा';

  @override
  String pendingSyncItems(int count) => 'लंबित सिंक आइटम: $count';
}

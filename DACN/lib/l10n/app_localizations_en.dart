// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Wave Music';

  @override
  String get homeTitle => 'Home';

  @override
  String get searchTitle => 'Search';

  @override
  String get libraryTitle => 'Library';

  @override
  String get userTitle => 'Account';

  @override
  String get loginButton => 'LOG IN';

  @override
  String get connectionLost => 'Connection lost. Please try again.';
}

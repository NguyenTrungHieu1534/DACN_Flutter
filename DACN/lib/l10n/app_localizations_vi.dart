// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Wave Music';

  @override
  String get homeTitle => 'Trang Chủ';

  @override
  String get searchTitle => 'Tìm Kiếm';

  @override
  String get libraryTitle => 'Thư Viện';

  @override
  String get userTitle => 'Tài Khoản';

  @override
  String get loginButton => 'ĐĂNG NHẬP';

  @override
  String get connectionLost => 'Mất kết nối mạng. Vui lòng thử lại.';
}

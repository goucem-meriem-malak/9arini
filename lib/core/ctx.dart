import 'package:flutter/material.dart';
import 'l10n/strings.dart';
import 'theme/tokens.dart';

extension Ctx on BuildContext {
  AppColors get c => Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  TextTheme get tx => Theme.of(this).textTheme;
  String get lang => Localizations.localeOf(this).languageCode;
  bool get isAr => lang == 'ar';
  String t(String key, [Map<String, String>? params]) => S.lookup(lang, key, params);
  String pl(String key, int n) => S.plural(lang, key, n);
  void toast(String msg) => ScaffoldMessenger.of(this)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

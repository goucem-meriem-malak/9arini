import 'package:flutter/widgets.dart';
import 'ctx.dart';

final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Validators return a string key (or null when valid). Use [tr] to localize.
String? vEmail(String? v) => (v != null && _emailRe.hasMatch(v.trim())) ? null : 'err_email';
String? vPassword(String? v) => (v != null && v.length >= 8) ? null : 'err_password';
String? vRequired(String? v, {int max = 120}) {
  if (v == null || v.trim().isEmpty) return 'err_required';
  return v.trim().length > max ? 'err_long' : null;
}

String? vInt(String? v, {int min = 0, int max = 1000000}) {
  final n = int.tryParse((v ?? '').trim());
  return (n == null || n < min || n > max) ? 'err_required' : null;
}

FormFieldValidator<String> tr(BuildContext context, String? Function(String?) f) => (v) {
      final k = f(v);
      return k == null ? null : context.t(k);
    };

import 'package:flutter_test/flutter_test.dart';
import 'package:qarini/core/l10n/strings.dart';

void main() {
  test('French and Arabic have every key that English has', () {
    final en = S.keysFor('en');
    for (final lang in ['fr', 'ar']) {
      final missing = en.difference(S.keysFor(lang)).where((k) => !k.contains('_one') && !k.contains('_other')).toList();
      expect(missing, isEmpty, reason: '$lang is missing $missing');
    }
  });

  test('plural categories', () {
    expect(S.category('en', 1), 'one');
    expect(S.category('en', 2), 'other');
    expect(S.category('fr', 0), 'one');
    expect(S.category('ar', 2), 'two');
    expect(S.category('ar', 5), 'few');
    expect(S.category('ar', 15), 'many');
    expect(S.plural('en', 'members', 3), '3 members');
    expect(S.plural('ar', 'members', 2), 'عضوان');
  });

  test('placeholders are replaced', () {
    expect(S.lookup('en', 'hello', {'name': 'Amina'}), 'Hello, Amina');
  });
}

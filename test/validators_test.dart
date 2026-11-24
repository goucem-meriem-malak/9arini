import 'package:flutter_test/flutter_test.dart';
import 'package:qarini/core/validators.dart';

void main() {
  test('email', () {
    expect(vEmail('amina@example.org'), isNull);
    expect(vEmail('amina@'), 'err_email');
    expect(vEmail(''), 'err_email');
  });
  test('password needs 8 characters', () {
    expect(vPassword('1234567'), 'err_password');
    expect(vPassword('12345678'), isNull);
  });
  test('integers in range', () {
    expect(vInt('10', min: 1, max: 200), isNull);
    expect(vInt('0', min: 1, max: 200), 'err_required');
    expect(vInt('abc'), 'err_required');
  });
}

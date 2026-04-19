import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/features/auth/auth_validation.dart';

void main() {
  test('validateEmailField rejects empty and invalid', () {
    expect(validateEmailField(null), isNotNull);
    expect(validateEmailField(''), isNotNull);
    expect(validateEmailField('bad'), isNotNull);
    expect(validateEmailField('a@b'), isNotNull);
    expect(validateEmailField('ok@example.com'), isNull);
  });

  test('validatePasswordField requires 8+ chars', () {
    expect(validatePasswordField(''), isNotNull);
    expect(validatePasswordField('short'), isNotNull);
    expect(validatePasswordField('12345678'), isNull);
  });
}

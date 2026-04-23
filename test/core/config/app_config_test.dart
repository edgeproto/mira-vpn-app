import 'package:flutter_test/flutter_test.dart';
import 'package:mira_vpn_app/core/config/app_config.dart';

void main() {
  test('apiBaseUrl matches kDefaultApiBaseUrl when API_BASE_URL is not defined', () {
    expect(AppConfig.apiBaseUrl, AppConfig.kDefaultApiBaseUrl);
    expect(AppConfig.apiBaseUrl, 'http://95.217.206.233:18080');
  });

  test('apiBaseUrl is a valid absolute http(s) URI', () {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    expect(uri.hasScheme, isTrue);
    expect(uri.scheme, anyOf('http', 'https'));
    expect(uri.host, isNotEmpty);
  });
}

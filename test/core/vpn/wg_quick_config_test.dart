import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/core/vpn/wg_quick_config.dart';

void main() {
  test('parseWireGuardEndpoint reads Endpoint line', () {
    const ini = '''
[Interface]
PrivateKey = abc

[Peer]
PublicKey = def
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
''';
    expect(parseWireGuardEndpoint(ini), 'vpn.example.com:51820');
  });

  test('parseWireGuardEndpoint returns null when missing', () {
    expect(parseWireGuardEndpoint('[Interface]\nPrivateKey=x\n'), isNull);
  });
}

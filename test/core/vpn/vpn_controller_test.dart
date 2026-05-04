import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/core/api/models/wireguard_config_dto.dart';
import 'package:mira_vpn_app/core/api/models/wireguard_location_dto.dart';
import 'package:mira_vpn_app/core/api/wireguard_api.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';
import 'package:mira_vpn_app/core/storage/guest_device_store.dart';
import 'package:mira_vpn_app/core/storage/wg_config_store.dart';
import 'package:mira_vpn_app/core/vpn/vpn_controller.dart';
import 'package:mira_vpn_app/core/vpn/vpn_providers.dart';
import 'package:mira_vpn_app/core/vpn/vpn_tunnel_contract.dart';
import 'package:mira_vpn_app/core/vpn/vpn_tunnel_stub.dart';
import 'package:mira_vpn_app/core/api/models/user_dto.dart';
import 'package:mira_vpn_app/features/auth/auth_controller.dart';

UserDto get _user => UserDto(
      id: 'u1',
      email: 'a@example.com',
      isPro: false,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    );

const _sampleIni = '''
[Interface]
PrivateKey = abc
Address = 10.0.0.2/32

[Peer]
PublicKey = def
Endpoint = 192.0.2.10:51820
AllowedIPs = 0.0.0.0/0
''';

class _SignedInAuth extends AuthController {
  @override
  AuthState build() => AuthState(isLoading: false, user: _user);
}

class _SignedOutAuth extends AuthController {
  @override
  AuthState build() => const AuthState(isLoading: false, user: null);
}

class _MemoryWgStore implements WgConfigStore {
  final _m = <String, String>{};

  @override
  Future<void> delete(String userId) async => _m.remove(userId);

  @override
  Future<String?> read(String userId) async => _m[userId];

  @override
  Future<void> write(String userId, String config) async {
    _m[userId] = config;
  }
}

class _StubVpnLocation extends VpnLocationController {
  @override
  Future<VpnLocationState> build() async => const VpnLocationState(
        locations: [
          WireguardLocationDto(name: 'Finland', displayName: 'Finland'),
        ],
        selectedName: 'Finland',
      );
}

class _FakeWireGuardApi implements WireGuardApi {
  const _FakeWireGuardApi({this.dto, this.guestDto, this.error});

  final WireGuardConfigDto? dto;
  final WireGuardConfigDto? guestDto;
  final Object? error;

  @override
  Future<List<WireguardLocationDto>> listLocations() async => const [
        WireguardLocationDto(name: 'Finland', displayName: 'Finland'),
      ];

  @override
  Future<WireGuardConfigDto> createConfig({required String location}) async {
    if (error != null) {
      Error.throwWithStackTrace(error!, StackTrace.current);
    }
    return dto!;
  }

  @override
  Future<WireGuardConfigDto> createGuestConfig({
    required String deviceId,
    required String location,
  }) async {
    if (error != null) {
      Error.throwWithStackTrace(error!, StackTrace.current);
    }
    return guestDto ?? dto!;
  }
}

List<Override> _vpnControllerTestOverrides(List<Override> inner) => <Override>[
      vpnLocationControllerProvider.overrideWith(_StubVpnLocation.new),
      ...inner,
    ];

class _FakeGuestDeviceStore implements GuestDeviceStore {
  const _FakeGuestDeviceStore(this.deviceId);
  final String deviceId;

  @override
  Future<String> readOrCreateDeviceId() async => deviceId;
}

class _FakeTunnel implements VpnTunnelAdapter {
  _FakeTunnel();

  final _stages = StreamController<String>.broadcast();
  final _traffic = StreamController<Map<String, dynamic>>.broadcast();
  var started = false;
  String currentStage = 'disconnected';

  @override
  bool get supported => true;

  @override
  Stream<String> get stageEvents => _stages.stream;

  @override
  Stream<Map<String, dynamic>> get trafficEvents => _traffic.stream;

  @override
  Future<void> initialize({
    required String interfaceName,
    String? vpnName,
    String? iosAppGroup,
  }) async {}

  @override
  Future<bool> checkVpnPermission() async => true;

  @override
  Future<void> refreshStage() async {}

  @override
  Future<String> stage() async => currentStage;

  @override
  Future<void> startVpn({
    required String serverAddress,
    required String wgQuickConfig,
    required String providerBundleIdentifier,
  }) async {
    started = true;
    currentStage = 'connecting';
    _stages.add('connecting');
    scheduleMicrotask(() {
      currentStage = 'connected';
      _stages.add('connected');
    });
  }

  @override
  Future<void> stopVpn() async {
    started = false;
    currentStage = 'disconnected';
    _stages.add('disconnected');
  }

  void emitTraffic(Map<String, dynamic> event) {
    _traffic.add(event);
  }

  void emitStage(String stage) {
    currentStage = stage;
    _stages.add(stage);
  }
}

Future<void> _waitUntil(
  bool Function() satisfied, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (satisfied()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition not met within $timeout');
}

void main() {
  group('VpnController', () {
    test('connect fetches config, starts tunnel, becomes connected', () async {
      final tunnel = _FakeTunnel();
      const dto = WireGuardConfigDto(
        location: 'Finland',
        peerId: 'p1',
        address: '10.0.0.2',
        publicKey: 'pub',
        config: _sampleIni,
      );
      final container = ProviderContainer(
        overrides: _vpnControllerTestOverrides([
          authControllerProvider.overrideWith(_SignedInAuth.new),
          vpnTunnelAdapterProvider.overrideWithValue(tunnel),
          wgConfigStoreProvider.overrideWithValue(_MemoryWgStore()),
          wireGuardApiProvider.overrideWithValue(
            const _FakeWireGuardApi(dto: dto),
          ),
        ]),
      );
      addTearDown(container.dispose);

      container.read(vpnControllerProvider);
      await container.read(vpnControllerProvider.notifier).connect();
      await _waitUntil(
        () => container.read(vpnControllerProvider).phase == VpnPhase.connected,
      );
      expect(tunnel.started, isTrue);
    });

    test('connect without sign-in uses guest config and connects', () async {
      final tunnel = _FakeTunnel();
      final container = ProviderContainer(
        overrides: _vpnControllerTestOverrides([
          authControllerProvider.overrideWith(_SignedOutAuth.new),
          vpnTunnelAdapterProvider.overrideWithValue(tunnel),
          wgConfigStoreProvider.overrideWithValue(_MemoryWgStore()),
          guestDeviceStoreProvider.overrideWithValue(
            const _FakeGuestDeviceStore('guest-dev-1'),
          ),
          wireGuardApiProvider.overrideWithValue(
            const _FakeWireGuardApi(
              guestDto: WireGuardConfigDto(
                location: 'Finland',
                peerId: 'guest-peer',
                address: '10.0.0.2',
                publicKey: 'pub',
                config: _sampleIni,
              ),
            ),
          ),
        ]),
      );
      addTearDown(container.dispose);

      container.read(vpnControllerProvider);
      await container.read(vpnControllerProvider.notifier).connect();
      await _waitUntil(
        () => container.read(vpnControllerProvider).phase == VpnPhase.connected,
      );
      expect(tunnel.started, isTrue);
    });

    test('connect maps 409 to error message', () async {
      final tunnel = _FakeTunnel();
      final container = ProviderContainer(
        overrides: _vpnControllerTestOverrides([
          authControllerProvider.overrideWith(_SignedInAuth.new),
          vpnTunnelAdapterProvider.overrideWithValue(tunnel),
          wgConfigStoreProvider.overrideWithValue(_MemoryWgStore()),
          wireGuardApiProvider.overrideWithValue(
            _FakeWireGuardApi(
              error: DioException(
                requestOptions: RequestOptions(path: '/wireguard/config'),
                response: Response(
                  requestOptions: RequestOptions(path: '/wireguard/config'),
                  statusCode: 409,
                  data: <String, dynamic>{'message': 'Already provisioned'},
                ),
              ),
            ),
          ),
        ]),
      );
      addTearDown(container.dispose);

      container.read(vpnControllerProvider);
      await container.read(vpnControllerProvider.notifier).connect();
      final s = container.read(vpnControllerProvider);
      expect(s.phase, VpnPhase.error);
      expect(s.message, 'Already provisioned');
    });

    test('unsupported platform sets error', () async {
      final container = ProviderContainer(
        overrides: _vpnControllerTestOverrides([
          authControllerProvider.overrideWith(_SignedInAuth.new),
          vpnTunnelAdapterProvider.overrideWithValue(StubVpnTunnelAdapter()),
          wgConfigStoreProvider.overrideWithValue(_MemoryWgStore()),
          wireGuardApiProvider.overrideWithValue(
            const _FakeWireGuardApi(
              dto: WireGuardConfigDto(
                location: 'Finland',
                peerId: 'p1',
                address: '10.0.0.2',
                publicKey: 'pub',
                config: _sampleIni,
              ),
            ),
          ),
        ]),
      );
      addTearDown(container.dispose);

      container.read(vpnControllerProvider);
      await container.read(vpnControllerProvider.notifier).connect();
      final s = container.read(vpnControllerProvider);
      expect(s.phase, VpnPhase.error);
      expect(s.message, contains('not available'));
    });

    test('connected traffic stream updates vpn stats', () async {
      final tunnel = _FakeTunnel();
      const dto = WireGuardConfigDto(
        location: 'Finland',
        peerId: 'p1',
        address: '10.0.0.2',
        publicKey: 'pub',
        config: _sampleIni,
      );
      final container = ProviderContainer(
        overrides: _vpnControllerTestOverrides([
          authControllerProvider.overrideWith(_SignedInAuth.new),
          vpnTunnelAdapterProvider.overrideWithValue(tunnel),
          wgConfigStoreProvider.overrideWithValue(_MemoryWgStore()),
          wireGuardApiProvider.overrideWithValue(
            const _FakeWireGuardApi(dto: dto),
          ),
        ]),
      );
      addTearDown(container.dispose);

      container.read(vpnControllerProvider);
      await container.read(vpnControllerProvider.notifier).connect();
      await _waitUntil(
        () => container.read(vpnControllerProvider).phase == VpnPhase.connected,
      );

      tunnel.emitTraffic({
        'totalDownload': 2048,
        'totalUpload': 1024,
        'downloadSpeed': 256.0,
        'uploadSpeed': 128.0,
        'duration': '00:03:30',
      });
      await _waitUntil(
        () => container.read(vpnControllerProvider).stats != null,
      );
      final stats = container.read(vpnControllerProvider).stats;
      expect(stats?.totalDownloadBytes, 2048);
      expect(stats?.totalUploadBytes, 1024);
      expect(stats?.uptime, const Duration(minutes: 3, seconds: 30));
    });

    test('revoked tunnel updates state to disconnected', () async {
      final tunnel = _FakeTunnel();
      const dto = WireGuardConfigDto(
        location: 'Finland',
        peerId: 'p1',
        address: '10.0.0.2',
        publicKey: 'pub',
        config: _sampleIni,
      );
      final container = ProviderContainer(
        overrides: _vpnControllerTestOverrides([
          authControllerProvider.overrideWith(_SignedInAuth.new),
          vpnTunnelAdapterProvider.overrideWithValue(tunnel),
          wgConfigStoreProvider.overrideWithValue(_MemoryWgStore()),
          wireGuardApiProvider.overrideWithValue(
            const _FakeWireGuardApi(dto: dto),
          ),
        ]),
      );
      addTearDown(container.dispose);

      container.read(vpnControllerProvider);
      await container.read(vpnControllerProvider.notifier).connect();
      await _waitUntil(
        () => container.read(vpnControllerProvider).phase == VpnPhase.connected,
      );
      tunnel.emitStage('disconnected');
      await _waitUntil(
        () =>
            container.read(vpnControllerProvider).phase == VpnPhase.disconnected,
      );
      expect(container.read(vpnControllerProvider).stats, isNull);
    });

    test('resume refresh reflects current connected stage', () async {
      final tunnel = _FakeTunnel()..currentStage = 'connected';
      final container = ProviderContainer(
        overrides: _vpnControllerTestOverrides([
          authControllerProvider.overrideWith(_SignedInAuth.new),
          vpnTunnelAdapterProvider.overrideWithValue(tunnel),
          wgConfigStoreProvider.overrideWithValue(_MemoryWgStore()),
          wireGuardApiProvider.overrideWithValue(
            const _FakeWireGuardApi(
              dto: WireGuardConfigDto(
                location: 'Finland',
                peerId: 'p1',
                address: '10.0.0.2',
                publicKey: 'pub',
                config: _sampleIni,
              ),
            ),
          ),
        ]),
      );
      addTearDown(container.dispose);

      container.read(vpnControllerProvider);
      await container.read(vpnControllerProvider.notifier).onAppResumed();
      expect(container.read(vpnControllerProvider).phase, VpnPhase.connected);
    });
  });
}

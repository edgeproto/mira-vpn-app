import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../api/api_exception.dart';
import '../providers/dependency_providers.dart';
import 'wg_quick_config.dart';

/// High-level VPN lifecycle for the Home screen.
enum VpnPhase {
  disconnected,
  preparing,
  connecting,
  connected,
  error,
}

@immutable
class VpnTrafficStats {
  const VpnTrafficStats({
    required this.totalDownloadBytes,
    required this.totalUploadBytes,
    required this.downloadSpeedBps,
    required this.uploadSpeedBps,
    required this.uptime,
  });

  final int totalDownloadBytes;
  final int totalUploadBytes;
  final double downloadSpeedBps;
  final double uploadSpeedBps;
  final Duration uptime;
}

@immutable
class VpnState {
  const VpnState({
    this.phase = VpnPhase.disconnected,
    this.message,
    this.stats,
  });

  final VpnPhase phase;
  final String? message;
  final VpnTrafficStats? stats;

  VpnState copyWith({
    VpnPhase? phase,
    String? message,
    VpnTrafficStats? stats,
    bool clearStats = false,
    bool clearMessage = false,
  }) {
    return VpnState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
      stats: clearStats ? null : (stats ?? this.stats),
    );
  }
}

class VpnController extends Notifier<VpnState> {
  static const _bundleId = 'com.mira.mira_vpn_app.WGExtension';
  static const _initializeTimeout = Duration(seconds: 20);
  static const _firstStartTimeout = Duration(seconds: 45);
  static const _startTimeout = Duration(seconds: 20);

  StreamSubscription<String>? _stageSub;
  StreamSubscription<Map<String, dynamic>>? _trafficSub;
  bool _tunnelInitialized = false;
  bool _listening = false;
  bool _autoRetried = false;

  @override
  VpnState build() {
    ref.onDispose(() {
      _stageSub?.cancel();
      _trafficSub?.cancel();
      _stageSub = null;
      _trafficSub = null;
      _listening = false;
    });

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      final wasIn = prev?.isSignedIn ?? false;
      final isIn = next.isSignedIn;
      if (wasIn && !isIn && prev?.user != null) {
        unawaited(_onSignedOut(prev!.user!.id));
      }
    });

    final adapter = ref.read(vpnTunnelAdapterProvider);
    if (adapter.supported && !_listening) {
      _listening = true;
      _stageSub = adapter.stageEvents.listen(_onTunnelStage);
      _trafficSub = adapter.trafficEvents.listen(
        _onTrafficEvent,
        onError: (_, __) {
          // Some platforms emit traffic stream errors before tunnel init.
        },
      );
    }

    return const VpnState();
  }

  void _onTunnelStage(String name) {
    if (state.phase == VpnPhase.preparing) {
      if (name == 'disconnected' ||
          name == 'disconnecting' ||
          name == 'exiting' ||
          name == 'noConnection') {
        return;
      }
    }

    switch (name) {
      case 'connected':
        _autoRetried = false;
        state = state.copyWith(
          phase: VpnPhase.connected,
          clearMessage: true,
        );
        break;
      case 'denied':
        state = const VpnState(
          phase: VpnPhase.error,
          message: 'VPN permission was denied',
        );
        break;
      case 'connecting':
      case 'preparing':
      case 'waitingConnection':
      case 'authenticating':
      case 'reconnect':
        if (state.phase != VpnPhase.error) {
          state = state.copyWith(phase: VpnPhase.connecting, clearMessage: true);
        }
        break;
      case 'disconnected':
      case 'disconnecting':
      case 'exiting':
      case 'noConnection':
        if (state.phase == VpnPhase.preparing || state.phase == VpnPhase.connecting) {
          if (!_autoRetried) {
            _autoRetried = true;
            unawaited(_retryConnectOnce());
          } else {
            state = const VpnState(
              phase: VpnPhase.error,
              message: 'Connection dropped. Tap Retry to reconnect.',
            );
          }
        } else if (state.phase == VpnPhase.connected) {
          state = const VpnState(phase: VpnPhase.disconnected);
        } else if (state.phase == VpnPhase.error) {
          return;
        } else {
          state = const VpnState(phase: VpnPhase.disconnected);
        }
        break;
      default:
        break;
    }
  }

  void _onTrafficEvent(Map<String, dynamic> event) {
    if (state.phase != VpnPhase.connected) {
      return;
    }
    state = state.copyWith(
      stats: VpnTrafficStats(
        totalDownloadBytes: _toInt(event['totalDownload']),
        totalUploadBytes: _toInt(event['totalUpload']),
        downloadSpeedBps: _toDouble(event['downloadSpeed']),
        uploadSpeedBps: _toDouble(event['uploadSpeed']),
        uptime: _parseDuration(event['duration']),
      ),
    );
  }

  Future<void> _onSignedOut(String userId) async {
    final adapter = ref.read(vpnTunnelAdapterProvider);
    if (adapter.supported) {
      try {
        await adapter.stopVpn();
      } catch (_) {}
    }
    await ref.read(wgConfigStoreProvider).delete(userId);
    state = const VpnState(phase: VpnPhase.disconnected);
  }

  Future<void> _retryConnectOnce() async {
    state = const VpnState(phase: VpnPhase.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _connectInternal(isAutoRetry: true);
  }

  /// Connect when disconnected or retry after error; disconnect when connected.
  Future<void> onCirclePressed() async {
    switch (state.phase) {
      case VpnPhase.connected:
        await disconnect();
        break;
      case VpnPhase.disconnected:
      case VpnPhase.error:
        await connect();
        break;
      case VpnPhase.preparing:
      case VpnPhase.connecting:
        break;
    }
  }

  Future<void> connect() async {
    _autoRetried = false;
    await _connectInternal(isAutoRetry: false);
  }

  Future<void> _connectInternal({required bool isAutoRetry}) async {
    final auth = ref.read(authControllerProvider);
    final adapter = ref.read(vpnTunnelAdapterProvider);
    if (!adapter.supported) {
      state = const VpnState(
        phase: VpnPhase.error,
        message: 'VPN is not available on this platform',
      );
      return;
    }

    final userId = auth.user?.id ?? 'guest';
    state = const VpnState(phase: VpnPhase.preparing);
    final isFirstTunnelStart = !_tunnelInitialized;

    try {
      final store = ref.read(wgConfigStoreProvider);
      final api = ref.read(wireGuardApiProvider);
      final cached = await store.read(userId);
      late final String config;
      try {
        final dto = auth.isSignedIn
            ? await api.createConfig()
            : await api.createGuestConfig(
                deviceId:
                    await ref.read(guestDeviceStoreProvider).readOrCreateDeviceId(),
              );
        config = dto.config;
        await store.write(userId, config);
      } on DioException catch (e) {
        if (cached != null &&
            cached.isNotEmpty &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionError)) {
          config = cached;
        } else {
          rethrow;
        }
      }

      state = const VpnState(phase: VpnPhase.connecting);

      if (!_tunnelInitialized) {
        await adapter.initialize(
          interfaceName: 'wg_mira',
          vpnName: 'Mira VPN',
        ).timeout(_initializeTimeout);
        _tunnelInitialized = true;
      }

      final endpoint =
          parseWireGuardEndpoint(config) ?? '127.0.0.1:51820';

      await adapter.startVpn(
        serverAddress: endpoint,
        wgQuickConfig: config,
        providerBundleIdentifier: _bundleId,
      ).timeout(isFirstTunnelStart ? _firstStartTimeout : _startTimeout);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final api = ApiException.fromDio(e);
      final msg = code == 409
          ? (api?.message ?? 'You already have an active VPN configuration.')
          : (api?.message ?? 'Could not create VPN configuration.');
      state = VpnState(phase: VpnPhase.error, message: msg);
    } catch (e) {
      final message = e.toString();
      if (e is TimeoutException) {
        state = VpnState(
          phase: VpnPhase.error,
          message:
              isFirstTunnelStart
                  ? 'VPN startup is taking longer than expected on first run. Tap Retry.'
                  : 'VPN startup timed out. Tap Retry.',
        );
        return;
      }
      if (_isBadConfigError(message) && !_autoRetried) {
        _autoRetried = true;
        await ref.read(wgConfigStoreProvider).delete(userId);
        await _connectInternal(isAutoRetry: true);
        return;
      }
      if (_isTransientError(message) && !_autoRetried && !isAutoRetry) {
        _autoRetried = true;
        unawaited(_retryConnectOnce());
        return;
      }
      if (_isBadConfigError(message)) {
        state = const VpnState(
          phase: VpnPhase.error,
          message:
              'Invalid VPN profile received from server. Please reconnect to fetch a fresh profile.',
        );
        return;
      }
      state = VpnState(phase: VpnPhase.error, message: message);
    }
  }

  Future<void> disconnect() async {
    final adapter = ref.read(vpnTunnelAdapterProvider);
    if (!adapter.supported) {
      state = const VpnState(phase: VpnPhase.disconnected);
      return;
    }
    try {
      await adapter.stopVpn();
      state = const VpnState(phase: VpnPhase.disconnected);
    } catch (e) {
      state = VpnState(phase: VpnPhase.error, message: e.toString());
    }
  }

  Future<void> onAppResumed() async {
    final adapter = ref.read(vpnTunnelAdapterProvider);
    if (!adapter.supported) {
      return;
    }
    try {
      await adapter.refreshStage();
      final stage = await adapter.stage();
      _onTunnelStage(stage);
    } catch (_) {
      // Ignore best-effort status refresh errors when resuming.
    }
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Duration _parseDuration(Object? value) {
    final raw = value?.toString() ?? '';
    final parts = raw.split(':');
    if (parts.length != 3) return Duration.zero;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  static bool _isTransientError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('socket') ||
        lower.contains('network');
  }

  static bool _isBadConfigError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('badconfigexception') ||
        lower.contains('can\'t connect to tunnel') ||
        lower.contains('invalid wg-quick config');
  }

  @visibleForTesting
  void debugSetStateForTest(VpnState value) {
    state = value;
  }
}

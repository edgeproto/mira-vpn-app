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
class VpnState {
  const VpnState({
    this.phase = VpnPhase.disconnected,
    this.message,
  });

  final VpnPhase phase;
  final String? message;

  VpnState copyWith({
    VpnPhase? phase,
    String? message,
    bool clearMessage = false,
  }) {
    return VpnState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class VpnController extends Notifier<VpnState> {
  static const _bundleId = 'com.mira.mira_vpn_app.WGExtension';

  StreamSubscription<String>? _stageSub;
  bool _tunnelInitialized = false;
  bool _listening = false;

  @override
  VpnState build() {
    ref.onDispose(() {
      _stageSub?.cancel();
      _stageSub = null;
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
        state = const VpnState(phase: VpnPhase.connected);
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
        if (state.phase == VpnPhase.connected ||
            state.phase == VpnPhase.connecting) {
          state = const VpnState(phase: VpnPhase.disconnected);
        }
        break;
      default:
        break;
    }
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
    final auth = ref.read(authControllerProvider);
    if (!auth.isSignedIn) {
      state = const VpnState(
        phase: VpnPhase.error,
        message: 'Sign in to connect',
      );
      return;
    }

    final adapter = ref.read(vpnTunnelAdapterProvider);
    if (!adapter.supported) {
      state = const VpnState(
        phase: VpnPhase.error,
        message: 'VPN is not available on this platform',
      );
      return;
    }

    final userId = auth.user!.id;
    state = const VpnState(phase: VpnPhase.preparing);

    try {
      final store = ref.read(wgConfigStoreProvider);
      final api = ref.read(wireGuardApiProvider);
      var config = await store.read(userId);
      if (config == null || config.isEmpty) {
        final dto = await api.createConfig();
        config = dto.config;
        await store.write(userId, config);
      }

      state = const VpnState(phase: VpnPhase.connecting);

      if (!_tunnelInitialized) {
        await adapter.initialize(
          interfaceName: 'wg_mira',
          vpnName: 'Mira VPN',
        );
        _tunnelInitialized = true;
      }

      final endpoint =
          parseWireGuardEndpoint(config) ?? '127.0.0.1:51820';

      await adapter.startVpn(
        serverAddress: endpoint,
        wgQuickConfig: config,
        providerBundleIdentifier: _bundleId,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final api = ApiException.fromDio(e);
      final msg = code == 409
          ? (api?.message ?? 'You already have an active VPN configuration.')
          : (api?.message ?? 'Could not create VPN configuration.');
      state = VpnState(phase: VpnPhase.error, message: msg);
    } catch (e) {
      state = VpnState(phase: VpnPhase.error, message: e.toString());
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

  @visibleForTesting
  void debugSetStateForTest(VpnState value) {
    state = value;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/auth_controller.dart';
import '../api/models/wireguard_location_dto.dart';
import '../providers/dependency_providers.dart';

@immutable
class VpnLocationState {
  const VpnLocationState({
    required this.locations,
    required this.selectedName,
  });

  final List<WireguardLocationDto> locations;
  final String selectedName;

  String get displayLabel {
    for (final WireguardLocationDto loc in locations) {
      if (loc.name == selectedName) {
        return loc.displayName;
      }
    }
    return selectedName;
  }
}

class VpnLocationController extends AsyncNotifier<VpnLocationState> {
  static const _prefKey = 'vpn_selected_location_name';

  @override
  Future<VpnLocationState> build() async {
    final api = ref.read(wireGuardApiProvider);
    final prefs = await SharedPreferences.getInstance();

    List<WireguardLocationDto> locations;
    try {
      locations = await api.listLocations();
    } catch (_) {
      locations = const [
        WireguardLocationDto(name: 'Finland', displayName: 'Finland'),
      ];
    }
    if (locations.isEmpty) {
      locations = const [
        WireguardLocationDto(name: 'Finland', displayName: 'Finland'),
      ];
    }

    var selected = prefs.getString(_prefKey);
    final validNames = locations.map((WireguardLocationDto e) => e.name).toSet();
    if (selected == null || !validNames.contains(selected)) {
      selected = locations.first.name;
      await prefs.setString(_prefKey, selected);
    }

    return VpnLocationState(locations: locations, selectedName: selected);
  }

  Future<void> selectLocation(String canonicalName) async {
    final current = state;
    if (!current.hasValue) {
      return;
    }
    final cur = current.requireValue;
    if (!cur.locations.any((WireguardLocationDto e) => e.name == canonicalName)) {
      return;
    }
    if (canonicalName == cur.selectedName) {
      return;
    }
    await _clearStoredWireGuardConfig();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, canonicalName);
    state = AsyncData(
      VpnLocationState(locations: cur.locations, selectedName: canonicalName),
    );
  }

  /// Discards the cached API-generated profile so the next connect fetches a
  /// config for the newly selected region (avoids reusing another location's
  /// tunnel on transient network errors).
  Future<void> _clearStoredWireGuardConfig() async {
    final auth = ref.read(authControllerProvider);
    final userId = auth.user?.id ?? 'guest';
    await ref.read(wgConfigStoreProvider).delete(userId);
  }

  /// Reload locations from the API (e.g. after sign-in). Keeps selection when
  /// still valid; [build] reconciles prefs if the list changed.
  void refresh() {
    ref.invalidateSelf();
  }
}

final vpnLocationControllerProvider =
    AsyncNotifierProvider<VpnLocationController, VpnLocationState>(
  VpnLocationController.new,
);

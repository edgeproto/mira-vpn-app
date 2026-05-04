import 'package:dio/dio.dart';

import 'models/wireguard_config_dto.dart';
import 'models/wireguard_location_dto.dart';

class WireGuardApi {
  WireGuardApi(this._dio);

  final Dio _dio;

  Future<List<WireguardLocationDto>> listLocations() async {
    final res = await _dio.get<Map<String, dynamic>>('/wireguard/locations');
    final raw = res.data!['locations'] as List<dynamic>;
    return raw
        .map(
          (e) => WireguardLocationDto.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<WireGuardConfigDto> createConfig({required String location}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/wireguard/config',
      data: <String, dynamic>{'location': location},
    );
    return WireGuardConfigDto.fromJson(res.data!);
  }

  Future<WireGuardConfigDto> createGuestConfig({
    required String deviceId,
    required String location,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/wireguard/config/guest',
      data: <String, dynamic>{
        'deviceId': deviceId,
        'location': location,
      },
    );
    return WireGuardConfigDto.fromJson(res.data!);
  }
}

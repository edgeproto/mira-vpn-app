import 'package:dio/dio.dart';

import 'models/wireguard_config_dto.dart';

class WireGuardApi {
  WireGuardApi(this._dio);

  final Dio _dio;

  Future<WireGuardConfigDto> createConfig({String location = 'Finland'}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/wireguard/config',
      data: <String, dynamic>{'location': location},
    );
    return WireGuardConfigDto.fromJson(res.data!);
  }

  Future<WireGuardConfigDto> createGuestConfig({
    required String deviceId,
    String location = 'Finland',
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

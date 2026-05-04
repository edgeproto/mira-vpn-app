import 'package:flutter/foundation.dart';

@immutable
class WireguardLocationDto {
  const WireguardLocationDto({
    required this.name,
    required this.displayName,
    this.country,
    this.latencyHint,
    this.flagCode,
  });

  factory WireguardLocationDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final rawDisplay = json['displayName'] as String?;
    final display = rawDisplay?.trim();
    return WireguardLocationDto(
      name: name,
      displayName: (display != null && display.isNotEmpty) ? display : name,
      country: json['country'] as String?,
      latencyHint: json['latencyHint'] as String?,
      flagCode: json['flagCode'] as String?,
    );
  }

  final String name;
  final String displayName;
  final String? country;
  final String? latencyHint;
  final String? flagCode;
}

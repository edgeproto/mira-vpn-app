class WireGuardConfigDto {
  const WireGuardConfigDto({
    required this.location,
    required this.peerId,
    required this.address,
    required this.publicKey,
    required this.config,
  });

  final String location;
  final String peerId;
  final String address;
  final String publicKey;
  final String config;

  factory WireGuardConfigDto.fromJson(Map<String, dynamic> json) {
    return WireGuardConfigDto(
      location: json['location'] as String,
      peerId: json['peerId'] as String,
      address: json['address'] as String,
      publicKey: json['publicKey'] as String,
      config: json['config'] as String,
    );
  }
}

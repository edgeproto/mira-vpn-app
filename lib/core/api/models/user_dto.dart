class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.isPro,
    required this.createdAt,
  });

  final String id;
  final String email;
  final bool isPro;
  final DateTime createdAt;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      isPro: json['isPro'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

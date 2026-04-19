import 'user_dto.dart';

class AuthResponseDto {
  const AuthResponseDto({
    required this.token,
    required this.user,
  });

  final String token;
  final UserDto user;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

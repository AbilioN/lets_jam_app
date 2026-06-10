import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.avatarUrl,
    super.channel,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      channel: json['channel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (channel != null) 'channel': channel,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      channel: user.channel,
    );
  }

  static UserModel fromApiResponse(Map<String, dynamic> response) {
    final userData = response['user'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  static UserModel fromProfileResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return UserModel(
      id: data['id'].toString(),
      email: data['email'] as String,
      name: data['name'] as String,
      avatarUrl: data['avatar_url'] as String?,
      channel: data['channel'] as String?,
    );
  }

  static String? extractToken(Map<String, dynamic> response) {
    return response['token'] as String?;
  }

  static String? extractMessage(Map<String, dynamic> response) {
    return response['message'] as String?;
  }
} 
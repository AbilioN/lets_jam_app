import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  // Personal Pusher channel name e.g. "user.user.42" (without "private-" prefix)
  final String? channel;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.channel,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, channel];
} 
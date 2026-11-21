import 'package:equatable/equatable.dart';
import '../domain/app_user.dart';

abstract class UsersEvent extends Equatable {
  const UsersEvent();
  @override
  List<Object?> get props => [];
}

class UsersRequested extends UsersEvent {
  const UsersRequested();
}

class UsersRoleFilterChanged extends UsersEvent {
  final UserRole? role;
  const UsersRoleFilterChanged(this.role);

  @override
  List<Object?> get props => [role];
}

class UsersSearchChanged extends UsersEvent {
  final String search;
  const UsersSearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

class UserCreated extends UsersEvent {
  final String username;
  final String fullName;
  final String password;
  final String? phone;
  final UserRole role;
  final void Function(String? error) onComplete;

  const UserCreated({
    required this.username,
    required this.fullName,
    required this.password,
    required this.phone,
    required this.role,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [username, fullName, role];
}

class UserDetailsUpdated extends UsersEvent {
  final String userId;
  final String fullName;
  final String? phone;
  final void Function(String? error) onComplete;

  const UserDetailsUpdated({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.onComplete,
  });

  @override
  List<Object?> get props => [userId, fullName, phone];
}

class UserActiveToggled extends UsersEvent {
  final String userId;
  final bool isActive;
  final void Function(String? error) onComplete;

  const UserActiveToggled(this.userId, this.isActive, this.onComplete);

  @override
  List<Object?> get props => [userId, isActive];
}

class UserTokenRegenerated extends UsersEvent {
  final String userId;
  final void Function(String? newToken, String? error) onComplete;

  const UserTokenRegenerated(this.userId, this.onComplete);

  @override
  List<Object?> get props => [userId];
}

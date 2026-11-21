import 'package:equatable/equatable.dart';
import '../domain/app_user.dart';

abstract class UsersState extends Equatable {
  const UsersState();
  @override
  List<Object?> get props => [];
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  final List<AppUser> users;
  final UserRole? activeRoleFilter;
  final String searchTerm;

  const UsersLoaded(
    this.users, {
    this.activeRoleFilter,
    this.searchTerm = '',
  });

  @override
  List<Object?> get props => [users, activeRoleFilter, searchTerm];
}

class UsersError extends UsersState {
  final String message;
  const UsersError(this.message);

  @override
  List<Object?> get props => [message];
}

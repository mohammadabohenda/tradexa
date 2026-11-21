import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/users_repository.dart';
import '../domain/app_user.dart';
import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _repository;
  UserRole? _roleFilter;
  String _search = '';

  UsersBloc(this._repository) : super(const UsersLoading()) {
    on<UsersRequested>(_onRequested);
    on<UsersRoleFilterChanged>(_onRoleFilterChanged);
    on<UsersSearchChanged>(_onSearchChanged);
    on<UserCreated>(_onCreated);
    on<UserDetailsUpdated>(_onDetailsUpdated);
    on<UserActiveToggled>(_onActiveToggled);
    on<UserTokenRegenerated>(_onTokenRegenerated);

    add(const UsersRequested());
  }

  Future<void> _onRequested(UsersRequested event, Emitter<UsersState> emit) async {
    emit(const UsersLoading());
    try {
      final list = await _repository.fetchAll(role: _roleFilter, search: _search);
      emit(UsersLoaded(list, activeRoleFilter: _roleFilter, searchTerm: _search));
    } catch (_) {
      emit(const UsersError('تعذّر تحميل المستخدمين، تحقق من الاتصال'));
    }
  }

  Future<void> _onRoleFilterChanged(
    UsersRoleFilterChanged event,
    Emitter<UsersState> emit,
  ) async {
    _roleFilter = event.role;
    await _onRequested(const UsersRequested(), emit);
  }

  Future<void> _onSearchChanged(
    UsersSearchChanged event,
    Emitter<UsersState> emit,
  ) async {
    _search = event.search;
    await _onRequested(const UsersRequested(), emit);
  }

  Future<void> _onCreated(UserCreated event, Emitter<UsersState> emit) async {
    try {
      await _repository.createUser(
        username: event.username,
        fullName: event.fullName,
        password: event.password,
        phone: event.phone,
        role: event.role,
      );
      event.onComplete(null);
      await _onRequested(const UsersRequested(), emit);
    } on UserOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onDetailsUpdated(
    UserDetailsUpdated event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await _repository.updateDetails(
        event.userId,
        fullName: event.fullName,
        phone: event.phone,
      );
      event.onComplete(null);
      await _onRequested(const UsersRequested(), emit);
    } on UserOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onActiveToggled(
    UserActiveToggled event,
    Emitter<UsersState> emit,
  ) async {
    try {
      await _repository.setActive(event.userId, event.isActive);
      event.onComplete(null);
      await _onRequested(const UsersRequested(), emit);
    } on UserOperationException catch (e) {
      event.onComplete(e.message);
    }
  }

  Future<void> _onTokenRegenerated(
    UserTokenRegenerated event,
    Emitter<UsersState> emit,
  ) async {
    try {
      final token = await _repository.regenerateToken(event.userId);
      event.onComplete(token, null);
      await _onRequested(const UsersRequested(), emit);
    } on UserOperationException catch (e) {
      event.onComplete(null, e.message);
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthError('Failed to check authentication status'));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final success = await _authService.login(event.username, event.password);
      if (success) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthError('Failed to get user data'));
        }
      } else {
        emit(const AuthError('Invalid username or password'));
      }
    } catch (e) {
      emit(const AuthError('Login failed. Please try again.'));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final success = await _authService.register(
        event.name,
        event.username,
        event.password,
        event.age,
        event.country,
      );
      if (success) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthError('Failed to get user data'));
        }
      } else {
        emit(const AuthError('Username already exists'));
      }
    } catch (e) {
      emit(const AuthError('Registration failed. Please try again.'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('Logout failed'));
    }
  }

  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final success = await _authService.updateProfile(
        event.name,
        event.username,
        event.age,
        event.country,
      );
      if (success) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          emit(AuthProfileUpdateSuccess(user, 'Profile updated successfully!'));
        } else {
          emit(const AuthError('Failed to get updated user data'));
        }
      } else {
        emit(const AuthError('Failed to update profile'));
      }
    } catch (e) {
      emit(const AuthError('Profile update failed. Please try again.'));
    }
  }
}

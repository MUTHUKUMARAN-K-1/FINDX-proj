import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:frontend/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for managing Firebase authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(const AuthInitial()) {
    // Register event handlers
    on<AuthStarted>(_onAuthStarted);
    on<_AuthStateChanged>(_onAuthStateChanged);
    on<AuthSignInWithEmail>(_onSignInWithEmail);
    on<AuthSignUpWithEmail>(_onSignUpWithEmail);
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthPasswordReset>(_onPasswordReset);
    on<AuthUpdateProfile>(_onUpdateProfile);
    on<AuthLoggedOut>(_onLoggedOut);
  }

  /// Initialize auth and listen to auth state changes
  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    emit(const AuthLoading());

    // Listen to Firebase auth state changes
    _authStateSubscription?.cancel();
    _authStateSubscription = _authService.authStateChanges.listen(
      (user) => add(_AuthStateChanged(user)),
    );
  }

  /// Handle auth state changes from Firebase
  void _onAuthStateChanged(_AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(const Unauthenticated());
    }
  }

  /// Sign in with email and password
  Future<void> _onSignInWithEmail(
    AuthSignInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      // Auth state will be updated via _AuthStateChanged
    } catch (e) {
      emit(AuthError(e.toString()));
      // Revert to unauthenticated after error
      emit(const Unauthenticated());
    }
  }

  /// Sign up with email and password
  Future<void> _onSignUpWithEmail(
    AuthSignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.signUpWithEmail(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      // Auth state will be updated via _AuthStateChanged
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Sign in anonymously (guest mode)
  Future<void> _onSignInAnonymously(
    AuthSignInAnonymously event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.signInAnonymously();
      // Auth state will be updated via _AuthStateChanged
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Sign in with Google
  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User cancelled
        emit(const Unauthenticated());
      }
      // Auth state will be updated via _AuthStateChanged if successful
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Send password reset email
  Future<void> _onPasswordReset(
    AuthPasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent(event.email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Update user profile
  Future<void> _onUpdateProfile(
    AuthUpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.updateProfile(
        displayName: event.displayName,
        photoUrl: event.photoUrl,
      );
      // Profile update will trigger auth state change
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign out
  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Get current user (convenience method)
  User? get currentUser => _authService.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _authService.isLoggedIn;

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

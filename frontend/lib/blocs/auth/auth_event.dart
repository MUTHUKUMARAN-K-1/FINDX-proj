part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

/// Initial auth check on app start
class AuthStarted extends AuthEvent {}

/// User logged in via any method
class AuthLoggedIn extends AuthEvent {}

/// User logged out
class AuthLoggedOut extends AuthEvent {}

/// Sign in with email and password
class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  AuthSignInWithEmail({required this.email, required this.password});
}

/// Sign up with email and password
class AuthSignUpWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  AuthSignUpWithEmail({
    required this.email,
    required this.password,
    this.displayName,
  });
}

/// Sign in anonymously (guest mode)
class AuthSignInAnonymously extends AuthEvent {}

/// Password reset request
class AuthPasswordReset extends AuthEvent {
  final String email;

  AuthPasswordReset({required this.email});
}

/// Sign in with Google
class AuthSignInWithGoogle extends AuthEvent {}

/// Update user profile
class AuthUpdateProfile extends AuthEvent {
  final String? displayName;
  final String? photoUrl;

  AuthUpdateProfile({this.displayName, this.photoUrl});
}

/// Auth state changed (from stream)
class _AuthStateChanged extends AuthEvent {
  final User? user;

  _AuthStateChanged(this.user);
}

part of 'auth_bloc.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

/// Initial state before auth check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth check in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  String? get displayName => user.displayName;
  String? get email => user.email;
  String? get photoUrl => user.photoURL;
  String get uid => user.uid;
  bool get isAnonymous => user.isAnonymous;
}

/// User is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Auth operation failed
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

/// Password reset email sent successfully
class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent(this.email);
}

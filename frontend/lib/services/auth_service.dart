import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:frontend/services/firestore_service.dart';

/// Service for Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of user changes (includes token refresh)
  Stream<User?> get userChanges => _auth.userChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile in Firestore
      if (credential.user != null) {
        await _firestoreService.saveUserProfile(
          uid: credential.user!.uid,
          email: credential.user!.email ?? email,
          displayName: credential.user!.displayName,
          photoUrl: credential.user!.photoURL,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Create user profile in Firestore
      if (credential.user != null) {
        await _firestoreService.saveUserProfile(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in anonymously (guest mode)
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      // Create anonymous user profile
      if (credential.user != null) {
        await _firestoreService.saveUserProfile(
          uid: credential.user!.uid,
          email: 'anonymous@findx.app',
          displayName: 'Guest User',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    // Google Sign-In is not supported on Windows/Linux/macOS desktop
    if (!_isGoogleSignInSupported()) {
      throw 'Google Sign-In is not supported on this platform. Please use email/password.';
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Get auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create/update user profile in Firestore
      if (userCredential.user != null) {
        await _firestoreService.saveUserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? googleUser.email,
          displayName:
              userCredential.user!.displayName ?? googleUser.displayName,
          photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google Sign-In failed: $e';
    }
  }

  /// Check if Google Sign-In is supported on this platform
  bool _isGoogleSignInSupported() {
    try {
      // Google Sign-In works on Android, iOS, and Web
      // It does NOT work on Windows, Linux, or macOS desktop
      return !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;
    } catch (e) {
      // On web, Platform is not available, but Google Sign-In works on web
      return true;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Update Firestore profile
    await _firestoreService.saveUserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName,
      photoUrl: photoUrl ?? user.photoURL,
    );
  }

  /// Update email
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

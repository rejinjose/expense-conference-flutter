import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider to access the FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// The StreamProvider that tracks the user's auth state
// It automatically returns AsyncValue<User?>
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Simplified provider for UI widgets to get basic user info
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// Provider to fetch the specific role from the token
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  // Force refresh the token to ensure we have the latest claims
  final idTokenResult = await user.getIdTokenResult(true);
  return idTokenResult.claims?['role'] as String?;
});

// A separate class for your login/signup/logout methods
class AuthService {
  final FirebaseAuth _auth;
  AuthService(this._auth);

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async => await _auth.signOut();

  // Call this after calling the 'addRole' cloud function to update the UI
  Future<void> refreshUserToken() async {
    await _auth.currentUser?.getIdToken(true);
  }
}

// Provider for the AuthService logic
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

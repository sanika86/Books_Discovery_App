import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._repo) : super(const AsyncValue.data(null));
  final AuthRepository _repo;

  Future<String?> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final u = await _repo.signUpWithEmail(email, password);
      state = AsyncValue.data(u);
      return null;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      return _mapFirebaseError(e);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return "Something went wrong";
    }
  }

  Future<String?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final u = await _repo.signInWithEmail(email, password);
      state = AsyncValue.data(u);
      return null;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      return _mapFirebaseError(e);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return "Something went wrong";
    }
  }

  Future<String?> googleSignIn() async {
    state = const AsyncValue.loading();
    try {
      final u = await _repo.signInWithGoogle();
      state = AsyncValue.data(u);
      return null;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      if (e.code == 'account-exists-with-different-credential') {
        // This means the user has registered with email/password
        // Prompt them to log in with email/password first, then link Google
        return "An account already exists with this email using a different sign-in method. Please log in with email and password first.";
      }
      return _mapFirebaseError(e);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return "Something went wrong";
    }
  }

  Future<void> signOut() => _repo.signOut();

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return "Email already in use";
      case 'invalid-email': return "Invalid email";
      case 'weak-password': return "Weak password (min 6 chars)";
      case 'user-not-found': return "User not found";
      case 'wrong-password': return "Wrong password";
      case 'network-request-failed': return "Network error";
      default: return e.message ?? "Auth error";
    }
  }
}

final authControllerProvider =
  StateNotifierProvider<AuthController, AsyncValue<User?>>(
    (ref) => AuthController(ref.watch(authRepositoryProvider)),
  );

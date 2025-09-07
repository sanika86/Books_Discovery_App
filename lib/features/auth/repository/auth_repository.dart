import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    return cred.user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    // NOTE: Google Sign-In ke liye Firebase console me Android ke SHA-1 add karo (debug + release)
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken, accessToken: googleAuth.accessToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // google_sign_in logout optional:
    try { await GoogleSignIn().signOut(); } catch (_) {}
  }
}

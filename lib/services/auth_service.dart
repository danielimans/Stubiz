import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<void> logout() => _auth.signOut();

  static Future<void> registerEmailPassword({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(displayName.trim());
    // Activation step: send verification link
    await cred.user!.sendEmailVerification();

    // Create user profile in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': cred.user!.email,
      'displayName': displayName.trim(),
      'role': 'student',
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> resendActivationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  static Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) return false;

    // Sync to Firestore
    await _db.collection('users').doc(refreshed.uid).set({
      'emailVerified': refreshed.emailVerified,
    }, SetOptions(merge: true));

    return refreshed.emailVerified;
  }

  static Future<void> loginEmailPassword({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Must verify email first
    if (!cred.user!.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Email not verified. Please activate your account via email.',
      );
    }

    final snap = await _db.collection('users').doc(cred.user!.uid).get();
    if (!snap.exists) {
      await _auth.signOut();
      throw Exception('User profile not found in Firestore.');
    }

    final role = (snap.data()!['role'] ?? '').toString();
    if (role != expectedRole) {
      await _auth.signOut();
      throw Exception('Role mismatch. Please select the correct login type.');
    }

    await _db.collection('users').doc(cred.user!.uid).set({
      'emailVerified': true,
    }, SetOptions(merge: true));
  }

  static Future<void> sendResetPasswordEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in.');
    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) throw Exception('User profile not found.');
    return (snap.data()!['role'] ?? '').toString();
  }
}

// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeplanner/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign up with email & password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();
        await _firestore.collection('Users').doc(user.uid).set({
          'displayName': '',
          'email': email.trim(),
          'createdAt': Timestamp.now(),
          'auth_type': 'Email',
        });
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign in with email & password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Google sign-in
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope(
          'https://www.googleapis.com/auth/contacts.readonly',
        );
        final credential = await _auth.signInWithPopup(googleProvider);
        return _handleGoogleUser(credential);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(cred);
        return _handleGoogleUser(userCredential);
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<User?> _handleGoogleUser(UserCredential userCredential) async {
    final user = userCredential.user;
    final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (user != null && isNew) {
      await _firestore.collection('Users').doc(user.uid).set({
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'createdAt': Timestamp.now(),
        'auth_type': 'Google',
      });
    }
    return user;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await NotificationService.instance.cancelAll(); // Add here
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }

  // Delete user account and Firestore data
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('Users').doc(user.uid).delete();
    await NotificationService.instance.cancelAll(); // Add here
    await user.delete();

    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }
}

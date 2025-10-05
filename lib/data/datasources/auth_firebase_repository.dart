import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pet_date/domain/entities/auth_user.dart';
import 'package:pet_date/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }
      debugPrint('Login exitoso para: $email');
      return AuthUser(id: user.uid, email: user.email);
    } catch (e) {
      debugPrint('Error en signInWithEmail: $e');
      rethrow;
    }
  }

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-created');
      }
      debugPrint('Registro exitoso para: $email');
      return AuthUser(id: user.uid, email: user.email);
    } catch (e) {
      debugPrint('Error en signUpWithEmail: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  AuthUser? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUser(id: user.uid, email: user.email);
  }
}

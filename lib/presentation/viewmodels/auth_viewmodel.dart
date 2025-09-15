import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/data/repositories/auth_repository.dart';

class AuthViewModel with ChangeNotifier {
  final AuthRepository authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel({required this.authRepository});
  bool _isLoading = false;
  User? _user;
  User? get user => _user;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _user = await authRepository.signInWithEmail(email, password);
      notifyListeners();
    } catch (e) {
      print('Error en signIn: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      _user = await authRepository.signUpWithEmail(email, password);
      notifyListeners();
    } catch (e) {
      print('Error en signUp: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    _user = null;
    notifyListeners();
  }

  void loadCurrentUser() {
    _user = authRepository.getCurrentUser();
    notifyListeners();
  }

  Future<void> addUserToFirestore(String name) async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set(
        {'email': _user!.email, 'uid': _user!.uid, 'name': name},
      );
    }
    notifyListeners();
  }
}

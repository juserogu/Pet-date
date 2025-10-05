import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/auth_user.dart';
import 'package:pet_date/domain/repositories/auth_repository.dart';

class AuthViewModel with ChangeNotifier {
  final AuthRepository authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel({required this.authRepository});
  bool _isLoading = false;
  AuthUser? _user;
  AuthUser? get user => _user;
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
      debugPrint('Error en signIn: $e');
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
      debugPrint('Error en signUp: $e');
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
    final current = _user;
    if (current != null) {
      await _firestore.collection('users').doc(current.id).set(
        {
          'id': current.id,
          'uid': current.id,
          'email': current.email,
          'name': name,
          // Campos básicos para la UI (con valores por defecto)
          'age': 'Not specified',
          'bio': '',
          'petName': 'Pet',
          'petType': 'Animal',
          'photoUrl': '',
          'photoUrls': <String>[],
          'matchesLastSeen': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    notifyListeners();
  }
}

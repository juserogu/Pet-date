import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> signUpWithEmail(String email, String password);
  Future<void> signOut();
  AuthUser? getCurrentUser();
}

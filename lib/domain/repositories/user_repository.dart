import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile> getUser(String id);
  Future<void> addUser(UserProfile user);
  Future<void> updateUser(String id, Map<String, dynamic> data);
}

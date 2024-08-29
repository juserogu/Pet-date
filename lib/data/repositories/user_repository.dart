import 'package:pet_date/domain/entities/user_pet.dart';

abstract class UserRepository {
  Future<UserPet> getUser(String id);
  Future<void> addUser(UserPet user);
}

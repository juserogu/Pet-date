import 'package:flutter/material.dart';
import 'package:pet_date/data/repositories/user_repository.dart';
import 'package:pet_date/domain/entities/user_pet.dart';

class UserViewModel with ChangeNotifier {
  final UserRepository userRepository;

  UserViewModel({required this.userRepository});

  UserPet? _user;
  UserPet? get user => _user;

  Future<void> fetchUser(String id) async {
    _user = await userRepository.getUser(id);
    notifyListeners();
  }
}

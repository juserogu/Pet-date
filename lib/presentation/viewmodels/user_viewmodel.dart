import 'package:flutter/material.dart';
import 'package:pet_date/domain/entities/user_profile.dart';
import 'package:pet_date/domain/repositories/user_repository.dart';

class UserViewModel with ChangeNotifier {
  final UserRepository userRepository;

  UserViewModel({required this.userRepository});

  UserProfile? _user;
  UserProfile? get user => _user;

  Future<void> fetchUser(String id) async {
    _user = await userRepository.getUser(id);
    notifyListeners();
  }
}

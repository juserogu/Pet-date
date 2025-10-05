import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/data/datasources/user_firebase_respository.dart';
import 'package:pet_date/main.dart';
import 'package:provider/provider.dart';

import '../viewmodels/user_viewmodel.dart';

class UserProvider extends StatelessWidget {
  const UserProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserViewModel(
          userRepository: FirebaseUserRepository(FirebaseFirestore.instance)),
      child: const MyApp(),
    );
  }
}

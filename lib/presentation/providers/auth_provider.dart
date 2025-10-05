import 'package:flutter/material.dart';
import 'package:pet_date/data/datasources/auth_firebase_repository.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends StatelessWidget {
  final Widget child;

  const AuthProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        authRepository: FirebaseAuthRepository(FirebaseAuth.instance),
      )..loadCurrentUser(),
      child: child,
    );
  }
}

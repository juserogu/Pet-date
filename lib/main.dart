import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/presentation/pages/home_page.dart';

import 'package:pet_date/presentation/pages/login_page.dart';
import 'package:pet_date/presentation/pages/register_page.dart';
import 'package:pet_date/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
        routes: {
          '/login': (context) => LoginPage(),
          '/home': (context) => HomePage(),
          '/register': (context) => RegisterPage()
        },
      ),
    );
  }
}

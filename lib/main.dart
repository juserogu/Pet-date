import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pet_date/firebase_options.dart';
import 'package:pet_date/presentation/pages/home_page.dart';
import 'package:pet_date/presentation/pages/login_page.dart';
import 'package:pet_date/presentation/pages/register_page.dart';
import 'package:pet_date/presentation/providers/auth_provider.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pet_date/presentation/pages/profile_page.dart';
import 'package:pet_date/presentation/pages/matches_page.dart';
import 'package:pet_date/presentation/pages/chat_page.dart';
import 'package:pet_date/presentation/viewmodels/home_viewmodel.dart';
import 'package:pet_date/data/datasources/interaction_firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_date/presentation/viewmodels/profile_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('Error al inicializar Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const RootPage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) {
            final auth = Provider.of<AuthViewModel>(context, listen: false);
            final uid = auth.user?.id;
            if (uid == null) {
              return const LoginPage();
            }
            return _HomeProvider(uid: uid);
          },
          '/register': (context) => const RegisterPage(),
          '/profile': (context) {
            final auth = Provider.of<AuthViewModel>(context, listen: false);
            final uid = auth.user?.id;
            if (uid == null) {
              return const LoginPage();
            }
            return ChangeNotifierProvider(
              create: (_) => ProfileViewModel(uid: uid)..load(),
              child: const ProfilePage(),
            );
          },
          '/matches': (context) => const MatchesPage(),
          '/chat': (context) => const ChatPage(),
        },
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final uid = auth.user?.id;
        if (uid != null) {
          return _HomeProvider(uid: uid);
        }
        return const LoginPage();
      },
    );
  }
}

class _HomeProvider extends StatelessWidget {
  final String uid;

  const _HomeProvider({required this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        currentUserId: uid,
        interactions: FirebaseInteractionRepository(FirebaseFirestore.instance),
        firestore: FirebaseFirestore.instance,
      ),
      child: const HomePage(),
    );
  }
}

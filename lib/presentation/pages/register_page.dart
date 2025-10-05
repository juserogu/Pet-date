import 'package:flutter/material.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:pet_date/presentation/widgets/dialogs.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController confirmPasswordController;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final bool isBusy = authViewModel.isLoading || _navigating;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AbsorbPointer(
        absorbing: isBusy,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Center(
                child: Image.asset(
                  'assets/logo_app.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: nameController,
                  enabled: !isBusy,
                  decoration: InputDecoration(
                    labelText: "Name",
                    prefixIcon:
                        const Icon(Icons.person, color: Colors.pinkAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isBusy,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon:
                        const Icon(Icons.email, color: Colors.pinkAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  enabled: !isBusy,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon:
                        const Icon(Icons.lock, color: Colors.pinkAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  enabled: !isBusy,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Colors.pinkAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          final ctx = context;
                          // Validaciones
                          if (nameController.text.trim().isEmpty) {
                            await showInfoDialog(
                              ctx,
                              title: 'Required Field',
                              message: 'Please enter your name',
                              icon: Icons.person,
                              color: Colors.red,
                            );
                            return;
                          }
                          if (emailController.text.trim().isEmpty) {
                            await showInfoDialog(
                              ctx,
                              title: 'Required Field',
                              message: 'Please enter your email',
                              icon: Icons.email,
                              color: Colors.red,
                            );
                            return;
                          }
                          if (!_isValidEmail(emailController.text.trim())) {
                            await showInfoDialog(
                              ctx,
                              title: 'Invalid Email',
                              message:
                                  'Please enter a valid email (example: user@email.com)',
                              icon: Icons.email,
                              color: Colors.red,
                            );
                            return;
                          }
                          if (passwordController.text.length < 6) {
                            await showInfoDialog(
                              ctx,
                              title: 'Password Too Short',
                              message: 'Password must be at least 6 characters',
                              icon: Icons.lock,
                              color: Colors.red,
                            );
                            return;
                          }
                          if (passwordController.text !=
                              confirmPasswordController.text) {
                            await showInfoDialog(
                              ctx,
                              title: 'Passwords do not match',
                              message: 'Please confirm your password',
                              icon: Icons.lock_outline,
                              color: Colors.red,
                            );
                            return;
                          }

                          final navigator = Navigator.of(ctx);
                          try {
                            FocusScope.of(ctx).unfocus();
                            await authViewModel.signUp(
                              emailController.text.trim(),
                              passwordController.text,
                            );
                            if (!ctx.mounted) return;

                            if (authViewModel.user != null) {
                              setState(() => _navigating = true);
                              await authViewModel.addUserToFirestore(
                                  nameController.text.trim());
                              if (!ctx.mounted) return;
                              navigator.pushReplacementNamed('/home');
                            }
                          } catch (e) {
                            if (!ctx.mounted) return;
                            await showInfoDialog(
                              ctx,
                              title: 'Registration Error',
                              message: 'Could not register. ${e.toString()}',
                              icon: Icons.error_outline,
                              color: Colors.red,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Center(
                    child: isBusy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.pinkAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

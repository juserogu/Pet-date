import 'package:flutter/material.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:pet_date/presentation/widgets/dialogs.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
                const SizedBox(height: 60),

                Center(
                  child: Image.asset(
                    'assets/logo_app.png',
                    height: 150,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "PetLove",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    controller: emailController,
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
                // BotÃ³n de inicio de sesiÃ³n
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final ctx = context;
                            // Validate empty fields
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

                            if (passwordController.text.trim().isEmpty) {
                              await showInfoDialog(
                                ctx,
                                title: 'Required Field',
                                message: 'Please enter your password',
                                icon: Icons.lock,
                                color: Colors.red,
                              );
                              return;
                            }

                            // Validate email format
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

                            // Validate password length
                            if (passwordController.text.length < 6) {
                              await showInfoDialog(
                                ctx,
                                title: 'Password Too Short',
                                message:
                                    'Password must be at least 6 characters long',
                                icon: Icons.lock,
                                color: Colors.red,
                              );
                              return;
                            }

                            final navigator = Navigator.of(ctx);
                            try {
                              FocusScope.of(context).unfocus();
                              await authViewModel.signIn(
                                emailController.text.trim(),
                                passwordController.text,
                              );

                              if (!ctx.mounted) return;

                              if (authViewModel.user != null) {
                                setState(() => _navigating = true);
                                navigator.pushReplacementNamed('/home');
                              }
                            } catch (e) {
                              String errorMessage = 'Connection Error';
                              IconData errorIcon = Icons.error;

                              if (e.toString().contains('user-not-found')) {
                                errorMessage = 'User not found';
                                errorIcon = Icons.person_off;
                              } else if (e
                                  .toString()
                                  .contains('wrong-password')) {
                                errorMessage = 'Incorrect password';
                                errorIcon = Icons.lock_outline;
                              } else if (e
                                  .toString()
                                  .contains('invalid-email')) {
                                errorMessage = 'Invalid email';
                                errorIcon = Icons.email_outlined;
                              } else if (e
                                  .toString()
                                  .contains('network-request-failed')) {
                                errorMessage = 'Internet connection error';
                                errorIcon = Icons.wifi_off;
                              } else if (e
                                  .toString()
                                  .contains('too-many-requests')) {
                                errorMessage =
                                    'Too many attempts. Try again later';
                                errorIcon = Icons.hourglass_empty;
                              } else if (e
                                  .toString()
                                  .contains('invalid-credential')) {
                                errorMessage = 'Invalid credentials';
                                errorIcon = Icons.warning;
                              }

                              if (!mounted) return;

                              await showInfoDialog(
                                ctx,
                                title: 'Authentication Error',
                                message: errorMessage,
                                icon: errorIcon,
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
                              "Login",
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
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
                const SizedBox(height: 40),

                Image.asset(
                  'assets/perros.jpg',
                  height: 150,
                ),
              ],
            ),
          ),
        ));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

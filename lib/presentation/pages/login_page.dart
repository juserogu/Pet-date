import 'package:flutter/material.dart';
import 'package:pet_date/presentation/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
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
                SizedBox(height: 60),

                Center(
                  child: Image.asset(
                    'assets/logo_app.png',
                    height: 150,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "PetLove",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    controller: emailController,
                    enabled: !isBusy,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email, color: Colors.pinkAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !isBusy,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock, color: Colors.pinkAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // BotÃ³n de inicio de sesiÃ³n
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () async {
                            // Validate empty fields
                            if (emailController.text.trim().isEmpty) {
                              _showErrorDialog(
                                context,
                                'Required Field',
                                'Please enter your email',
                                Icons.email,
                              );
                              return;
                            }

                            if (passwordController.text.trim().isEmpty) {
                              _showErrorDialog(
                                context,
                                'Required Field',
                                'Please enter your password',
                                Icons.lock,
                              );
                              return;
                            }

                            // Validate email format
                            if (!_isValidEmail(emailController.text.trim())) {
                              _showErrorDialog(
                                context,
                                'Invalid Email',
                                'Please enter a valid email (example: user@email.com)',
                                Icons.email,
                              );
                              return;
                            }

                            // Validate password length
                            if (passwordController.text.length < 6) {
                              _showErrorDialog(
                                context,
                                'Password Too Short',
                                'Password must be at least 6 characters long',
                                Icons.lock,
                              );
                              return;
                            }

                            try {
                              FocusScope.of(context).unfocus();
                              await authViewModel.signIn(
                                emailController.text.trim(),
                                passwordController.text,
                              );

                              if (authViewModel.user != null) {
                                if (mounted) setState(() => _navigating = true);
                                Navigator.pushReplacementNamed(
                                    context, '/home');
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

                              _showErrorDialog(
                                context,
                                'Authentication Error',
                                errorMessage,
                                errorIcon,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Center(
                      child: isBusy
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
                SizedBox(height: 40),

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

  void _showErrorDialog(
      BuildContext context, String title, String message, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.2),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../services/api_user.dart';
import '../theme/app_theme.dart';
import '../screens/signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _api = UserService();

  bool _obscure = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final identifier = _emailController.text.trim();
      final password = _passwordController.text;
      await _api.login(identifier: identifier, password: password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ocean gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.retroPrimary,
                  Color.fromARGB(255, 112, 150, 193),
                  AppColors.retroWhite,
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Subtle sand overlay at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.retroSand],
                ),
              ),
            ),
          ),
          // Soft decorative blobs (yellow/pink) matching Home accents
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.retroSand.withOpacity(0.8),
                    AppColors.retroSand,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(120),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.retroPeach.withOpacity(0.8),
                    AppColors.retroPeach,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand / Title
                    Text(
                      'Wave Music',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.retroWhite,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Form Card
                    Card(
                      color: AppColors.retroWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.retroAccent),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  final email =
                                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!email.hasMatch(value.trim())) {
                                    return 'Invalid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.retroAccent),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                        color: AppColors.retroAccent,),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgotPasswordScreen()),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: AppColors.retroAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _onSubmit,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(AppColors.retroWhite),
                                          ),
                                        )
                                      : const Text('Sign in'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account?"),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SignUpScreen()),
                                      );
                                    },
                                    child: const Text(
                                      'Create account',
                                      style: TextStyle(
                                        color: AppColors.retroAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

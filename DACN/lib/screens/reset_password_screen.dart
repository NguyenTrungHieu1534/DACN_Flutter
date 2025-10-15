import 'package:flutter/material.dart';
import '../services/api_user.dart';
import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _service = UserService();
  bool _loading = false;

  void _resetPassword() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Mật khẩu không khớp!")));
      return;
    }

    setState(() => _loading = true);
    final result = await _service.resetPassword(
      email: widget.email,
      otp: widget.otp,
      password: _passwordController.text.trim(),
    );
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    if (result['success']) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                    Text(
                      'Wave Music',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.retroWhite,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: AppColors.retroWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_outline, color: AppColors.retroAccent)),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _confirmController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu', prefixIcon: Icon(Icons.lock_reset, color: AppColors.retroAccent)),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _resetPassword,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppColors.retroWhite),
                                        ),
                                      )
                                    : const Text("Đặt lại mật khẩu"),
                              ),
                            ),
                          ],
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

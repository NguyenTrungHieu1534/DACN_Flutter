import 'package:flutter/material.dart';
import '../services/api_user.dart';
import 'reset_password_screen.dart';
import '../theme/app_theme.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _service = UserService();
  bool _loading = false;

  void _verifyOtp() async {
    setState(() => _loading = true);

    final result = await _service.verifyOtp(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    if (result['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otp: _otpController.text.trim(),
          ),
        ),
      );
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
                            Text("Nhập mã OTP được gửi đến email: ${widget.email}", style: TextStyle(color: AppColors.retroAccent),),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _otpController,
                              decoration: const InputDecoration(labelText: 'Mã OTP', prefixIcon: Icon(Icons.lock_outline, color: AppColors.retroAccent)),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _verifyOtp,
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
                                    : const Text("Xác minh"),
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

import 'package:flutter/material.dart';
import 'dart:ui';

class NoInternetOverlay extends StatelessWidget {
  final bool hasInternet;
  final VoidCallback? onRetry; // Optional: hành động thử lại khi nhấn nút

  const NoInternetOverlay({
    super.key,
    required this.hasInternet,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (hasInternet) return const SizedBox.shrink();

    return Positioned.fill(
      child: ClipRect(
        // Đưa ra ngoài Container
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            color: Colors.black.withOpacity(0.7), // Chỉ màu
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      ).createShader(bounds),
                      child: const Icon(Icons.wifi_off,
                          size: 70, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Mất kết nối Internet",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Vui lòng bật WiFi hoặc dữ liệu di động để tiếp tục.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Thử lại"),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

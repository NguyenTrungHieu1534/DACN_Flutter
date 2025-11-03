import 'package:flutter/material.dart';

class HawaiiGreetingCard extends StatelessWidget {
  final String Function() greeting;
  final IconData Function(int hour) getGreetingIcon;

  const HawaiiGreetingCard({
    super.key,
    required this.greeting,
    required this.getGreetingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00C6FB), // Xanh biển sáng
            Color(0xFF005BEA), // Xanh biển đậm
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007BFF).withOpacity(0.25),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF8EE7FF).withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFC371), // Vàng cam mặt trời
                  Color(0xFFFF5F6D), // Cam hồng nhiệt đới
                ],
              ),
            ),
            child: Icon(
              getGreetingIcon(DateTime.now().hour),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Text chào
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFE29F), // Vàng ánh sáng
                    Color(0xFFFF719A), // Hồng đào
                    Color(0xFF9BFFF9), // Aqua sáng
                  ],
                ).createShader(bounds),
                child: Text(
                  greeting(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 6,
                        color: Color(0xFF004C97),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Let’s ride the wave of music 🌊',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

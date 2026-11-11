import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  final Widget child;

  const DashboardBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF101820),
                  Color(0xFF17232E),
                  Color(0xFF1B2733),
                  Color(0xFF202D38),
                ]
              : const [
                  Color(0xFF8FC6FF),
                  Color(0xFFDCEEFF),
                  Color(0xFFF6FAFF),
                  Color(0xFFFFFFFF),
                ],
          stops: const [0.0, 0.30, 0.60, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Luz superior izquierda
          Positioned(
            top: -130,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.025 : 0.45),
              ),
            ),
          ),

          // Luz superior derecha
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.30),
              ),
            ),
          ),

          // Luz inferior
          Positioned(
            bottom: -180,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: isDark ? 0.04 : 0.05),
              ),
            ),
          ),

          // Capa sutil para efecto visual
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),

          SafeArea(child: child),
        ],
      ),
    );
  }
}

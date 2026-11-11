// =============================================================
// APLICATIVO NANCY
// Estadísticas inferiores del Dashboard
// Adaptadas para modo claro / oscuro
// =============================================================

import 'package:flutter/material.dart';

class DashboardStats extends StatelessWidget {
  final int pending;
  final int synced;

  final VoidCallback? onPendingTap;
  final VoidCallback? onSyncedTap;

  const DashboardStats({
    super.key,
    required this.pending,
    required this.synced,
    this.onPendingTap,
    this.onSyncedTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 145,
      child: Row(
        children: [
          // PENDIENTES
          Expanded(
            child: _StatItem(
              icon: Icons.cloud_upload_outlined,
              color: const Color(0xFFFF9800),
              number: pending.toString(),
              text: 'Pendientes',
              onTap: onPendingTap,
              isDark: isDark,
            ),
          ),

          // SEPARADOR
          Container(
            width: 1,
            height: 65,
            color: isDark ? const Color(0xFF3A4855) : const Color(0xFFE5E7EB),
          ),

          // HISTORIAL
          Expanded(
            child: _StatItem(
              icon: Icons.history_rounded,
              color: const Color(0xFF43A047),
              number: synced.toString(),
              text: 'Historial',
              onTap: onSyncedTap,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ELEMENTO INDIVIDUAL
// =============================================================

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String number;
  final String text;
  final VoidCallback? onTap;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.number,
    required this.text,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.10),
        highlightColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICONO
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),

              // NÚMERO
              Text(
                number,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 1),

              // TEXTO
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFB0BECC)
                      : const Color(0xFF7A869A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

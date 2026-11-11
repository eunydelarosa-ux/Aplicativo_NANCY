// =============================================================
// APLICATIVO NANCY
// Encabezado principal del Dashboard
// =============================================================

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:nancy_app/features/profile/models/user_profile_model.dart';
import 'package:nancy_app/features/profile/providers/user_profile_provider.dart';

class DashboardHeader extends StatefulWidget {
  final int pendingCount;

  const DashboardHeader({super.key, required this.pendingCount});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  // =============================================================
  // PROVIDER DEL PERFIL
  // =============================================================

  final UserProfileProvider _profileProvider = UserProfileProvider();

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _profileProvider.loadProfile();

    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _profileProvider.dispose();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final UserProfileModel? profile = _profileProvider.profile;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String userName = profile?.name.trim().isNotEmpty == true
        ? profile!.name.trim()
        : 'Usuario';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 8),

      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),

      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF202D38)
            : Colors.white.withValues(alpha: 0.93),

        borderRadius: BorderRadius.circular(27),

        border: Border.all(
          color: isDark ? const Color(0xFF344554) : Colors.white,
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7FB7DE).withValues(alpha: 0.13),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Row(
        children: [
          // =====================================================
          // FOTO DE PERFIL
          // =====================================================
          _buildProfileImage(profile),

          const SizedBox(width: 11),

          // =====================================================
          // SALUDO
          // =====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  '¡Hola, $userName!',

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF17345F),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Sistema Integral de Inscripciones',

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFB0BECC)
                        : const Color(0xFF6D7F96),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // CAMPANA
          // =====================================================
          _buildNotificationButton(context),
        ],
      ),
    );
  }

  // =============================================================
  // FOTO DE PERFIL
  // =============================================================
  Widget _buildProfileImage(UserProfileModel? profile) {
    Widget image;
    String? imagePath;

    if (profile?.imagePath != null && profile!.imagePath!.trim().isNotEmpty) {
      final File file = File(profile.imagePath!);

      if (file.existsSync()) {
        imagePath = profile.imagePath;
        image = Image.file(file, width: 45, height: 45, fit: BoxFit.cover);
      } else {
        image = _defaultProfileImage();
      }
    } else {
      image = _defaultProfileImage();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (imagePath == null) return;

          showDialog<void>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.75),
            builder: (dialogContext) {
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.all(24),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.file(
                            File(imagePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF17345F),
                        ),
                        tooltip: 'Cerrar foto',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8ED7F4), Color(0xFF9DDCC8)],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF202D38)
                  : Colors.white,
            ),
            child: ClipOval(child: image),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FOTO POR DEFECTO
  // =============================================================

  Widget _defaultProfileImage() {
    return Container(
      color: const Color(0xFFEAF3F8),

      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF7890A6),
        size: 26,
      ),
    );
  }

  // =============================================================
  // BOTÓN DE NOTIFICACIONES
  // =============================================================

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        Material(
          color: Colors.transparent,

          child: InkWell(
            onTap: () {
              _showNotifications(context);
            },

            borderRadius: BorderRadius.circular(16),

            child: Container(
              width: 47,
              height: 47,

              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2B3A48)
                    : const Color(0xFFF4F8FC),

                borderRadius: BorderRadius.circular(16),

                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF405262)
                      : const Color(0xFFE1EAF2),
                ),
              ),

              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF1976C9),
                size: 27,
              ),
            ),
          ),
        ),

        // =======================================================
        // CONTADOR
        // =======================================================
        if (widget.pendingCount > 0)
          Positioned(
            right: -2,
            top: -5,

            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),

              padding: const EdgeInsets.symmetric(horizontal: 4),

              decoration: BoxDecoration(
                color: const Color(0xFFE45757),

                shape: BoxShape.circle,

                border: Border.all(color: Colors.white, width: 2),
              ),

              child: Center(
                child: Text(
                  widget.pendingCount > 9
                      ? '9+'
                      : widget.pendingCount.toString(),

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =============================================================
  // PANEL DE AVISOS
  // =============================================================

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return _NotificationsSheet(pendingCount: widget.pendingCount);
      },
    );
  }
}

// =============================================================
// PANEL DE AVISOS
// =============================================================

class _NotificationsSheet extends StatelessWidget {
  final int pendingCount;

  const _NotificationsSheet({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final bool hasPending = pendingCount > 0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202D38) : Colors.white,

        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),

      child: SafeArea(
        top: false,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,

                decoration: BoxDecoration(
                  color: const Color(0xFFD5DEE6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF1976C9),
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                Text(
                  'Avisos',

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (hasPending)
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3020)
                      : const Color(0xFFFFFAF0),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF66502A)
                        : const Color(0xFFFFE1A8),
                  ),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDC7),

                        borderRadius: BorderRadius.circular(13),
                      ),

                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            pendingCount == 1
                                ? 'Hay 1 aspirante pendiente'
                                : 'Hay $pendingCount aspirantes pendientes',

                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFFFD58A)
                                  : const Color(0xFF7C4A03),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Los registros están guardados localmente y esperan sincronización.',

                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark
                                  ? const Color(0xFFE5C98E)
                                  : const Color(0xFF8A6A32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF20382F)
                      : const Color(0xFFF0FAF4),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF345A46)
                        : const Color(0xFFCBE8D2),
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF3E2),

                        borderRadius: BorderRadius.circular(13),
                      ),

                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF39A982),
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Todo está al día',

                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFA7E4B7)
                                  : const Color(0xFF2E6B38),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'No hay avisos pendientes en este momento.',

                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFFB5D7BD)
                                  : const Color(0xFF5F8066),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF405262)
                        : const Color(0xFFE2E8F0),
                  ),
                ),

                child: Text(
                  'Cerrar',

                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD5DEE7)
                        : const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

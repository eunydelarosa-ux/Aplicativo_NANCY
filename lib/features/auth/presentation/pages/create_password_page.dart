// =============================================================
// APLICATIVO NANCY
// Crear contraseña personal
// =============================================================

import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../profile/providers/user_profile_provider.dart';

// =============================================================
// PÁGINA CREAR CONTRASEÑA
// =============================================================

class CreatePasswordPage extends StatefulWidget {
  const CreatePasswordPage({super.key});

  @override
  State<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  // =============================================================
  // CONTROLADORES
  // =============================================================

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // =============================================================
  // ESTADO
  // =============================================================

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isSaving = false;

  // =============================================================
  // COLORES
  // =============================================================

  static const Color pearlWhite = Color(0xFFFCFDFE);

  static const Color lightBlue = Color(0xFF2D8FE5);
  static const Color primaryBlue = Color(0xFF1976C9);

  static const Color silver = Color(0xFFE5EAF0);
  static const Color textDark = Color(0xFF26364F);
  static const Color textGray = Color(0xFF718096);
  static const Color textLight = Color(0xFF9AA6B2);

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // =============================================================
  // ESTABLECER CONTRASEÑA
  // =============================================================

  Future<void> _savePassword() async {
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Ingrese y confirme su nueva contraseña.');
      return;
    }

    if (password.length < 8) {
      _showMessage('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String passwordHash = sha256
          .convert(utf8.encode(password))
          .toString();

      final UserProfileProvider provider = context.read<UserProfileProvider>();

      final bool success = await provider.setPersonalPassword(
        passwordHash: passwordHash,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showMessage(
          provider.errorMessage ??
              'No fue posible establecer la contraseña personal.',
        );
        return;
      }

      _showMessage('Contraseña personal creada correctamente.');

      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (!mounted) {
        return;
      }

      context.go('/profile');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('No fue posible establecer la contraseña personal.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =============================================================
  // MENSAJES
  // =============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        backgroundColor: const Color(0xFF334155),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =============================================================
  // DECORACIÓN DE CAMPOS
  // =============================================================

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: textLight,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF9AA8B5), size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFCFDFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: silver, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: silver, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: lightBlue, width: 1.4),
      ),
    );
  }

  // =============================================================
  // FORMULARIO
  // =============================================================

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nueva contraseña',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          enabled: !_isSaving,
          obscureText: _hidePassword,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            hint: 'Ingrese su nueva contraseña',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: _hidePassword
                  ? 'Mostrar contraseña'
                  : 'Ocultar contraseña',
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF9AA8B5),
                size: 22,
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
            ),
          ),
        ),
        const SizedBox(height: 19),
        const Text(
          'Confirmar contraseña',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          enabled: !_isSaving,
          obscureText: _hideConfirmPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isSaving) {
              _savePassword();
            }
          },
          decoration: _fieldDecoration(
            hint: 'Repita su nueva contraseña',
            icon: Icons.lock_reset_outlined,
            suffixIcon: IconButton(
              tooltip: _hideConfirmPassword
                  ? 'Mostrar contraseña'
                  : 'Ocultar contraseña',
              icon: Icon(
                _hideConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF9AA8B5),
                size: 22,
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _hideConfirmPassword = !_hideConfirmPassword;
                      });
                    },
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'La contraseña debe tener al menos 8 caracteres.',
          style: TextStyle(color: textGray, fontSize: 12),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePassword,
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shadowColor: const Color(0xFF1976C9).withValues(alpha: 0.22),
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'GUARDAR CONTRASEÑA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // TARJETA
  // =============================================================

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 27, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFFE8EEF3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF718096).withValues(alpha: 0.09),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: _buildForm(),
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pearlWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }
}

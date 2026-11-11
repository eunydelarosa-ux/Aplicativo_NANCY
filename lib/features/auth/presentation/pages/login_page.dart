import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/models/user_profile_model.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _hidePassword = true;
  bool _isLoading = false;

  // =============================================================
  // COLORES DEL LOGIN
  // =============================================================

  static const Color pearlWhite = Color(0xFFFCFDFE);

  static const Color lightBlue = Color(0xFF2D8FE5);
  static const Color primaryBlue = Color(0xFF1976C9);

  static const Color silver = Color(0xFFE5EAF0);
  static const Color textDark = Color(0xFF26364F);
  static const Color textGray = Color(0xFF718096);
  static const Color textLight = Color(0xFF9AA6B2);

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =============================================================
  // AUTENTICAR USUARIO
  // =============================================================

  Future<void> _login() async {
    final String username = _userController.text.trim();
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showLoginMessage('Ingrese su usuario y contraseña.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserProfileModel? profile = await _authService.login(
        username: username,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (profile != null) {
        context.go('/dashboard');
        return;
      }

      // -----------------------------------------------------------
      // EL CAMPO CONTRASEÑA TAMBIÉN ACEPTA EL CÓDIGO DE ACTIVACIÓN
      // -----------------------------------------------------------
      final UserProfileModel? activationProfile = await _authService
          .loginWithActivationCode(
            username: username,
            activationCode: password,
          );

      if (!mounted) {
        return;
      }

      if (activationProfile != null) {
        context.go('/create-password');
        return;
      }

      _showLoginMessage('Usuario, contraseña o código incorrectos.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      final String errorMessage = e.toString();

      if (errorMessage.contains('Tu cuenta fue eliminada')) {
        _showLoginMessage(
          'Tu cuenta fue eliminada. '
          'Comunícate con el administrador para que te cree '
          'o habilite una cuenta nueva.',
        );
      } else if (errorMessage.contains('Tu cuenta está desactivada')) {
        _showLoginMessage(
          'Tu cuenta está desactivada. '
          'Comunícate con el administrador para reactivarla.',
        );
      } else if (errorMessage.contains(
        'Debes utilizar tu código de activación',
      )) {
        // ---------------------------------------------------------
        // EL CÓDIGO SE INTRODUJO EN EL CAMPO CONTRASEÑA
        // ---------------------------------------------------------
        try {
          final UserProfileModel? activationProfile = await _authService
              .loginWithActivationCode(
                username: username,
                activationCode: password,
              );

          if (!mounted) {
            return;
          }

          if (activationProfile != null) {
            context.go('/create-password');
            return;
          }

          _showLoginMessage('Usuario o código de activación incorrectos.');
        } catch (activationError) {
          if (!mounted) {
            return;
          }

          final String activationMessage = activationError.toString();

          if (activationMessage.contains('desactivada')) {
            _showLoginMessage(
              'Tu cuenta está desactivada. '
              'Comunícate con el administrador para reactivarla.',
            );
          } else {
            _showLoginMessage('Usuario o código de activación incorrectos.');
          }
        }
      } else {
        _showLoginMessage('Usuario o contraseña incorrectos.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =============================================================
  // RECUPERACIÓN DE CONTRASEÑA
  // =============================================================

  void _showPasswordRecovery() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: const Text(
                'Recuperar contraseña',
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          content: const Text(
            'Si olvidó su contraseña, comuníquese con el '
            'Coordinador o Administrador de NANCY para solicitar '
            'un código de recuperación.\n\n'
            'Una vez reciba el código, podrá utilizarlo para '
            'crear una nueva contraseña.',
            textAlign: TextAlign.left,
            style: TextStyle(color: textGray, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'ENTENDIDO',
                style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showRecoveryCodeDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'INGRESAR CÓDIGO',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // INGRESAR CÓDIGO DE RECUPERACIÓN
  // =============================================================

  void _showRecoveryCodeDialog() {
    final TextEditingController usernameController = TextEditingController(
      text: _userController.text.trim(),
    );

    final TextEditingController recoveryCodeController =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: const Text(
                'Código de recuperación',
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingrese su usuario y el código de recuperación '
                  'que le proporcionó el Coordinador o Administrador.',
                  style: TextStyle(color: textGray, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Usuario',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    hint: 'Ingrese su usuario',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Código de recuperación',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: recoveryCodeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  decoration: _fieldDecoration(
                    hint: 'Ingrese el código',
                    icon: Icons.key_outlined,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: textGray, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final String username = usernameController.text.trim();
                final String recoveryCode = recoveryCodeController.text.trim();

                if (username.isEmpty || recoveryCode.isEmpty) {
                  await showDialog<void>(
                    context: context,
                    builder: (errorContext) {
                      return AlertDialog(
                        title: const Text(
                          'Datos incompletos',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        content: const Text(
                          'Ingrese su usuario y el código de recuperación.',
                          style: TextStyle(
                            color: textGray,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(errorContext).pop();
                            },
                            child: const Text(
                              'ENTENDIDO',
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }

                try {
                  final UserProfileModel? recoveryProfile = await _authService
                      .loginWithActivationCode(
                        username: username,
                        activationCode: recoveryCode,
                      );

                  if (!mounted) {
                    return;
                  }

                  if (recoveryProfile != null) {
                    Navigator.of(context).pop();
                    context.go('/create-password');
                    return;
                  }

                  await showDialog<void>(
                    context: context,
                    builder: (errorContext) {
                      return AlertDialog(
                        title: const Text(
                          'Código no válido',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        content: const Text(
                          'El usuario o el código de recuperación '
                          'son incorrectos.',
                          style: TextStyle(
                            color: textGray,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(errorContext).pop();
                            },
                            child: const Text(
                              'ENTENDIDO',
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } catch (e) {
                  if (!mounted) {
                    return;
                  }

                  final String errorMessage = e.toString();

                  if (errorMessage.contains('desactivada')) {
                    await showDialog<void>(
                      context: context,
                      builder: (errorContext) {
                        return AlertDialog(
                          title: const Text(
                            'Cuenta desactivada',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          content: const Text(
                            'Tu cuenta está desactivada. '
                            'Comunícate con el administrador '
                            'para reactivarla.',
                            style: TextStyle(
                              color: textGray,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(errorContext).pop();
                              },
                              child: const Text(
                                'ENTENDIDO',
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    await showDialog<void>(
                      context: context,
                      builder: (errorContext) {
                        return AlertDialog(
                          title: const Text(
                            'Código no válido',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                          content: const Text(
                            'El usuario o el código de recuperación '
                            'son incorrectos.',
                            style: TextStyle(
                              color: textGray,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(errorContext).pop();
                              },
                              child: const Text(
                                'ENTENDIDO',
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'CONTINUAR',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // MENSAJE DE AUTENTICACIÓN
  // =============================================================
  void _showLoginMessage(String message) {
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
  // FONDO DEL LOGIN
  // =============================================================

  Widget buildBackground() {
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/fondo_login.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(color: pearlWhite);
        },
      ),
    );
  }

  // =============================================================
  // LOGO
  // =============================================================

  Widget buildLogo() {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7EEF4), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF718096).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
    );
  }

  // =============================================================
  // TITULO
  // =============================================================

  Widget buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1976C9), Color(0xFF29AFC9), Color(0xFF42B883)],
            ).createShader(bounds);
          },
          child: const Text(
            'NANCY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 39,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'Sistema Integral de Inscripciones',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: textGray,
            letterSpacing: 0.25,
          ),
        ),
      ],
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

  Widget buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =========================================================
        // USUARIO
        // =========================================================
        const Text(
          'Usuario',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _userController,
          style: const TextStyle(
            color: textDark,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            hint: 'Ingrese su usuario',
            icon: Icons.person_outline_rounded,
          ),
        ),

        const SizedBox(height: 19),

        // =========================================================
        // CONTRASEÑA
        // =========================================================
        const Text(
          'Contraseña',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _passwordController,
          style: const TextStyle(
            color: textDark,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          obscureText: _hidePassword,
          textInputAction: TextInputAction.done,
          decoration: _fieldDecoration(
            hint: 'Ingrese su contraseña',
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
              onPressed: () {
                setState(() {
                  _hidePassword = !_hidePassword;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 7),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _showPasswordRecovery,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '¿Olvidó su contraseña?',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 17),
        // =========================================================
        // BOTÓN INGRESAR
        // =========================================================
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,

            style: ElevatedButton.styleFrom(
              elevation: 2,

              shadowColor: const Color(0xFF1976C9).withValues(alpha: 0.22),

              backgroundColor: primaryBlue,

              foregroundColor: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),

            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'INGRESAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // TARJETA DEL LOGIN
  // =============================================================

  Widget buildLoginCard() {
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

      child: buildLoginForm(),
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pearlWhite,

      body: Stack(
        children: [
          // =======================================================
          // FONDO
          // =======================================================
          Positioned.fill(child: buildBackground()),

          // =======================================================
          // CONTENIDO
          // =======================================================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 28,
                ),

                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // =================================================
                      // LOGO
                      // =================================================
                      buildLogo(),

                      const SizedBox(height: 21),

                      // =================================================
                      // TITULO
                      // =================================================
                      buildTitle(),

                      const SizedBox(height: 34),

                      // =================================================
                      // TARJETA
                      // =================================================
                      buildLoginCard(),

                      const SizedBox(height: 20),

                      // =================================================
                      // DETALLE DECORATIVO INFERIOR
                      // =================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF7FC9ED),
                            ),
                          ),

                          const SizedBox(width: 7),

                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF8DD8B9),
                            ),
                          ),

                          const SizedBox(width: 7),

                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFC7D0D9),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

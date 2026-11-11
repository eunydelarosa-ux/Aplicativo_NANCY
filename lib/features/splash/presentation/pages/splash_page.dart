import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// =============================================================
// SPLASH PAGE
// =============================================================

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // ===========================================================
  // CONTROLADORES DE ANIMACIÓN
  // ===========================================================

  late AnimationController _logoController;
  late AnimationController _contentController;

  // ===========================================================
  // ANIMACIONES DEL LOGO
  // ===========================================================

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // ===========================================================
  // ANIMACIONES DEL CONTENIDO
  // ===========================================================

  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;

  // ===========================================================
  // PROGRESO
  // ===========================================================

  int _progressStep = 0;

  Timer? _timer;

  // ===========================================================
  // INIT STATE
  // ===========================================================

  @override
  void initState() {
    super.initState();

    // ---------------------------------------------------------
    // ANIMACIÓN DEL LOGO
    // ---------------------------------------------------------

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // ---------------------------------------------------------
    // ANIMACIÓN DEL CONTENIDO
    // ---------------------------------------------------------

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );

    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );

    // ---------------------------------------------------------
    // INICIAR SPLASH
    // ---------------------------------------------------------

    iniciarAnimacion();
  }

  // ===========================================================
  // INICIAR ANIMACIÓN
  // ===========================================================

  Future<void> iniciarAnimacion() async {
    // Primero aparece el logo.
    await _logoController.forward();

    // Pequeña pausa.
    await Future.delayed(const Duration(milliseconds: 100));

    // Después aparece el contenido.
    if (mounted) {
      _contentController.forward();
    }

    // ---------------------------------------------------------
    // PROGRESO
    // ---------------------------------------------------------

    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) return;

      setState(() {
        _progressStep++;

        if (_progressStep >= 5) {
          timer.cancel();

          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              // Navegar al Login.
              context.go('/login');
            }
          });
        }
      });
    });
  }

  // ===========================================================
  // DISPOSE
  // ===========================================================

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();

    _timer?.cancel();

    super.dispose();
  }

  Widget buildBackground() {
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/splash_background.png',
        fit: BoxFit.fill,
        alignment: Alignment.center,
      ),
    );
  }

  // ===========================================================
  // LOGO
  // ===========================================================

  Widget buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================
  // TITULO NANCY
  // ===========================================================

  Widget buildNancy() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1E63A6), Color(0xFF278FC2), Color(0xFF3EAD73)],
        ).createShader(bounds);
      },
      child: const Text(
        'NANCY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 5,
        ),
      ),
    );
  }

  // ===========================================================
  // CONTENIDO
  // ===========================================================

  Widget buildContent() {
    return FadeTransition(
      opacity: _contentOpacity,
      child: SlideTransition(
        position: _contentSlide,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -------------------------------------------------
            // NOMBRE
            // -------------------------------------------------
            buildNancy(),

            const SizedBox(height: 14),

            // -------------------------------------------------
            // DESCRIPCIÓN
            // -------------------------------------------------
            const Text(
              'Sistema Integral de\nInscripciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF667085),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 48),

            // -------------------------------------------------
            // BARRA DE PROGRESO
            // -------------------------------------------------
            buildProgress(),

            const SizedBox(height: 22),

            // -------------------------------------------------
            // TEXTO DE CARGA
            // -------------------------------------------------
            const Text(
              'Cargando sistema...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8A94A6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // PROGRESO MINIMALISTA
  // ===========================================================

  Widget buildProgress() {
    // Calculamos cuánto debe avanzar la barra.
    final double progress = (_progressStep / 5).clamp(0.0, 1.0);

    return SizedBox(
      width: 90,
      height: 4,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // ---------------------------------------------------
          // FONDO
          // ---------------------------------------------------
          Container(
            width: 90,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E8EF),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // ---------------------------------------------------
          // PROGRESO
          // ---------------------------------------------------
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: 90 * progress,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF1E63A6),
                  Color(0xFF278FC2),
                  Color(0xFF3EAD73),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // BUILD PRINCIPAL
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------------------------------------------------
          // FONDO
          // ---------------------------------------------------
          buildBackground(),

          // ---------------------------------------------------
          // CONTENIDO PRINCIPAL
          // ---------------------------------------------------
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // -----------------------------------------
                    // LOGO
                    // -----------------------------------------
                    buildLogo(),

                    const SizedBox(height: 28),

                    // -----------------------------------------
                    // CONTENIDO
                    // -----------------------------------------
                    buildContent(),
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

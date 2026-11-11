import 'package:flutter/material.dart';

import '../../models/appearance_settings_model.dart';
import '../../providers/appearance_provider.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  late final AppearanceProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = AppearanceProvider.instance;
    _provider.addListener(_onAppearanceChanged);
    _provider.loadAppearance();
  }

  @override
  void dispose() {
    _provider.removeListener(_onAppearanceChanged);
    super.dispose();
  }

  void _onAppearanceChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppearanceSettingsModel settings = _provider.settings;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Apariencia',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: _provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEMA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Selecciona cómo quieres visualizar '
                      'la aplicación.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildThemeOption(
                      icon: Icons.brightness_auto_rounded,
                      iconColor: const Color(0xFF64748B),
                      title: 'Sistema',
                      description:
                          'Utiliza automáticamente el tema '
                          'configurado en tu dispositivo.',
                      value: 'system',
                      selectedValue: settings.themeMode,
                    ),

                    const SizedBox(height: 14),

                    _buildThemeOption(
                      icon: Icons.light_mode_outlined,
                      iconColor: const Color(0xFF2D8FE5),
                      title: 'Claro',
                      description:
                          'Mantiene la aplicación con una '
                          'apariencia clara.',
                      value: 'light',
                      selectedValue: settings.themeMode,
                    ),

                    const SizedBox(height: 14),

                    _buildThemeOption(
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Oscuro',
                      description:
                          'Utiliza una apariencia oscura '
                          'para la aplicación.',
                      value: 'dark',
                      selectedValue: settings.themeMode,
                    ),

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.outlineVariant),
                      ),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: colors.primary,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'La selección se guarda automáticamente '
                              'en este dispositivo.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String value,
    required String selectedValue,
  }) {
    final bool selected = value == selectedValue;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,

      child: InkWell(
    onTap: () {
  _provider.setThemeMode(value);
},

        borderRadius: BorderRadius.circular(22),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surface,

            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.4 : 1,
            ),

            boxShadow: theme.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),

          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(icon, color: iconColor, size: 26),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selected ? colors.primary : colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  border: Border.all(
                    color: selected ? colors.primary : colors.outline,
                    width: 2,
                  ),

                  color: selected ? colors.primary : Colors.transparent,
                ),

                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

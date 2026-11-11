import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart';

import '../../models/user_profile_model.dart';

import '../../providers/user_profile_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileProvider _profileProvider = UserProfileProvider();

  final _nameController = TextEditingController();

  final _roleController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();

  final _cedulaController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmNewPassword = true;

  String? _imagePath;

  bool _removeProfileImage = false;

  bool _isLoadingProfile = true;

  // Paleta de colores de la pantalla Mi perfil.

  static const Color _ink = Color(0xFF26364F);

  static const Color _blue = Color(0xFF4F83E3);

  static const Color _line = Color(0xFFE3EAF3);

  static const Color _fieldBackground = Color(0xFFFAFBFD);

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _textColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFFF1F5F9) : _ink;

  Color _fieldColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF263746) : _fieldBackground;

  Color _borderColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF405262) : _line;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();

    _roleController.dispose();

    _emailController.dispose();

    _phoneController.dispose();

    _cedulaController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    await _profileProvider.loadProfile();

    if (!mounted) return;

    final profile = _profileProvider.profile;

    if (profile != null) {
      _fillControllers(profile);
    }

    setState(() => _isLoadingProfile = false);

    final path = profile?.imagePath;

    if (path != null && path.isNotEmpty) {
      final imageFile = File(path);

      if (await imageFile.exists()) {
        if (!mounted) return;

        try {
          await precacheImage(FileImage(imageFile), context);
        } catch (_) {}
      }
    }
  }

  void _fillControllers(UserProfileModel profile) {
    _nameController.text = profile.name;

    _roleController.text = profile.role;

    _emailController.text = profile.email;

    _phoneController.text = profile.phone;

    _cedulaController.text = profile.cedula ?? '';

    _imagePath = profile.imagePath;

    // La imagen cargada es la que está guardada.

    _removeProfileImage = false;
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        final bool isDark =
            Theme.of(sheetContext).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202D38) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF526273)
                      : const Color(0xFFD5DEE9),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cambiar foto de perfil',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF26364F),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '¿Cómo deseas agregar tu fotografía?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFB8C6D4)
                      : const Color(0xFF6C819B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                tileColor: isDark
                    ? const Color(0xFF263746)
                    : const Color(0xFFF2F7FD),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0EDFF),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF3F83E8),
                  ),
                ),
                title: Text(
                  'Tomar una foto',
                  style: TextStyle(
                    color: isDark ? Colors.white : _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Usar la cámara del celular',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB8C6D4)
                        : const Color(0xFF6C819B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                tileColor: isDark
                    ? const Color(0xFF263746)
                    : const Color(0xFFF2F7FD),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0EDFF),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF3F83E8),
                  ),
                ),
                title: Text(
                  'Elegir de la galería',
                  style: TextStyle(
                    color: isDark ? Colors.white : _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Seleccionar una foto existente',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB8C6D4)
                        : const Color(0xFF6C819B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFD7E2EC)
                          : const Color(0xFF6C819B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (image == null || !mounted) return;

      setState(() {
        _imagePath = image.path;
        _removeProfileImage = false;
      });

      final success = await _profileProvider.updateProfileImage(
        imagePath: image.path,
      );

      if (!mounted) return;

      if (success) {
        final savedProfile = _profileProvider.profile;

        if (savedProfile != null) {
          setState(() {
            _imagePath = savedProfile.imagePath;
            _removeProfileImage = false;
          });
        }

        _showMessage('Foto del perfil guardada correctamente.', success: true);
      } else {
        setState(() {
          _imagePath = _profileProvider.profile?.imagePath;
        });

        _showMessage(
          _profileProvider.errorMessage ??
              'No fue posible guardar la foto del perfil.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imagePath = _profileProvider.profile?.imagePath;
        });

        _showMessage('No fue posible seleccionar o guardar la imagen.');
      }
    }
  }

  Future<void> _removeImage() async {
    final previousImagePath = _profileProvider.profile?.imagePath;

    setState(() {
      _imagePath = null;
      _removeProfileImage = false;
    });

    final success = await _profileProvider.updateProfileImage(imagePath: null);

    if (!mounted) return;

    if (success) {
      setState(() {
        _imagePath = null;
        _removeProfileImage = false;
      });

      _showMessage('Foto del perfil eliminada correctamente.', success: true);
    } else {
      setState(() {
        _imagePath = previousImagePath;
      });

      _showMessage(
        _profileProvider.errorMessage ??
            'No fue posible eliminar la foto del perfil.',
      );
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    // Comprobar si el perfil ya estaba completo antes de guardar.
    final bool wasProfileComplete =
        _profileProvider.profile?.isProfileComplete ?? false;

    final name = _nameController.text.trim();
    final role = _roleController.text.trim();
    final cedula = _cedulaController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    // Validar nombre.
    if (name.isEmpty) {
      _showMessage('Por favor, escribe tu nombre.');
      return;
    }

    // Validar cédula.
    if (cedula.isEmpty) {
      _showMessage('Por favor, escribe tu número de cédula.');
      return;
    }

    // Validar rol asignado.
    if (role.isEmpty) {
      _showMessage(
        'No se encontró el rol de tu cuenta. Contacta al administrador.',
      );
      return;
    }

    // Validar teléfono.
    if (phone.isEmpty) {
      _showMessage('Por favor, escribe tu teléfono.');
      return;
    }

    // Validar correo electrónico.
    if (email.isEmpty) {
      _showMessage('Por favor, escribe tu correo electrónico.');
      return;
    }

    // Comprobar el formato del correo.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Por favor, escribe un correo electrónico válido.');
      return;
    }

    // Guardar el perfil.
    final success = await _profileProvider.saveProfile(
      name: name,
      role: role,
      email: email,
      phone: phone,
      cedula: cedula,
      imagePath: _removeProfileImage ? null : _imagePath,
      removeImage: _removeProfileImage,
    );

    if (!mounted) return;

    if (success) {
      final savedProfile = _profileProvider.profile;

      if (savedProfile != null) {
        _fillControllers(savedProfile);
      }

      setState(() {});

      // Primera vez: después de guardar correctamente,
      // ir al panel principal.
      if (!wasProfileComplete) {
        context.go('/dashboard');
        return;
      }

      // Si el perfil ya estaba completo, permanecer en Mi perfil.
      _showMessage('Perfil guardado correctamente.', success: true);
    } else {
      _showMessage(
        _profileProvider.errorMessage ?? 'No fue posible guardar el perfil.',
      );
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: success
              ? const Color(0xFF21865B)
              : const Color(0xFF26364F),

          behavior: SnackBarBehavior.floating,

          margin: const EdgeInsets.all(12),

          elevation: 6,

          duration: const Duration(seconds: 3),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          content: Text(
            message,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 14,

              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDark(context);
    final profile = _profileProvider.profile;
    final bool isActive = profile?.isActive ?? true;
    final bool isProfileComplete = profile?.isProfileComplete ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark
          ? const Color(0xFF101923)
          : const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: isProfileComplete
            ? IconButton(
                tooltip: 'Volver',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.maybePop(context),
              )
            : const SizedBox.shrink(),
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildProfileHero(isActive: isActive),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        children: [
                          _buildPersonalContactForm(),
                          const SizedBox(height: 16),
                          _buildSecurityCard(),
                          const SizedBox(height: 86),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoadingProfile
          ? null
          : SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18232E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: isProfileComplete
                      ? Row(
                          children: [
                            Expanded(child: _buildCancelButton()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSaveButton()),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: _buildSaveButton(),
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHero({required bool isActive}) {
    final bool isDark = _isDark(context);

    final displayName = _nameController.text.trim().isEmpty
        ? 'Tu nombre'
        : _nameController.text.trim();

    final displayRole = _roleController.text.trim().isEmpty
        ? 'Tu rol'
        : _roleController.text.trim();

    return SizedBox(
      height: 330,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(42),
                bottomRight: Radius.circular(42),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                Color(0xFF172431),
                                Color(0xFF20384B),
                                Color(0xFF294B64),
                              ]
                            : const [
                                Color(0xFF61B1EF),
                                Color(0xFF7CC2F1),
                                Color(0xFFA9DCF6),
                              ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 58,
                    left: -105,
                    child: Transform.rotate(
                      angle: -0.18,
                      child: Container(
                        width: 455,
                        height: 118,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8FCDF3,
                          ).withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(90),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    right: -120,
                    child: Transform.rotate(
                      angle: -0.20,
                      child: Container(
                        width: 500,
                        height: 145,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFC4E6F9,
                          ).withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -55,
                    left: -85,
                    child: Container(
                      width: 510,
                      height: 145,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F1FB).withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tarjeta blanca con los datos del perfil.
          Positioned(
            top: 150,
            left: 16,
            right: 16,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 58, 18, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18232E) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF182D52),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    displayRole,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFB8C6D4)
                          : const Color(0xFF6C819B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF183A2A)
                          : const Color(0xFFE5F8EC),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF25B965)
                                : const Color(0xFF9AA8B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Perfil activo' : 'Perfil inactivo',
                          style: TextStyle(
                            color: isDark
                                ? (isActive
                                      ? const Color(0xFF7BE0A8)
                                      : const Color(0xFFB0BBC7))
                                : (isActive
                                      ? const Color(0xFF26794A)
                                      : const Color(0xFF687788)),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Foto y botones.
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 184,
                height: 110,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 17,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _buildAvatar(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 76,
                      top: 43,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickImage,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F83E8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 119,
                      top: 43,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _removeImage,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D55),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final path = _imagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return ClipOval(
      child: hasImage
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => _avatarPlaceholder(),
            )
          : _avatarPlaceholder(),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: const Color(0xFFEDF3FC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF4F83E3),
        size: 62,
      ),
    );
  }

  Widget _buildPersonalContactForm() {
    final bool isDark = _isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18232E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF405262) : const Color(0xFFE7EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: Color(0xFF1680EF),
                size: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Información personal y contacto',
                  style: TextStyle(
                    color: _textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildPrototypeProfileField(
            label: 'Nombre completo',
            hint: 'Ingrese su nombre completo',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            requiredField: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 13),
          _buildPrototypeProfileField(
            label: 'Cédula',
            hint: 'Ingrese su cédula',
            controller: _cedulaController,
            icon: Icons.credit_card_rounded,
            requiredField: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 13),
          _buildPrototypeProfileField(
            label: 'Rol',
            hint: 'Rol asignado',
            controller: _roleController,
            icon: Icons.badge_rounded,
            enabled: false,
          ),
          const SizedBox(height: 13),
          _buildPrototypeProfileField(
            label: 'Teléfono',
            hint: 'Ingrese su número de teléfono',
            controller: _phoneController,
            icon: Icons.phone_rounded,
            requiredField: true,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 13),
          _buildPrototypeProfileField(
            label: 'Correo electrónico',
            hint: 'Ingrese su correo electrónico',
            controller: _emailController,
            icon: Icons.mail_rounded,
            requiredField: true,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypeProfileField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool requiredField = false,
    bool enabled = true,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    final bool isDark = _isDark(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 54,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF263746) : const Color(0xFFF7FAFE),
            border: Border.all(
              color: isDark ? const Color(0xFF405262) : const Color(0xFFD6E4F4),
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF1680EF), size: 23),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            cursorColor: _blue,
            style: TextStyle(
              color: enabled
                  ? _textColor(context)
                  : (isDark
                        ? const Color(0xFF9FB2C5)
                        : const Color(0xFF8199B6)),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: label,
                  style: const TextStyle(
                    color: Color(0xFF1265C5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    if (requiredField)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? const Color(0xFF9FB2C5)
                    : const Color(0xFF8AA0BA),
                fontSize: 13,
              ),
              filled: true,
              fillColor: enabled
                  ? (isDark ? const Color(0xFF202D38) : Colors.white)
                  : (isDark
                        ? const Color(0xFF263746)
                        : const Color(0xFFEDF3F9)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF405262)
                      : const Color(0xFFD0E0F3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF405262)
                      : const Color(0xFFD0E0F3),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF405262)
                      : const Color(0xFFD0E0F3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1680EF),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    final bool isDark = _isDark(context);
    final bool isComplete =
        _profileProvider.profile?.isProfileComplete ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isComplete ? _showSecuritySheet : null,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF203247)
                : (isComplete
                      ? const Color(0xFFE8F5FF)
                      : const Color(0xFFEAF1F8)),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF35516C)
                  : (isComplete
                        ? const Color(0xFFC8E4FF)
                        : const Color(0xFFDCE8F4)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isComplete
                      ? const Color(0xFFD5EBFF)
                      : const Color(0xFFDCE7F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: isComplete
                      ? const Color(0xFF1680EF)
                      : const Color(0xFF91A7BC),
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contraseña',
                      style: TextStyle(
                        color: _textColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),
                    Text(
                      isComplete
                          ? 'Cambiar contraseña cuando lo necesites.'
                          : 'Disponible después de guardar tu perfil.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFB8C6D4)
                            : const Color(0xFF6C819B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isComplete
                    ? const Color(0xFF1680EF)
                    : const Color(0xFF91A7BC),
                size: 27,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSecuritySheet() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    setState(() {
      _hideCurrentPassword = true;
      _hideNewPassword = true;
      _hideConfirmNewPassword = true;
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        final bool isDark = _isDark(sheetContext);

        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  22 + MediaQuery.paddingOf(sheetContext).bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF202D38) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 22,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF526273)
                                : const Color(0xFFD5DEE9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF293F56)
                                  : const Color(0xFFEAF4FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: _blue,
                              size: 23,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'Contraseña',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1C3156),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark
                                  ? const Color(0xFFD7E2EC)
                                  : const Color(0xFF687A8F),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Cambia tu contraseña utilizando la contraseña '
                        'actual de tu cuenta.',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFC7D8E8)
                              : const Color(0xFF5C7088),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _securityPasswordField(
                        label: 'Contraseña actual',
                        hint: 'Escribe tu contraseña actual',
                        controller: _currentPasswordController,
                        obscureText: _hideCurrentPassword,
                        onToggleVisibility: () {
                          sheetSetState(() {
                            _hideCurrentPassword = !_hideCurrentPassword;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      _securityPasswordField(
                        label: 'Nueva contraseña',
                        hint: 'Mínimo 8 caracteres',
                        controller: _newPasswordController,
                        obscureText: _hideNewPassword,
                        onToggleVisibility: () {
                          sheetSetState(() {
                            _hideNewPassword = !_hideNewPassword;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      _securityPasswordField(
                        label: 'Confirmar nueva contraseña',
                        hint: 'Repite la nueva contraseña',
                        controller: _confirmNewPasswordController,
                        obscureText: _hideConfirmNewPassword,
                        onToggleVisibility: () {
                          sheetSetState(() {
                            _hideConfirmNewPassword = !_hideConfirmNewPassword;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF203247)
                              : const Color(0xFFEAF5FF),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF35516C)
                                : const Color(0xFFD6E9F8),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFFA5D6F7)
                                  : const Color(0xFF5794C9),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Si no recuerdas tu contraseña actual, '
                                'debes utilizar el proceso de recuperación '
                                'desde el inicio de sesión.',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFC7D8E8)
                                      : const Color(0xFF557491),
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final bool success =
                                await _changePersonalPassword();

                            if (!sheetContext.mounted) {
                              return;
                            }

                            if (success) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F8CE8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.lock_reset_rounded, size: 22),
                          label: const Text(
                            'Cambiar contraseña',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _changePersonalPassword() async {
    FocusScope.of(context).unfocus();

    final String currentPassword = _currentPasswordController.text;

    final String newPassword = _newPasswordController.text;

    final String confirmPassword = _confirmNewPasswordController.text;

    if (currentPassword.isEmpty) {
      _showMessage('Escribe tu contraseña actual.');
      return false;
    }

    if (newPassword.isEmpty) {
      _showMessage('Escribe la nueva contraseña.');
      return false;
    }

    if (newPassword.length < 8) {
      _showMessage('La nueva contraseña debe tener al menos 8 caracteres.');
      return false;
    }

    if (confirmPassword.isEmpty) {
      _showMessage('Confirma la nueva contraseña.');
      return false;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Las nuevas contraseñas no coinciden.');
      return false;
    }

    if (newPassword == currentPassword) {
      _showMessage('La nueva contraseña debe ser diferente a la actual.');
      return false;
    }

    final profile = _profileProvider.profile;

    if (profile == null) {
      _showMessage('No fue posible obtener la información de tu cuenta.');
      return false;
    }

    final String currentPasswordHash = sha256
        .convert(utf8.encode(currentPassword))
        .toString();

    if (currentPasswordHash != profile.passwordHash) {
      _showMessage('La contraseña actual no es correcta.');
      return false;
    }

    final String newPasswordHash = sha256
        .convert(utf8.encode(newPassword))
        .toString();

    final bool success = await _profileProvider.setPersonalPassword(
      passwordHash: newPasswordHash,
    );

    if (!mounted) {
      return false;
    }

    if (!success) {
      _showMessage(
        _profileProvider.errorMessage ??
            'No fue posible cambiar la contraseña.',
      );
      return false;
    }

    _showMessage('Contraseña cambiada correctamente.', success: true);

    return true;
  }

  Widget _securityPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    final bool isDark = _isDark(context);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF26364F),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: _blue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFF3267D5),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFFB8C6D4) : const Color(0xFF98A2B3),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: _blue,
          size: 21,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: IconButton(
            tooltip: obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
            onPressed: onToggleVisibility,
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF6D82A0),
              size: 21,
            ),
          ),
        ),
        filled: true,
        fillColor: _fieldColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _borderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }

  void _cancelChanges() {
    FocusScope.of(context).unfocus();

    final String name = _nameController.text.trim();
    final String cedula = _cedulaController.text.trim();
    final String role = _roleController.text.trim();
    final String phone = _phoneController.text.trim();
    final String email = _emailController.text.trim();

    // El rol es asignado por el sistema.
    if (role.isEmpty) {
      _showMessage(
        'No se encontró el rol de tu cuenta. Contacta al administrador.',
      );
      return;
    }

    // Estos datos son obligatorios.
    if (name.isEmpty || cedula.isEmpty || phone.isEmpty || email.isEmpty) {
      _showMessage(
        'No puedes salir del perfil hasta completar '
        'los datos obligatorios.',
      );
      return;
    }

    // El correo debe tener un formato válido.
    final bool emailValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);

    if (!emailValid) {
      _showMessage(
        'No puedes salir del perfil hasta ingresar '
        'un correo electrónico válido.',
      );
      return;
    }

    // Todos los datos obligatorios están completos.
    context.go('/dashboard');
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: _profileProvider.isLoading ? null : _cancelChanges,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textColor(context),
          side: BorderSide(
            color: _isDark(context)
                ? const Color(0xFF405262)
                : const Color(0xFFD1E0F0),
            width: 1.4,
          ),
          backgroundColor: _isDark(context)
              ? const Color(0xFF202D38)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: const Text(
          'Cancelar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        onPressed: _profileProvider.isLoading ? null : _saveProfile,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF4F8CE8),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB7C9E9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          elevation: 0,
        ),
        icon: _profileProvider.isLoading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_rounded, size: 24),
        label: Text(
          _profileProvider.isLoading ? 'Guardando…' : 'Guardar',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

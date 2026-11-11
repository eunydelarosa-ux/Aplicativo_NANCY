// =============================================================
// APLICATIVO NANCY
// Administrador de Catálogo
// =============================================================

import 'package:flutter/material.dart';

import '../../models/catalog_item_model.dart';
import '../../providers/catalog_provider.dart';

class CatalogManagerPage extends StatefulWidget {
  final String catalogType;
  final String title;

  const CatalogManagerPage({
    super.key,
    required this.catalogType,
    required this.title,
  });

  @override
  State<CatalogManagerPage> createState() => _CatalogManagerPageState();
}

class _CatalogManagerPageState extends State<CatalogManagerPage> {
  // =============================================================
  // PROVIDER
  // =============================================================

  late final CatalogProvider _provider;

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();

    _provider = CatalogProvider();

    _provider.addListener(_onProviderChanged);

    _provider.loadByType(widget.catalogType);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();

    super.dispose();
  }

  // =============================================================
  // ACTUALIZAR INTERFAZ
  // =============================================================

  void _onProviderChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF7F9FD),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17232E) : Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFE6EDF5) : const Color(0xFF26364F),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2A44),
          ),
        ),
      ),

      // =========================================================
      // CONTENIDO
      // =========================================================
      body: SafeArea(child: _buildBody(context)),

      // =========================================================
      // BOTÓN AGREGAR
      // =========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,

        backgroundColor: const Color(0xFF2D8FE5),

        foregroundColor: Colors.white,

        elevation: 3,

        icon: const Icon(Icons.add_rounded),

        label: const Text(
          'Agregar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // =============================================================
  // CUERPO
  // =============================================================

  Widget _buildBody(BuildContext context) {
    if (_provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D8FE5)),
      );
    }

    if (_provider.errorMessage != null) {
      return _buildError(context);
    }

    if (_provider.items.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      color: const Color(0xFF2D8FE5),

      onRefresh: () {
        return _provider.loadByType(widget.catalogType);
      },

      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

        itemCount: _provider.items.length,

        separatorBuilder: (_, index) {
          return const SizedBox(height: 12);
        },

        itemBuilder: (context, index) {
          final CatalogItemModel item = _provider.items[index];

          return _buildCatalogItem(item, context);
        },
      ),
    );
  }

  // =============================================================
  // ELEMENTO DEL CATÁLOGO
  // =============================================================

  Widget _buildCatalogItem(CatalogItemModel item, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2936) : Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: isDark ? const Color(0xFF344657) : const Color(0xFFE1E8F0),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          // =====================================================
          // ICONO
          // =====================================================
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF203D50) : const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(15),
            ),

            child: const Icon(
              Icons.list_alt_rounded,
              color: Color(0xFF2D8FE5),
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          // =====================================================
          // NOMBRE
          // =====================================================
          Expanded(
            child: Text(
              item.name,

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF26364F),
              ),
            ),
          ),

          // =====================================================
          // MENÚ
          // =====================================================
          PopupMenuButton<String>(
            color: isDark ? const Color(0xFF243442) : null,
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? const Color(0xFFB6C2CE) : const Color(0xFF8793A5),
            ),

            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(item);
              }

              if (value == 'delete') {
                _showDeleteConfirmation(item);
              }
            },

            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'edit',

                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: isDark ? const Color(0xFFE6EDF5) : null,
                      ),

                      SizedBox(width: 10),

                      Text(
                        'Editar',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFE6EDF5) : null,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'delete',

                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFFFF8A80) : null,
                      ),

                      SizedBox(width: 10),

                      Text(
                        'Eliminar',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFF8A80) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ESTADO VACÍO
  // =============================================================

  Widget _buildEmptyState(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(22),
              ),

              child: const Icon(
                Icons.inventory_2_outlined,
                size: 34,
                color: Color(0xFF2D8FE5),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'No hay elementos registrados',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF26364F),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Agrega el primer elemento de este catálogo.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark
                    ? const Color(0xFFB6C2CE)
                    : const Color(0xFF8793A5),
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: _showAddDialog,

              icon: const Icon(Icons.add_rounded),

              label: const Text('Agregar elemento'),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // ERROR
  // =============================================================

  Widget _buildError(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFFE57373),
            ),

            const SizedBox(height: 16),

            Text(
              'No fue posible cargar el catálogo.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF26364F),
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () {
                _provider.loadByType(widget.catalogType);
              },

              child: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // AGREGAR
  // =============================================================

  Future<void> _showAddDialog() async {
    // -----------------------------------------------------------
    // Abrimos solamente el diálogo.
    //
    // IMPORTANTE:
    // Aquí NO llamamos al Provider.
    // -----------------------------------------------------------

    final String? name = await showDialog<String>(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        final TextEditingController controller = TextEditingController();

        final bool isDark =
            Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2936) : null,
          titleTextStyle: TextStyle(
            color: isDark ? const Color(0xFFF1F5F9) : null,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: isDark ? const Color(0xFFD5DEE8) : null,
          ),
          title: Text('Agregar ${widget.title.toLowerCase()}'),

          content: TextField(
            controller: controller,

            autofocus: true,

            textCapitalization: TextCapitalization.sentences,

            style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : null),
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Escribe el nombre',
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFFB6C2CE) : null,
              ),
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF8FA0B1) : null,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () {
                final String value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                // -------------------------------------------------
                // SOLAMENTE DEVOLVEMOS EL TEXTO.
                //
                // El Provider todavía NO se ejecuta.
                // -------------------------------------------------

                Navigator.pop(dialogContext, value);
              },

              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    // ===========================================================
    // EL ALERTDIALOG YA ESTÁ COMPLETAMENTE CERRADO
    // ===========================================================

    if (!mounted) {
      return;
    }

    if (name == null || name.trim().isEmpty) {
      return;
    }

    // ===========================================================
    // AHORA SÍ GUARDAMOS
    // ===========================================================

    final bool success = await _provider.addItem(
      catalogType: widget.catalogType,
      name: name.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(_provider.errorMessage ?? 'No fue posible guardar.');
    }
  }

  // =============================================================
  // EDITAR
  // =============================================================

  Future<void> _showEditDialog(CatalogItemModel item) async {
    // -----------------------------------------------------------
    // Abrimos el diálogo.
    //
    // El Provider NO se ejecuta mientras el diálogo está abierto.
    // -----------------------------------------------------------

    final String? name = await showDialog<String>(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        final TextEditingController controller = TextEditingController(
          text: item.name,
        );

        final bool isDark =
            Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2936) : null,
          titleTextStyle: TextStyle(
            color: isDark ? const Color(0xFFF1F5F9) : null,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: isDark ? const Color(0xFFD5DEE8) : null,
          ),
          title: const Text('Editar elemento'),

          content: TextField(
            controller: controller,

            autofocus: true,

            textCapitalization: TextCapitalization.sentences,

            style: TextStyle(color: isDark ? const Color(0xFFF1F5F9) : null),
            decoration: InputDecoration(
              labelText: 'Nombre',
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFFB6C2CE) : null,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () {
                final String value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                // -------------------------------------------------
                // Solamente devolvemos el nuevo nombre.
                // -------------------------------------------------

                Navigator.pop(dialogContext, value);
              },

              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    // ===========================================================
    // EL DIÁLOGO YA ESTÁ COMPLETAMENTE CERRADO
    // ===========================================================

    if (!mounted) {
      return;
    }

    if (name == null || name.trim().isEmpty) {
      return;
    }

    // ===========================================================
    // CREAR MODELO ACTUALIZADO
    // ===========================================================

    final CatalogItemModel updated = item.copyWith(name: name.trim());

    // ===========================================================
    // AHORA SÍ ACTUALIZAMOS SQLITE
    // ===========================================================

    final bool success = await _provider.updateItem(updated);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(_provider.errorMessage ?? 'No fue posible actualizar.');
    }
  }

  // =============================================================
  // CONFIRMAR ELIMINACIÓN
  // =============================================================

  Future<void> _showDeleteConfirmation(CatalogItemModel item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        final bool isDark =
            Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2936) : null,
          titleTextStyle: TextStyle(
            color: isDark ? const Color(0xFFF1F5F9) : null,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: isDark ? const Color(0xFFD5DEE8) : null,
          ),
          title: const Text('Eliminar elemento'),

          content: Text(
            '¿Estás seguro de que deseas eliminar '
            '"${item.name}"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9534F),
              ),

              onPressed: () {
                // -------------------------------------------------
                // Igual que en agregar y editar:
                // primero cerramos el diálogo.
                // -------------------------------------------------

                Navigator.pop(dialogContext, true);
              },

              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    // ===========================================================
    // EL DIÁLOGO YA ESTÁ CERRADO
    // ===========================================================

    if (!mounted) {
      return;
    }

    if (confirmed != true) {
      return;
    }

    // ===========================================================
    // AHORA SÍ ELIMINAMOS
    // ===========================================================

    final bool success = await _provider.deleteItem(item);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(_provider.errorMessage ?? 'No fue posible eliminar.');
    }
  }

  // =============================================================
  // MENSAJE
  // =============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

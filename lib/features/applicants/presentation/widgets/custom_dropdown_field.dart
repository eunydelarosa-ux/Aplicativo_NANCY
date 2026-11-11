import 'package:flutter/material.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    this.value,
    this.onChanged,
  });

  // =============================================================
  // PALETA VISUAL DEL FORMULARIO NANCY
  // =============================================================

  static const Color _primaryBlue = Color(0xFF1E5AA8);
  static const Color _textColor = Color(0xFF24364B);
  static const Color _hintColor = Color(0xFF7B8798);
  static const Color _borderColor = Color(0xFFD8E1EC);
  static const Color _softGreen = Color(0xFFE8F6F1);

  // =============================================================
  // ABRIR SELECTOR CON BUSCADOR
  // =============================================================

  Future<void> _openSearchSelector(
    BuildContext context,
    List<String> uniqueItems,
  ) async {
    final String? selectedItem = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.none,
      builder: (BuildContext bottomSheetContext) {
        return _SearchSelectorSheet(
          label: label,
          icon: icon,
          items: uniqueItems,
          selectedValue: value,
        );
      },
    );

    // ===========================================================
    // EL BOTTOM SHEET YA SE CERRÓ.
    // AHORA ACTUALIZAMOS EL VALOR DEL FORMULARIO.
    // ===========================================================

    if (selectedItem != null) {
      onChanged?.call(selectedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : _textColor;
    final Color hintColor = isDark ? Colors.white70 : _hintColor;
    final Color fieldColor = isDark
        ? const Color(0xFF252525)
        : const Color(0xFFFBFCFE);
    final Color borderColor = isDark ? Colors.white24 : _borderColor;

    // =============================================================
    // ELIMINAR ELEMENTOS DUPLICADOS
    // =============================================================

    final List<String> uniqueItems = items.toSet().toList();

    // =============================================================
    // VALIDAR EL VALOR SELECCIONADO
    // =============================================================

    final String? selectedValue = value != null && uniqueItems.contains(value)
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =======================================================
          // ETIQUETA
          // =======================================================
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),

          const SizedBox(height: 9),

          // =======================================================
          // CAMPO CON BUSCADOR
          // =======================================================
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onChanged == null
                  ? null
                  : () {
                      _openSearchSelector(context, uniqueItems);
                    },
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                width: double.infinity,
                height: 68,
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF244238) : _softGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: _primaryBlue, size: 22),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        selectedValue ?? hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedValue == null ? hintColor : textColor,
                          fontSize: selectedValue == null ? 14 : 15,
                          fontWeight: selectedValue == null
                              ? FontWeight.w400
                              : FontWeight.w500,
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.search_rounded,
                        color: _primaryBlue,
                        size: 23,
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
}

// ===============================================================
// SELECTOR CON BUSCADOR
// ESTE WIDGET ES STATEFUL PARA QUE EL CONTROLADOR DEL BUSCADOR
// SE CREE Y SE DESTRUYA CORRECTAMENTE.
// ===============================================================

class _SearchSelectorSheet extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? selectedValue;

  const _SearchSelectorSheet({
    required this.label,
    required this.icon,
    required this.items,
    required this.selectedValue,
  });

  @override
  State<_SearchSelectorSheet> createState() => _SearchSelectorSheetState();
}

class _SearchSelectorSheetState extends State<_SearchSelectorSheet> {
  // =============================================================
  // COLORES
  // =============================================================

  static const Color _primaryBlue = Color(0xFF1E5AA8);
  static const Color _textColor = Color(0xFF24364B);
  static const Color _hintColor = Color(0xFF7B8798);
  static const Color _borderColor = Color(0xFFD8E1EC);
  static const Color _softGreen = Color(0xFFE8F6F1);

  // =============================================================
  // CONTROLADOR DEL BUSCADOR
  // =============================================================

  late final TextEditingController _searchController;

  // =============================================================
  // RESULTADOS FILTRADOS
  // =============================================================

  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();

    _filteredItems = List.from(widget.items);
  }

  // =============================================================
  // LIBERAR EL CONTROLADOR CUANDO EL BOTTOM SHEET
  // REALMENTE SEA ELIMINADO DEL ÁRBOL DE WIDGETS
  // =============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =============================================================
  // FILTRAR RESULTADOS
  // =============================================================

  void _filterItems(String query) {
    final String normalizedQuery = query.trim().toLowerCase();

    setState(() {
      if (normalizedQuery.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(normalizedQuery))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : _textColor;
    final Color hintColor = isDark ? Colors.white70 : _hintColor;
    final Color sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color fieldColor = isDark
        ? const Color(0xFF292929)
        : const Color(0xFFFBFCFE);
    final Color borderColor = isDark ? Colors.white24 : _borderColor;
    final Color selectedColor = isDark ? const Color(0xFF244238) : _softGreen;
    final Color iconBackground = isDark ? const Color(0xFF244238) : _softGreen;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,

        child: Column(
          children: [
            // =====================================================
            // INDICADOR SUPERIOR
            // =====================================================
            const SizedBox(height: 12),

            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 18),

            // =====================================================
            // TÍTULO
            // =====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: _primaryBlue, size: 23),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close_rounded, color: hintColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =====================================================
            // BUSCADOR
            // =====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filterItems,

                // TEXTO QUE EL USUARIO ESCRIBE
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),

                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _primaryBlue,
                  ),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: borderColor, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // =====================================================
            // LISTA DE RESULTADOS
            // =====================================================
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: hintColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No se encontraron resultados',
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final String item = _filteredItems[index];

                        final bool isSelected = item == widget.selectedValue;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context, item);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? selectedColor : fieldColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? _primaryBlue
                                      : borderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: _primaryBlue,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

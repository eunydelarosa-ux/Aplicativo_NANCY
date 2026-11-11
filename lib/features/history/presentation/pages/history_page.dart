import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../applicants/repositories/applicant_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApplicantRepository _repository = ApplicantRepository();

  String _searchQuery = '';
  DateTime? _selectedDate;
  int _currentPage = 0;
  bool _isLoading = true;

  static const int _itemsPerPage = 10;

  // =============================================================
  // HISTORIAL REAL DESDE SQLITE
  // =============================================================

  List<_HistoryItem> _history = [];
  final Set<int> _selectedItems = {};

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =============================================================
  // CARGAR HISTORIAL
  // =============================================================

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<Map<String, dynamic>> rows = await _repository
          .getSyncHistory();

      final List<_HistoryItem> history = rows
          .map(_HistoryItem.fromMap)
          .where((item) => item.id > 0 && item.applicantId.trim().isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _history = history;
        _isLoading = false;
        _selectedItems.clear();
        _adjustPage();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _history = [];
        _isLoading = false;
        _selectedItems.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible cargar el historial: $error')),
      );
    }
  }

  // =============================================================
  // COPIAR IDENTIFICADOR
  // =============================================================

  Future<void> _copyApplicantId(String applicantId) async {
    await Clipboard.setData(ClipboardData(text: applicantId));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identificador copiado al portapapeles.')),
    );
  }

  // =============================================================
  // FORMATO DE FECHA
  // =============================================================

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatTime(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .trim();
  }

  // =============================================================
  // ESTADO DE SINCRONIZACIÓN
  // =============================================================

  String _statusLabel(String status) {
    switch (_normalize(status)) {
      case 'sincronizado':
      case 'sincronizados':
      case 'synced':
        return 'Sincronizado';

      case 'error':
        return 'Error';

      case 'sincronizando':
      case 'syncing':
        return 'Sincronizando';

      case 'pendiente':
      case 'pending':
        return 'Pendiente';

      default:
        return status.trim().isEmpty ? 'Sin estado' : status.trim();
    }
  }

  bool _isSuccessful(String status) {
    final String normalized = _normalize(status);

    return normalized == 'sincronizado' ||
        normalized == 'sincronizados' ||
        normalized == 'synced';
  }

  // =============================================================
  // FILTRAR HISTORIAL
  // =============================================================

  List<_HistoryItem> get _filteredHistory {
    final String query = _normalize(_searchQuery);

    return _history.where((item) {
      final String applicantId = _normalize(item.applicantId);
      final String status = _normalize(_statusLabel(item.status));
      final String message = _normalize(item.message ?? '');

      final String formattedDate = _normalize(_formatDate(item.syncedAt));

      final String formattedTime = _normalize(_formatTime(item.syncedAt));

      final bool matchesText =
          query.isEmpty ||
          applicantId.contains(query) ||
          status.contains(query) ||
          message.contains(query) ||
          formattedDate.contains(query) ||
          formattedTime.contains(query);

      final bool matchesDate =
          _selectedDate == null ||
          (item.syncedAt.year == _selectedDate!.year &&
              item.syncedAt.month == _selectedDate!.month &&
              item.syncedAt.day == _selectedDate!.day);

      return matchesText && matchesDate;
    }).toList();
  }

  int get _totalPages => (_filteredHistory.length / _itemsPerPage).ceil();

  List<_HistoryItem> get _currentPageItems {
    final List<_HistoryItem> items = _filteredHistory;

    final int start = _currentPage * _itemsPerPage;

    if (start >= items.length) {
      return [];
    }

    final int end = (start + _itemsPerPage).clamp(0, items.length);

    return items.sublist(start, end);
  }

  void _resetPage() {
    _currentPage = 0;
  }

  void _adjustPage() {
    final int totalPages = _totalPages;

    if (totalPages == 0) {
      _currentPage = 0;
    } else if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
  }

  // =============================================================
  // SELECCIONAR REGISTROS
  // =============================================================

  void _toggleSelection(int id, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedItems.add(id);
      } else {
        _selectedItems.remove(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedItems.addAll(_currentPageItems.map((item) => item.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  // =============================================================
  // ELIMINAR UN REGISTRO
  // =============================================================

  Future<void> _confirmDelete(_HistoryItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar del historial'),
        content: Text(
          '¿Desea eliminar la referencia '
          '${item.applicantId} del historial temporal?\n\n'
          'Esto no afecta el registro del sistema central.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD94B63),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final int deletedRows = await _repository.deleteSyncHistory(item.id);

      if (deletedRows == 0) {
        throw StateError('No fue posible eliminar el registro del historial.');
      }

      await _loadHistory();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible eliminar el registro: $error')),
      );
    }
  }

  // =============================================================
  // ELIMINAR SELECCIONADOS
  // =============================================================

  Future<void> _deleteSelected() async {
    if (_selectedItems.isEmpty) {
      return;
    }

    final int selectedCount = _selectedItems.length;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar seleccionados'),
        content: Text(
          '¿Desea eliminar $selectedCount registro(s) '
          'del historial temporal?\n\n'
          'Esto no afecta los registros del sistema central.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD94B63),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final List<int> ids = List<int>.from(_selectedItems);

      for (final int id in ids) {
        await _repository.deleteSyncHistory(id);
      }

      await _loadHistory();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible eliminar los registros seleccionados: $error',
          ),
        ),
      );
    }
  }

  // =============================================================
  // VACIAR HISTORIAL
  // =============================================================

  Future<void> _confirmClearHistory() async {
    if (_history.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar historial'),
        content: const Text(
          '¿Desea eliminar todos los registros '
          'del historial temporal?\n\n'
          'Esto no elimina ningún aspirante '
          'del sistema central.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD94B63),
              foregroundColor: Colors.white,
            ),
            child: const Text('Vaciar historial'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _repository.clearSyncHistory();
      await _loadHistory();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible vaciar el historial: $error')),
      );
    }
  }

  // =============================================================
  // SELECCIONAR FECHA
  // =============================================================

  Future<void> _chooseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Filtrar historial por fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _resetPage();
      });
    }
  }

  // =============================================================
  // MENÚ DE TRES PUNTICOS
  // =============================================================

  void _handleMenu(String value) {
    switch (value) {
      case 'select':
        _selectAll();
        break;

      case 'clear_selection':
        _clearSelection();
        break;

      case 'delete_selected':
        _deleteSelected();
        break;

      case 'clear_history':
        _confirmClearHistory();
        break;
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_HistoryItem> filteredHistory = _filteredHistory;

    final List<_HistoryItem> pageItems = _currentPageItems;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF18232E) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF17345F),
          ),
        ),
        title: Text(
          'Historial',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF17345F),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenu,
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF536783)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select',
                child: ListTile(
                  leading: Icon(Icons.select_all_rounded),
                  title: Text('Seleccionar página'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_selection',
                child: ListTile(
                  leading: Icon(Icons.deselect_rounded),
                  title: Text('Quitar selección'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_selected',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFD94B63),
                  ),
                  title: Text('Eliminar seleccionados'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_history',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Color(0xFFD94B63),
                  ),
                  title: Text('Vaciar historial'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),

      // ===========================================================
      // CUERPO
      // ===========================================================
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // -----------------------------------------------
                // DESCRIPCIÓN Y BUSCADOR
                // -----------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial de sincronización',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF294765),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Consulta qué registros fueron enviados y cuál fue su resultado.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718396),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // BUSCADOR CLARO
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF202D39)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDDEAF1)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7EA9C2,
                              ).withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _resetPage();
                            });
                          },
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF263B55),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF202D39)
                                : Colors.white,
                            hintText:
                                'Buscar identificador, estado o mensaje...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8798A8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF54718C),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Filtrar por fecha',
                                  onPressed: _chooseDate,
                                  icon: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Color(0xFF1976C9),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () {
                                      _searchController.clear();

                                      setState(() {
                                        _searchQuery = '';
                                        _resetPage();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF8798A8),
                                    ),
                                  ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      if (_selectedDate != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InputChip(
                            avatar: const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Color(0xFF1976C9),
                            ),
                            label: Text(_formatDate(_selectedDate!)),
                            onDeleted: () {
                              setState(() {
                                _selectedDate = null;
                                _resetPage();
                              });
                            },
                            deleteIconColor: const Color(0xFF536783),
                            backgroundColor: const Color(0xFFEAF4FF),
                            side: BorderSide.none,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // AVISO
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD4E7F7)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.privacy_tip_outlined,
                              color: Color(0xFF1976C9),
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Solo se conserva la referencia técnica, el resultado, la fecha, los intentos y el mensaje durante un periodo temporal.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.3,
                                  color: Color(0xFF536783),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // -----------------------------------------------
                // CONTADOR Y ACCIONES
                // -----------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filteredHistory.length} registros',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF294765),
                          ),
                        ),
                      ),
                      if (_selectedItems.isNotEmpty)
                        TextButton.icon(
                          onPressed: _deleteSelected,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: Text('Eliminar (${_selectedItems.length})'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD94B63),
                          ),
                        ),
                    ],
                  ),
                ),

                // -----------------------------------------------
                // LISTA PAGINADA
                // -----------------------------------------------
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : filteredHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          itemCount: pageItems.length,
                          itemBuilder: (context, index) {
                            final _HistoryItem item = pageItems[index];

                            return _buildHistoryItem(item);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ===========================================================
      // PAGINACIÓN FIJA SOBRE LA NAVEGACIÓN DEL CELULAR
      // ===========================================================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18232E) : Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFE2ECF2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Página anterior',
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: const Color(0xFF1976C9),
                disabledColor: const Color(0xFF8798A8),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _totalPages == 0
                      ? 'Página 0 de 0'
                      : 'Página ${_currentPage + 1} de $_totalPages',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1976C9),
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Página siguiente',
                onPressed: _currentPage + 1 < _totalPages
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: const Color(0xFF1976C9),
                disabledColor: const Color(0xFF8798A8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // ESTADO DE CARGA
  // =============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1976C9)),
    );
  }

  // =============================================================
  // TARJETA DEL HISTORIAL
  // =============================================================

  Widget _buildHistoryItem(_HistoryItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool selected = _selectedItems.contains(item.id);

    final bool successful = _isSuccessful(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202D39) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF1976C9) : const Color(0xFFE2ECF2),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7EA9C2).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (value) => _toggleSelection(item.id, value),
            activeColor: const Color(0xFF1976C9),
          ),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              successful ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: successful
                  ? const Color(0xFF1976C9)
                  : const Color(0xFFD94B63),
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referencia del registro',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFB7C7D6)
                        : const Color(0xFF718396),
                  ),
                ),

                const SizedBox(height: 2),

                SelectableText(
                  item.applicantId,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF243B55),
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: successful
                            ? const Color(0xFFEAF7EF)
                            : const Color(0xFFFFEEF1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(item.status),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: successful
                              ? const Color(0xFF168A4A)
                              : const Color(0xFFD94B63),
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        '${_formatDate(item.syncedAt)} · ${_formatTime(item.syncedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF8798A8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  'Intentos: ${item.attempts}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF718396),
                  ),
                ),

                if ((item.message ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.message!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF536783),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () => _copyApplicantId(item.applicantId),
                tooltip: 'Copiar identificador',
                icon: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF1976C9),
                  size: 20,
                ),
              ),

              IconButton(
                onPressed: () => _confirmDelete(item),
                tooltip: 'Eliminar del historial',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD94B63),
                  size: 21,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // =============================================================
  // ESTADO VACÍO
  // =============================================================

  Widget _buildEmptyState() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202D39) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2ECF2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                color: Color(0xFF9BAEBC),
                size: 42,
              ),

              const SizedBox(height: 10),

              Text(
                'No hay registros en el historial',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF536783),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Los registros sincronizados aparecerán aquí durante su periodo temporal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Color(0xFF8798A8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// =============================================================
// MODELO DEL HISTORIAL DE SINCRONIZACIÓN
// =============================================================

class _HistoryItem {
  final int id;
  final String applicantId;
  final String status;
  final DateTime syncedAt;
  final int attempts;
  final String? message;

  const _HistoryItem({
    required this.id,
    required this.applicantId,
    required this.status,
    required this.syncedAt,
    required this.attempts,
    required this.message,
  });

  factory _HistoryItem.fromMap(Map<String, dynamic> map) {
    final int id = int.tryParse(map['id']?.toString() ?? '') ?? 0;

    final String applicantId = (map['applicant_id'] ?? '').toString();

    final String status = (map['status'] ?? '').toString();

    final DateTime syncedAt =
        DateTime.tryParse((map['synced_at'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final int attempts = int.tryParse(map['attempts']?.toString() ?? '') ?? 0;

    final String? rawMessage = map['message']?.toString();

    final String? message = rawMessage == null || rawMessage.trim().isEmpty
        ? null
        : rawMessage.trim();

    return _HistoryItem(
      id: id,
      applicantId: applicantId,
      status: status,
      syncedAt: syncedAt,
      attempts: attempts,
      message: message,
    );
  }
}

// =============================================================
// APLICATIVO NANCY
// Provider de Catálogos
// =============================================================

import 'package:flutter/foundation.dart';

import '../models/catalog_item_model.dart';
import '../repositories/catalog_repository.dart';

class CatalogProvider extends ChangeNotifier {
  // =============================================================
  // REPOSITORY
  // =============================================================

  final CatalogRepository _repository = CatalogRepository();

  // =============================================================
  // ESTADO
  // =============================================================

  List<CatalogItemModel> _items = [];

  bool _isLoading = false;

  String? _errorMessage;

  // =============================================================
  // GETTERS
  // =============================================================

  List<CatalogItemModel> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // =============================================================
  // CARGAR TODOS LOS CATÁLOGOS
  // =============================================================

  Future<void> loadAll() async {
    _setLoading(true);

    try {
      final List<CatalogItemModel> result = await _repository.getAll();

      _items = result;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'No fue posible cargar los catálogos.';

      debugPrint('CatalogProvider.loadAll ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // CARGAR POR TIPO
  // =============================================================

  Future<void> loadByType(String catalogType) async {
    _setLoading(true);

    try {
      final List<CatalogItemModel> result = await _repository.getByType(
        catalogType,
      );

      _items = result;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'No fue posible cargar este catálogo.';

      debugPrint('CatalogProvider.loadByType ERROR: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // AGREGAR
  // =============================================================

  Future<bool> addItem({
    required String catalogType,
    required String name,
    int parentId = 0,
  }) async {
    final String cleanName = name.trim();

    // -----------------------------------------------------------
    // VALIDACIÓN
    // -----------------------------------------------------------

    if (cleanName.isEmpty) {
      _errorMessage = 'El nombre no puede estar vacío.';
      _notify();

      return false;
    }

    try {
      _errorMessage = null;

      // ---------------------------------------------------------
      // COMPROBAR DUPLICADO
      // ---------------------------------------------------------

      final bool alreadyExists = await _repository.exists(
        catalogType: catalogType,
        name: cleanName,
      );

      if (alreadyExists) {
        _errorMessage = 'Este elemento ya existe.';
        _notify();

        return false;
      }

      // ---------------------------------------------------------
      // CREAR ELEMENTO
      // ---------------------------------------------------------

      final String now = DateTime.now().toIso8601String();

      final CatalogItemModel item = CatalogItemModel(
        catalogType: catalogType,
        name: cleanName,
        parentId: parentId,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      // ---------------------------------------------------------
      // GUARDAR EN SQLITE
      // ---------------------------------------------------------

      await _repository.insert(item);

      // ---------------------------------------------------------
      // RECARGAR LOS DATOS
      // ---------------------------------------------------------

      final List<CatalogItemModel> result = await _repository.getByType(
        catalogType,
      );

      _items = result;
      _errorMessage = null;

      // ---------------------------------------------------------
      // UNA SOLA NOTIFICACIÓN AL FINAL
      // ---------------------------------------------------------

      _notify();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible guardar el elemento.';

      debugPrint('CatalogProvider.addItem ERROR: $e');

      _notify();

      return false;
    }
  }

  // =============================================================
  // EDITAR
  // =============================================================

  Future<bool> updateItem(CatalogItemModel item) async {
    // -----------------------------------------------------------
    // VALIDAR ID
    // -----------------------------------------------------------

    if (item.id == null) {
      _errorMessage = 'El elemento no tiene un identificador válido.';
      _notify();

      return false;
    }

    // -----------------------------------------------------------
    // VALIDAR NOMBRE
    // -----------------------------------------------------------

    final String cleanName = item.name.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'El nombre no puede estar vacío.';
      _notify();

      return false;
    }

    try {
      _errorMessage = null;

      // ---------------------------------------------------------
      // CREAR ELEMENTO ACTUALIZADO
      // ---------------------------------------------------------

      final CatalogItemModel updatedItem = item.copyWith(
        name: cleanName,
        updatedAt: DateTime.now().toIso8601String(),
      );

      // ---------------------------------------------------------
      // ACTUALIZAR SQLITE
      // ---------------------------------------------------------

      await _repository.update(updatedItem);

      // ---------------------------------------------------------
      // RECARGAR DESDE SQLITE
      //
      // IMPORTANTE:
      // Ya NO llamamos loadByType().
      //
      // loadByType() hace varias notificaciones.
      // Aquí hacemos la consulta directamente y notificamos
      // solamente una vez al terminar toda la operación.
      // ---------------------------------------------------------

      final List<CatalogItemModel> result = await _repository.getByType(
        item.catalogType,
      );

      _items = result;
      _errorMessage = null;

      // ---------------------------------------------------------
      // UNA SOLA NOTIFICACIÓN
      // ---------------------------------------------------------

      _notify();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible actualizar el elemento.';

      debugPrint('CatalogProvider.updateItem ERROR: $e');

      _notify();

      return false;
    }
  }

  // =============================================================
  // ELIMINAR
  // =============================================================

  Future<bool> deleteItem(CatalogItemModel item) async {
    // -----------------------------------------------------------
    // VALIDAR ID
    // -----------------------------------------------------------

    if (item.id == null) {
      _errorMessage = 'El elemento no tiene un identificador válido.';
      _notify();

      return false;
    }

    try {
      _errorMessage = null;

      // ---------------------------------------------------------
      // ELIMINAR DE SQLITE
      // ---------------------------------------------------------

      await _repository.delete(item.id!);

      // ---------------------------------------------------------
      // RECARGAR DESDE SQLITE
      // ---------------------------------------------------------

      final List<CatalogItemModel> result = await _repository.getByType(
        item.catalogType,
      );

      _items = result;
      _errorMessage = null;

      // ---------------------------------------------------------
      // UNA SOLA NOTIFICACIÓN
      // ---------------------------------------------------------

      _notify();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible eliminar el elemento.';

      debugPrint('CatalogProvider.deleteItem ERROR: $e');

      _notify();

      return false;
    }
  }

  // =============================================================
  // DESACTIVAR
  // =============================================================

  Future<bool> deactivateItem(CatalogItemModel item) async {
    if (item.id == null) {
      _errorMessage = 'El elemento no tiene un identificador válido.';
      _notify();

      return false;
    }

    try {
      _errorMessage = null;

      await _repository.deactivate(item.id!);

      final List<CatalogItemModel> result = await _repository.getByType(
        item.catalogType,
      );

      _items = result;
      _errorMessage = null;

      _notify();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible desactivar el elemento.';

      debugPrint('CatalogProvider.deactivateItem ERROR: $e');

      _notify();

      return false;
    }
  }

  // =============================================================
  // ACTIVAR
  // =============================================================

  Future<bool> activateItem(CatalogItemModel item) async {
    if (item.id == null) {
      _errorMessage = 'El elemento no tiene un identificador válido.';
      _notify();

      return false;
    }

    try {
      _errorMessage = null;

      await _repository.activate(item.id!);

      final List<CatalogItemModel> result = await _repository.getByType(
        item.catalogType,
      );

      _items = result;
      _errorMessage = null;

      _notify();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible activar el elemento.';

      debugPrint('CatalogProvider.activateItem ERROR: $e');

      _notify();

      return false;
    }
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    _notify();
  }

  // =============================================================
  // ESTADO DE CARGA
  // =============================================================

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;

    _notify();
  }

  // =============================================================
  // NOTIFICAR CAMBIOS
  // =============================================================

  void _notify() {
    if (!hasListeners) {
      return;
    }

    notifyListeners();
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _items = [];
    _errorMessage = null;

    super.dispose();
  }
}

// =============================================================
// APLICATIVO NANCY
// Modelo de elemento de catálogo
// =============================================================

class CatalogItemModel {
  // ===========================================================
  // IDENTIFICACIÓN
  // ===========================================================

  final int? id;

  // ===========================================================
  // TIPO DE CATÁLOGO
  // ===========================================================

  final String catalogType;

  // ===========================================================
  // NOMBRE
  // ===========================================================

  final String name;

  // ===========================================================
  // RELACIÓN CON OTRO CATÁLOGO
  // ===========================================================

  final int parentId;

  // ===========================================================
  // ESTADO
  // ===========================================================

  final bool active;

  // ===========================================================
  // FECHAS
  // ===========================================================

  final String createdAt;

  final String updatedAt;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const CatalogItemModel({
    this.id,
    required this.catalogType,
    required this.name,
    this.parentId = 0,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===========================================================
  // COPIAR
  // ===========================================================

  CatalogItemModel copyWith({
    int? id,
    String? catalogType,
    String? name,
    int? parentId,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) {
    return CatalogItemModel(
      id: id ?? this.id,
      catalogType: catalogType ?? this.catalogType,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===========================================================
  // CONVERTIR A MAP
  // ===========================================================

  Map<String, dynamic> toMap() {
    return {
      // ---------------------------------------------------------
      // IMPORTANTE:
      //
      // Cuando se crea un elemento nuevo, id es null.
      // SQLite se encarga de generar el AUTOINCREMENT.
      // ---------------------------------------------------------
      'id': id,

      'catalog_type': catalogType,

      'name': name,

      'parent_id': parentId,

      // SQLite almacena bool como INTEGER:
      // 1 = activo
      // 0 = inactivo.
      'active': active ? 1 : 0,

      'created_at': createdAt,

      'updated_at': updatedAt,
    };
  }

  // ===========================================================
  // CREAR DESDE MAP
  // ===========================================================

  factory CatalogItemModel.fromMap(Map<String, dynamic> map) {
    // -----------------------------------------------------------
    // ID
    // -----------------------------------------------------------

    final dynamic rawId = map['id'];

    int? parsedId;

    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is num) {
      parsedId = rawId.toInt();
    } else if (rawId != null) {
      parsedId = int.tryParse(rawId.toString());
    }

    // -----------------------------------------------------------
    // TIPO
    // -----------------------------------------------------------

    final String parsedCatalogType = map['catalog_type']?.toString() ?? '';

    // -----------------------------------------------------------
    // NOMBRE
    // -----------------------------------------------------------

    final String parsedName = map['name']?.toString() ?? '';

    // -----------------------------------------------------------
    // PARENT ID
    // -----------------------------------------------------------

    final dynamic rawParentId = map['parent_id'];

    int parsedParentId = 0;

    if (rawParentId is int) {
      parsedParentId = rawParentId;
    } else if (rawParentId is num) {
      parsedParentId = rawParentId.toInt();
    } else if (rawParentId != null) {
      parsedParentId = int.tryParse(rawParentId.toString()) ?? 0;
    }

    // -----------------------------------------------------------
    // ESTADO
    // -----------------------------------------------------------

    final dynamic rawActive = map['active'];

    bool parsedActive = true;

    if (rawActive is bool) {
      parsedActive = rawActive;
    } else if (rawActive is num) {
      parsedActive = rawActive != 0;
    } else if (rawActive != null) {
      final String value = rawActive.toString().toLowerCase().trim();

      parsedActive = value == '1' || value == 'true' || value == 'yes';
    }

    // -----------------------------------------------------------
    // FECHA DE CREACIÓN
    // -----------------------------------------------------------

    final String parsedCreatedAt = map['created_at']?.toString() ?? '';

    // -----------------------------------------------------------
    // FECHA DE ACTUALIZACIÓN
    // -----------------------------------------------------------

    final String parsedUpdatedAt = map['updated_at']?.toString() ?? '';

    // -----------------------------------------------------------
    // CREAR MODELO
    // -----------------------------------------------------------

    return CatalogItemModel(
      id: parsedId,
      catalogType: parsedCatalogType,
      name: parsedName,
      parentId: parsedParentId,
      active: parsedActive,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  // ===========================================================
  // REPRESENTACIÓN DE TEXTO
  // ===========================================================

  @override
  String toString() {
    return 'CatalogItemModel('
        'id: $id, '
        'catalogType: $catalogType, '
        'name: $name, '
        'parentId: $parentId, '
        'active: $active, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}

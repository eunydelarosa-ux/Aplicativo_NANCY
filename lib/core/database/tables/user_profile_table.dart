// ===============================================================
// ===============================================================

// APLICATIVO NANCY

// Tabla de perfil del usuario

// ===============================================================

class UserProfileTable {
  UserProfileTable._();

  // =============================================================
  // NOMBRE DE LA TABLA
  // =============================================================

  static const String tableName = 'user_profile';

  // =============================================================
  // COLUMNAS
  // =============================================================

  static const String id = 'id';

  static const String name = 'name';

  static const String username = 'username';

  static const String role = 'role';

  static const String email = 'email';

  static const String phone = 'phone';

  static const String cedula = 'cedula';

  static const String municipalityId = 'municipality_id';

  static const String siteId = 'site_id';

  static const String createdByUserId = 'created_by_user_id';

  static const String passwordHash = 'password_hash';

  static const String isActive = 'is_active';

  static const String activationCodeHash = 'activation_code_hash';

  static const String mustChangePassword = 'must_change_password';

  static const String imagePath = 'image_path';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  // =============================================================
  // CREACIÓN DE LA TABLA
  // =============================================================

  static const String createTable =
      '''
    CREATE TABLE $tableName (

      $id INTEGER PRIMARY KEY AUTOINCREMENT,

      $name TEXT NOT NULL,

      $username TEXT NOT NULL UNIQUE,

      $role TEXT NOT NULL,

      $email TEXT,

      $phone TEXT,

      $cedula TEXT,
$municipalityId INTEGER,

$siteId INTEGER,

$createdByUserId INTEGER,

$passwordHash TEXT NOT NULL,

      $isActive INTEGER NOT NULL DEFAULT 1,

$activationCodeHash TEXT,

$mustChangePassword INTEGER NOT NULL DEFAULT 0,

      $imagePath TEXT,

    $createdAt TEXT NOT NULL,
$updatedAt TEXT NOT NULL


    )
  ''';
}

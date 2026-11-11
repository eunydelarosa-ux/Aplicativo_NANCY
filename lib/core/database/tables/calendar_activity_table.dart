// =============================================================
// APLICATIVO NANCY
// Tabla de actividades del calendario
// =============================================================

class CalendarActivityTable {
  CalendarActivityTable._();

  static const String tableName = 'calendar_activities';

  static const String userIdColumn = 'user_id';

  static const String createTable = '''
    CREATE TABLE IF NOT EXISTS calendar_activities (
      id TEXT PRIMARY KEY,
      user_id INTEGER,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      time TEXT NOT NULL,
      description TEXT NOT NULL
    )
  ''';
}

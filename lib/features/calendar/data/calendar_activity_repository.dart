import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/database/tables/calendar_activity_table.dart';
import '../../session/session_manager.dart';
import '../models/calendar_activity_model.dart';

class CalendarActivityRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  int? get _currentUserId => SessionManager.instance.currentUser?.id;

  Future<List<CalendarActivity>> getAllActivities() async {
    final int? userId = _currentUserId;

    // Sin una sesión activa, no se muestran actividades.
    if (userId == null) {
      return [];
    }

    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      CalendarActivityTable.tableName,
      where: '${CalendarActivityTable.userIdColumn} = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );

    return result.map(CalendarActivity.fromMap).toList();
  }

  Future<void> insertActivity(CalendarActivity activity) async {
    final int? userId = _currentUserId;

    if (userId == null) {
      throw StateError(
        'No hay una sesión activa para guardar la actividad del calendario.',
      );
    }

    final Database db = await _databaseHelper.database;

    final Map<String, dynamic> data = activity.toMap();

    // Guardar la actividad con el usuario que inició sesión.
    data[CalendarActivityTable.userIdColumn] = userId;

    await db.insert(
      CalendarActivityTable.tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> deleteActivity(String id) async {
    final int? userId = _currentUserId;

    if (userId == null) {
      throw StateError(
        'No hay una sesión activa para eliminar la actividad del calendario.',
      );
    }

    final Database db = await _databaseHelper.database;

    // Solo se puede eliminar una actividad del usuario actual.
    await db.delete(
      CalendarActivityTable.tableName,
      where: 'id = ? AND ${CalendarActivityTable.userIdColumn} = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> updateActivity(CalendarActivity activity) async {
    final int? userId = _currentUserId;

    if (userId == null) {
      throw StateError(
        'No hay una sesión activa para editar la actividad del calendario.',
      );
    }

    final Database db = await _databaseHelper.database;

    // Solo se puede editar una actividad del usuario actual.
    await db.update(
      CalendarActivityTable.tableName,
      activity.toMap(),
      where: 'id = ? AND ${CalendarActivityTable.userIdColumn} = ?',
      whereArgs: [activity.id, userId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}

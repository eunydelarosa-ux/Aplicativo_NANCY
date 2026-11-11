import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio encargado de programar y cancelar
/// las notificaciones de las actividades del calendario.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializa el servicio de notificaciones.
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar zonas horarias.
    tz.initializeTimeZones();

    // Zona horaria de Colombia.
    tz.setLocalLocation(tz.getLocation('America/Bogota'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(initializationSettings);

    // Permisos de Android.
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    // Solicitar permiso para alarmas exactas en Android.
    await androidPlugin?.requestExactAlarmsPermission();

    // Permisos de iOS.
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Programa una notificación para una actividad del calendario.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await initialize();

    // No programar notificaciones para fechas pasadas.
    if (!scheduledDate.isAfter(DateTime.now())) return;

    final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'nancy_calendar_channel',
        'Recordatorios del calendario',
        channelDescription:
            'Notificaciones de las actividades programadas en NANCY',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails,

      // Solicita programación exacta incluso en modo de ahorro.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancela la notificación de una actividad.
  Future<void> cancelNotification(int id) async {
    await initialize();
    await _notifications.cancel(id);
  }

  /// Cancela todas las notificaciones programadas.
  Future<void> cancelAllNotifications() async {
    await initialize();
    await _notifications.cancelAll();
  }
}

import 'package:flutter/material.dart';
import '../../data/calendar_activity_repository.dart';
import '../../models/calendar_activity_model.dart';
import '../../../../services/notification_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final CalendarActivityRepository _repository = CalendarActivityRepository();

  bool _isDark = false;

  List<CalendarActivity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _repository.getAllActivities();

      if (!mounted) return;

      setState(() {
        _activities = activities;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible cargar las actividades.')),
      );
    }
  }

  final List<String> _months = const [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  final List<String> _weekDays = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  List<CalendarActivity> get _selectedDayActivities {
    final items = _activities
        .where((activity) => _isSameDay(activity.date, _selectedDay))
        .toList();
    items.sort(
      (a, b) => _timeSortValue(a.time).compareTo(_timeSortValue(b.time)),
    );
    return items;
  }

  int _timeSortValue(String time) {
    final normalized = time.trim().toUpperCase();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    ).firstMatch(normalized);
    if (match == null) return 0;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3);
    if (period == 'AM' && hour == 12) hour = 0;
    if (period == 'PM' && hour != 12) hour += 12;
    return hour * 60 + minute;
  }

  DateTime? _getActivityDateTime(DateTime date, String time) {
    final normalized = time.trim().toUpperCase();

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    ).firstMatch(normalized);

    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3);

    if (period == 'AM' && hour == 12) hour = 0;
    if (period == 'PM' && hour != 12) hour += 12;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _hasActivity(DateTime day) =>
      _activities.any((activity) => _isSameDay(activity.date, day));

  String _formatSelectedDate(DateTime date) =>
      '${date.day} de ${_months[date.month - 1]} de ${date.year}';

  Future<void> _showAddActivityDialog() async {
    final result = await showDialog<_CalendarActivityDraft>(
      context: context,
      builder: (_) => _AddCalendarActivityDialog(
        selectedDate: _selectedDay,
        formattedDate: _formatSelectedDate(_selectedDay),
      ),
    );

    if (result == null || !mounted) return;

    final activity = CalendarActivity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: result.title,
      date: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day),
      time: result.time,
      description: result.description.isEmpty
          ? 'Sin descripción.'
          : result.description,
    );

    try {
      // 1. Guardar la actividad en SQLite.
      await _repository.insertActivity(activity);

      // 2. Programar la notificación sin afectar el guardado.
      try {
        final notificationDate = _getActivityDateTime(
          activity.date,
          activity.time,
        );

        if (notificationDate != null) {
          final parsedId = int.tryParse(activity.id);

          final notificationId = parsedId == null
              ? activity.id.codeUnits.fold<int>(
                  0,
                  (value, unit) => (value * 31 + unit) & 0x7FFFFFFF,
                )
              : parsedId % 2147483647;

          await NotificationService.instance.scheduleNotification(
            id: notificationId,
            title: activity.title,
            body: activity.description,
            scheduledDate: notificationDate,
          );
        }
      } catch (e) {
        debugPrint('Error al programar la notificación: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La actividad se guardó, pero no se pudo programar el recordatorio.',
              ),
            ),
          );
        }
      }

      // 3. Actualizar las actividades mostradas.
      await _loadActivities();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible guardar la actividad.')),
      );
    }
  }

  Future<void> _showEditActivityDialog(CalendarActivity activity) async {
    final result = await showDialog<_CalendarActivityDraft>(
      context: context,
      builder: (_) => _AddCalendarActivityDialog(
        selectedDate: activity.date,
        formattedDate: _formatSelectedDate(activity.date),
        initialActivity: activity,
      ),
    );

    if (result == null || !mounted) return;

    final updatedActivity = CalendarActivity(
      id: activity.id,
      title: result.title,
      date: activity.date,
      time: result.time,
      description: result.description.isEmpty
          ? 'Sin descripción.'
          : result.description,
    );

    try {
      await _repository.updateActivity(updatedActivity);

      final parsedId = int.tryParse(activity.id);

      final notificationId = parsedId == null
          ? activity.id.codeUnits.fold<int>(
              0,
              (value, unit) => (value * 31 + unit) & 0x7FFFFFFF,
            )
          : parsedId % 2147483647;

      try {
        await NotificationService.instance.cancelNotification(notificationId);

        final notificationDate = _getActivityDateTime(
          updatedActivity.date,
          updatedActivity.time,
        );

        if (notificationDate != null) {
          await NotificationService.instance.scheduleNotification(
            id: notificationId,
            title: updatedActivity.title,
            body: updatedActivity.description,
            scheduledDate: notificationDate,
          );
        }
      } catch (e) {
        debugPrint('Error al actualizar la notificación: $e');
      }

      await _loadActivities();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad actualizada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible actualizar la actividad.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteActivity(CalendarActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1B2733) : null,
        title: Text(
          'Eliminar actividad',
          style: TextStyle(
            color: _isDark ? Colors.white : const Color(0xFF243B55),
          ),
        ),
        content: Text(
          '¿Deseas eliminar "${activity.title}"?',
          style: TextStyle(
            color: _isDark ? Colors.white : const Color(0xFF526D85),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: _isDark ? Colors.white : null),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 1. Eliminar la actividad de SQLite.
        await _repository.deleteActivity(activity.id);

        // 2. Cancelar su notificación programada.
        try {
          final parsedId = int.tryParse(activity.id);

          final notificationId = parsedId == null
              ? activity.id.codeUnits.fold<int>(
                  0,
                  (value, unit) => (value * 31 + unit) & 0x7FFFFFFF,
                )
              : parsedId % 2147483647;

          await NotificationService.instance.cancelNotification(notificationId);
        } catch (e) {
          debugPrint('Error al cancelar la notificación: $e');
        }

        // 3. Actualizar la lista de actividades.
        await _loadActivities();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Actividad eliminada.')));
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible eliminar la actividad.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    final monthName = _months[_currentMonth.month - 1];

    return Scaffold(
      backgroundColor: _isDark
          ? const Color(0xFF101820)
          : const Color(0xFFEAF6FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActivityDialog,
        backgroundColor: const Color(0xFF1976C9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar actividad'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDark
                ? const [
                    Color(0xFF071321),
                    Color(0xFF10243A),
                    Color(0xFF152535),
                    Color(0xFF101820),
                  ]
                : const [
                    Color(0xFF0057B8),
                    Color(0xFF0A3D91),
                    Color(0xFF9DD0EE),
                    Color(0xFFEAF6FC),
                    Colors.white,
                    Color(0xFFF4FBF8),
                    Color(0xFFE1F4E9),
                  ],
            stops: _isDark
                ? const [0.00, 0.18, 0.42, 1.00]
                : const [0.00, 0.10, 0.20, 0.30, 0.50, 0.78, 1.00],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 20),
                      Text(
                        'Calendario',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF17345F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildCalendarCard(monthName),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Actividades del día',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _isDark
                                    ? Colors.white
                                    : const Color(0xFF17345F),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? const Color(0xFF263747)
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selectedDayActivities.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _isDark
                                    ? Colors.white
                                    : const Color(0xFF1976C9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSelectedDate(_selectedDay),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF526D85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedDayActivities.isEmpty)
                        _buildEmptyActivities()
                      else
                        ..._selectedDayActivities.map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildActivityCard(activity),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi calendario',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Organiza tus actividades',
                  style: TextStyle(fontSize: 12, color: Color(0xFFD8E9F8)),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _isDark
            ? const Color(0xFF1B2733)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _isDark ? const Color(0xFF344454) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17345F).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDark
                    ? const [Color(0xFF263747), Color(0xFF223A3A)]
                    : const [Color(0xFFEAF4FF), Color(0xFFE8F7F3)],
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: _isDark
                    ? const Color(0xFF3A4B5C)
                    : const Color(0xFFD5E7F4),
              ),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Color(0xFF1976C9),
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organiza tu jornada',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? Colors.white : const Color(0xFF243B55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulta las actividades y mantén organizados tus procesos.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _isDark ? Colors.white : const Color(0xFF718396),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(String monthName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark
            ? const Color(0xFF1B2733)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _isDark ? const Color(0xFF344454) : const Color(0xFFD6E8F5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B8AA5).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMonthButton(
                icon: Icons.chevron_left_rounded,
                onTap: _previousMonth,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      monthName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _isDark ? Colors.white : const Color(0xFF17345F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_currentMonth.year}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isDark ? Colors.white : const Color(0xFF718396),
                      ),
                    ),
                  ],
                ),
              ),
              _buildMonthButton(
                icon: Icons.chevron_right_rounded,
                onTap: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: _weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF718396),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          _buildDaysGrid(),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            height: 1,
            color: _isDark ? const Color(0xFF344454) : const Color(0xFFE6EEF4),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(
                color: const Color(0xFF1976C9),
                label: 'Día seleccionado',
              ),
              const SizedBox(width: 15),
              _buildLegend(color: const Color(0xFF168A4A), label: 'Actividad'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF263747) : const Color(0xFFEAF4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isDark
                  ? const Color(0xFF3A4B5C)
                  : const Color(0xFFD5E7F4),
            ),
          ),
          child: Icon(
            icon,
            color: _isDark ? Colors.white : const Color(0xFF1976C9),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildDaysGrid() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final startingWeekday = firstDayOfMonth.weekday - 1;
    final daysInMonth = lastDayOfMonth.day;
    final List<Widget> dayWidgets = [];

    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(
        _buildDayItem(DateTime(_currentMonth.year, _currentMonth.month, day)),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 4,
      children: dayWidgets,
    );
  }

  Widget _buildDayItem(DateTime date) {
    final isSelected = _isSameDay(date, _selectedDay);
    final isToday = _isSameDay(date, DateTime.now());
    final hasActivity = _hasActivity(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedDay = date),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1976C9)
                : isToday
                ? (_isDark ? const Color(0xFF263747) : const Color(0xFFEAF4FF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isToday && !isSelected
                ? Border.all(
                    color: _isDark
                        ? const Color(0xFF526D85)
                        : const Color(0xFF9CC8ED),
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: (isSelected || _isDark)
                      ? Colors.white
                      : const Color(0xFF354B63),
                ),
              ),
              if (hasActivity)
                Positioned(
                  bottom: 3,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF168A4A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: _isDark ? Colors.white : const Color(0xFF718396),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyActivities() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark
            ? const Color(0xFF1B2733)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isDark ? const Color(0xFF344454) : const Color(0xFFD6E8F5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 32,
            color: _isDark ? Colors.white : const Color(0xFF8AA2B7),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay actividades para este día',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _isDark ? Colors.white : const Color(0xFF526D85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Puedes agregar una actividad con el botón inferior.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _isDark ? Colors.white : const Color(0xFF718396),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(CalendarActivity activity) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isDark
              ? const Color(0xFF1B2733)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activity.color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: activity.color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: activity.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: activity.color.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(activity.icon, color: activity.color, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _isDark ? Colors.white : const Color(0xFF243B55),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: _isDark ? Colors.white : const Color(0xFF718396),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: activity.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.time,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: activity.color,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar actividad',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showEditActivityDialog(activity),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: _isDark ? Colors.white : const Color(0xFF1976C9),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar actividad',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDeleteActivity(activity),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: _isDark ? Colors.white : const Color(0xFFCC4B4B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarActivityDraft {
  final String title;
  final String time;
  final String description;

  const _CalendarActivityDraft({
    required this.title,
    required this.time,
    required this.description,
  });
}

class _AddCalendarActivityDialog extends StatefulWidget {
  final DateTime selectedDate;
  final String formattedDate;
  final CalendarActivity? initialActivity;

  const _AddCalendarActivityDialog({
    required this.selectedDate,
    required this.formattedDate,
    this.initialActivity,
  });

  @override
  State<_AddCalendarActivityDialog> createState() =>
      _AddCalendarActivityDialogState();
}

class _AddCalendarActivityDialogState
    extends State<_AddCalendarActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();

    final activity = widget.initialActivity;

    _titleController = TextEditingController(text: activity?.title ?? '');

    _descriptionController = TextEditingController(
      text: activity?.description == 'Sin descripción.'
          ? ''
          : activity?.description ?? '',
    );

    if (activity != null) {
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      ).firstMatch(activity.time.trim().toUpperCase());

      if (match != null) {
        var hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3);

        if (period == 'AM' && hour == 12) hour = 0;
        if (period == 'PM' && hour != 12) hour += 12;

        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickTime() async {
    final initialTime = _selectedTime ?? TimeOfDay.now();

    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _TimePickerDialog(initialTime: initialTime),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldTextColor = isDark ? Colors.white : const Color(0xFF263238);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF526D85);
    final borderColor = isDark ? Colors.white30 : const Color(0xFFB0BEC5);
    const focusedColor = Color(0xFF1976C9);
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1B2733) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.initialActivity == null ? 'Nueva actividad' : 'Editar actividad',
        style: TextStyle(color: isDark ? Colors.white : null),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.formattedDate,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1976C9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                style: TextStyle(color: fieldTextColor),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre de la actividad *',
                  hintText: 'Ej. Reunión con aspirantes',
                  labelStyle: TextStyle(color: labelColor),
                  floatingLabelStyle: const TextStyle(color: focusedColor),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF78909C),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: focusedColor, width: 2),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el nombre de la actividad'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Hora de la actividad *',
                    labelStyle: TextStyle(color: labelColor),
                    floatingLabelStyle: const TextStyle(color: focusedColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: focusedColor, width: 2),
                    ),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(
                      Icons.access_time_rounded,
                      color: focusedColor,
                    ),
                  ),
                  child: Text(
                    _selectedTime == null
                        ? 'Toca para elegir la hora'
                        : _formatTime(_selectedTime!),
                    style: TextStyle(
                      color: _selectedTime == null
                          ? Theme.of(context).hintColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: _selectedTime == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: fieldTextColor),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Agrega detalles...',
                  labelStyle: TextStyle(color: labelColor),
                  floatingLabelStyle: const TextStyle(color: focusedColor),
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF78909C),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: focusedColor, width: 2),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: isDark ? Colors.white : null),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_selectedTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selecciona la hora de la actividad.'),
                ),
              );
              return;
            }

            Navigator.pop(
              context,
              _CalendarActivityDraft(
                title: _titleController.text.trim(),
                time: _formatTime(_selectedTime!),
                description: _descriptionController.text.trim(),
              ),
            );
          },
          child: Text(
            widget.initialActivity == null
                ? 'Guardar actividad'
                : 'Guardar cambios',
          ),
        ),
      ],
    );
  }
}

class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _TimePickerDialog({required this.initialTime});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;

  late int _selectedHour;
  late int _selectedMinute;
  late String _selectedPeriod;

  @override
  void initState() {
    super.initState();

    final initialTime = widget.initialTime;

    _selectedHour = initialTime.hourOfPeriod == 0
        ? 12
        : initialTime.hourOfPeriod;

    _selectedMinute = initialTime.minute;

    _selectedPeriod = initialTime.period == DayPeriod.am ? 'AM' : 'PM';

    _hourController = TextEditingController(
      text: _selectedHour.toString().padLeft(2, '0'),
    );

    _minuteController = TextEditingController(
      text: _selectedMinute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldTextColor = isDark ? Colors.white : const Color(0xFF263238);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF526D85);
    final borderColor = isDark ? Colors.white30 : const Color(0xFFB0BEC5);
    const focusedColor = Color(0xFF1976C9);
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1B2733) : null,
      title: Text(
        'Seleccionar hora',
        style: TextStyle(color: isDark ? Colors.white : null),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona o escribe la hora.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : null),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedHour,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Hora',
                        labelStyle: TextStyle(color: labelColor),
                        floatingLabelStyle: const TextStyle(
                          color: focusedColor,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: focusedColor, width: 2),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      style: TextStyle(color: fieldTextColor),
                      dropdownColor: isDark
                          ? const Color(0xFF1B2733)
                          : Colors.white,
                      items: List.generate(12, (index) {
                        final hour = index + 1;

                        return DropdownMenuItem<int>(
                          value: hour,
                          child: Text(hour.toString().padLeft(2, '0')),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedHour = value;
                          _hourController.text = value.toString().padLeft(
                            2,
                            '0',
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedMinute,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Minutos',
                        labelStyle: TextStyle(color: labelColor),
                        floatingLabelStyle: const TextStyle(
                          color: focusedColor,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: focusedColor, width: 2),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      style: TextStyle(color: fieldTextColor),
                      dropdownColor: isDark
                          ? const Color(0xFF1B2733)
                          : Colors.white,
                      items: List.generate(60, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(index.toString().padLeft(2, '0')),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedMinute = value;
                          _minuteController.text = value.toString().padLeft(
                            2,
                            '0',
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Text(
                    'Periodo:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(value: 'AM', label: Text('AM')),
                        ButtonSegment<String>(value: 'PM', label: Text('PM')),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedPeriod = selection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'O escribe la hora manualmente',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : null,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hourController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        labelText: 'Hora (1-12)',
                        counterText: '',
                        labelStyle: TextStyle(color: labelColor),
                        floatingLabelStyle: const TextStyle(
                          color: focusedColor,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: focusedColor, width: 2),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      style: TextStyle(color: fieldTextColor),
                      validator: (value) {
                        final hour = int.tryParse(value ?? '');

                        if (hour == null || hour < 1 || hour > 12) {
                          return '1 a 12';
                        }

                        return null;
                      },
                      onChanged: (value) {
                        final hour = int.tryParse(value);

                        if (hour != null && hour >= 1 && hour <= 12) {
                          setState(() {
                            _selectedHour = hour;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _minuteController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: InputDecoration(
                        labelText: 'Minutos (0-59)',
                        counterText: '',
                        labelStyle: TextStyle(color: labelColor),
                        floatingLabelStyle: const TextStyle(
                          color: focusedColor,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: focusedColor, width: 2),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      style: TextStyle(color: fieldTextColor),
                      validator: (value) {
                        final minute = int.tryParse(value ?? '');

                        if (minute == null || minute < 0 || minute > 59) {
                          return '0 a 59';
                        }

                        return null;
                      },
                      onChanged: (value) {
                        final minute = int.tryParse(value);

                        if (minute != null && minute >= 0 && minute <= 59) {
                          setState(() {
                            _selectedMinute = minute;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: isDark ? Colors.white : null),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final hour = int.parse(_hourController.text);
            final minute = int.parse(_minuteController.text);

            int hour24 = hour % 12;

            if (_selectedPeriod == 'PM') {
              hour24 += 12;
            }

            Navigator.pop(context, TimeOfDay(hour: hour24, minute: minute));
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

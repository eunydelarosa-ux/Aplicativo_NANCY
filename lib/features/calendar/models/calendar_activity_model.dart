import 'package:flutter/material.dart';

class CalendarActivity {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final String description;

  const CalendarActivity({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.description,
  });

  // Apariencia utilizada por las tarjetas del calendario.
  IconData get icon => Icons.event_note_rounded;

  Color get color => const Color(0xFF1976C9);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'time': time,
      'description': description,
    };
  }

  factory CalendarActivity.fromMap(Map<String, dynamic> map) {
    return CalendarActivity(
      id: map['id'].toString(),
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String,
      description: map['description'] as String,
    );
  }
}

import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String name;
  final Color color;
  final bool isCompleted;
  final DateTime createdAt;
  final List<DateTime> completedDates;

  Habit({
    required this.id,
    required this.name,
    required this.color,
    this.isCompleted = false,
    required this.createdAt,
    required this.completedDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedDates': completedDates.map((date) => date.millisecondsSinceEpoch).toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      completedDates: (json['completedDates'] as List<dynamic>?)
          ?.map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp))
          .toList() ?? [],
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    Color? color,
    bool? isCompleted,
    DateTime? createdAt,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  bool isCompletedToday() {
    final today = DateTime.now();
    return completedDates.any((date) => 
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day
    );
  }
}

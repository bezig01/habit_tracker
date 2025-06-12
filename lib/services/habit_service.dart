import 'dart:math';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';

class HabitService {
  final StorageService _storageService = StorageService();

  Future<List<Habit>> getHabits() async {
    return await _storageService.getHabits();
  }

  Future<void> addHabit(String name, Color color) async {
    final habits = await getHabits();
    final newHabit = Habit(
      id: _generateId(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
      completedDates: [],
    );
    habits.add(newHabit);
    await _storageService.saveHabits(habits);
  }
  
  // This method adds a habit and returns it
  Future<Habit> addHabitAndReturn(String name, Color color) async {
    final habits = await getHabits();
    final newHabit = Habit(
      id: _generateId(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
      completedDates: [],
    );
    habits.add(newHabit);
    await _storageService.saveHabits(habits);
    return newHabit;
  }
  
  // This method adds multiple habits at once
  Future<List<Habit>> addMultipleHabits(List<Map<String, dynamic>> habitsData) async {
    final habits = await getHabits();
    final newHabits = <Habit>[];
    
    for (var habitData in habitsData) {
      final newHabit = Habit(
        id: _generateId(),
        name: habitData['name'],
        color: habitData['color'],
        createdAt: DateTime.now(),
        completedDates: [],
      );
      newHabits.add(newHabit);
      habits.add(newHabit);
    }
    
    await _storageService.saveHabits(habits);
    return newHabits;
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await getHabits();
    habits.removeWhere((habit) => habit.id == habitId);
    await _storageService.saveHabits(habits);
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    final habits = await getHabits();
    final habitIndex = habits.indexWhere((habit) => habit.id == habitId);
    
    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      final today = DateTime.now();
      final isCompletedToday = habit.isCompletedToday();
      
      List<DateTime> updatedCompletedDates = List.from(habit.completedDates);
      
      if (isCompletedToday) {
        // Remove today's completion
        updatedCompletedDates.removeWhere((date) => 
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day
        );
      } else {
        // Add today's completion
        updatedCompletedDates.add(DateTime(today.year, today.month, today.day));
      }
      
      final updatedHabit = habit.copyWith(
        completedDates: updatedCompletedDates,
      );
      
      habits[habitIndex] = updatedHabit;
      await _storageService.saveHabits(habits);
    }
  }

  Future<Map<String, int>> getWeeklyProgress() async {
    final habits = await getHabits();
    final Map<String, int> weeklyProgress = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: now.weekday - 1 - i));
      final dayName = weekdays[i];
      
      int completedCount = 0;
      for (final habit in habits) {
        if (habit.completedDates.any((completedDate) =>
          completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day
        )) {
          completedCount++;
        }
      }
      weeklyProgress[dayName] = completedCount;
    }

    return weeklyProgress;
  }

  Future<List<Habit>> getTodayCompletedHabits() async {
    final habits = await getHabits();
    return habits.where((habit) => habit.isCompletedToday()).toList();
  }

  Future<List<Habit>> getTodayIncompleteHabits() async {
    final habits = await getHabits();
    return habits.where((habit) => !habit.isCompletedToday()).toList();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}

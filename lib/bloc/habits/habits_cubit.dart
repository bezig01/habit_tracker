import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';
import 'habits_state.dart';

class HabitsCubit extends Cubit<HabitsState> {
  final HabitService _habitService;

  HabitsCubit(this._habitService) : super(HabitsInitial());

  Future<void> loadHabits() async {
    emit(HabitsLoading());
    try {
      final habits = await _habitService.getHabits();
      final completedHabits = await _habitService.getTodayCompletedHabits();
      final incompleteHabits = await _habitService.getTodayIncompleteHabits();
      
      emit(HabitsLoaded(
        habits: habits,
        completedHabits: completedHabits,
        incompleteHabits: incompleteHabits,
      ));
    } catch (e) {
      emit(const HabitsError('Failed to load habits'));
    }
  }

  Future<void> addHabit(String name, Color color) async {
    emit(HabitsLoading());
    try {
      await _habitService.addHabit(name, color);
      
      // Reload habits after adding
      final habits = await _habitService.getHabits();
      final completedHabits = await _habitService.getTodayCompletedHabits();
      final incompleteHabits = await _habitService.getTodayIncompleteHabits();
      
      emit(HabitsOperationSuccess(
        message: 'Habit added successfully!',
        habits: habits,
        completedHabits: completedHabits,
        incompleteHabits: incompleteHabits,
      ));
    } catch (e) {
      emit(const HabitsError('Failed to add habit'));
    }
  }
  
  // This method adds multiple habits at once
  Future<void> addMultipleHabits(List<Map<String, dynamic>> habitsData) async {
    emit(HabitsLoading());
    try {
      await _habitService.addMultipleHabits(habitsData);
      
      // Reload habits after adding all
      final habits = await _habitService.getHabits();
      final completedHabits = await _habitService.getTodayCompletedHabits();
      final incompleteHabits = await _habitService.getTodayIncompleteHabits();
      
      emit(HabitsOperationSuccess(
        message: 'Habits added successfully!',
        habits: habits,
        completedHabits: completedHabits,
        incompleteHabits: incompleteHabits,
      ));
    } catch (e) {
      emit(const HabitsError('Failed to add habits'));
    }
  }

  Future<void> deleteHabit(String habitId) async {
    emit(HabitsLoading());
    try {
      await _habitService.deleteHabit(habitId);
      
      // Reload habits after deleting
      final habits = await _habitService.getHabits();
      final completedHabits = await _habitService.getTodayCompletedHabits();
      final incompleteHabits = await _habitService.getTodayIncompleteHabits();
      
      emit(HabitsOperationSuccess(
        message: 'Habit deleted successfully!',
        habits: habits,
        completedHabits: completedHabits,
        incompleteHabits: incompleteHabits,
      ));
    } catch (e) {
      emit(const HabitsError('Failed to delete habit'));
    }
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    try {
      await _habitService.toggleHabitCompletion(habitId);
      
      // Reload habits after toggling
      final habits = await _habitService.getHabits();
      final completedHabits = await _habitService.getTodayCompletedHabits();
      final incompleteHabits = await _habitService.getTodayIncompleteHabits();
      
      emit(HabitsLoaded(
        habits: habits,
        completedHabits: completedHabits,
        incompleteHabits: incompleteHabits,
      ));
    } catch (e) {
      emit(const HabitsError('Failed to toggle habit completion'));
    }
  }

  Future<Map<String, int>> getWeeklyProgress() async {
    try {
      return await _habitService.getWeeklyProgress();
    } catch (e) {
      return {};
    }
  }
  
  Future<List<Habit>> getHabits() async {
    try {
      return await _habitService.getHabits();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> updateHabit(String habitId, String name, Color color) async {
    emit(HabitsLoading());
    try {
      await _habitService.updateHabit(habitId, name, color);
      
      // Reload habits after updating
      final habits = await _habitService.getHabits();
      final completedHabits = await _habitService.getTodayCompletedHabits();
      final incompleteHabits = await _habitService.getTodayIncompleteHabits();
      
      emit(HabitsOperationSuccess(
        message: 'Habit updated successfully!',
        habits: habits,
        completedHabits: completedHabits,
        incompleteHabits: incompleteHabits,
      ));
    } catch (e) {
      emit(HabitsError('Failed to update habit: ${e.toString()}'));
    }
  }
}

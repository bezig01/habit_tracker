import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/habit.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _habitsKey = 'habits_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _selectedHabitsForNotificationsKey = 'selected_habits_notifications';

  // User methods
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return User.fromJson(jsonDecode(userString));
    }
    return null;
  }

  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Login state methods
  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Habits methods
  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = habits.map((habit) => habit.toJson()).toList();
    await prefs.setString(_habitsKey, jsonEncode(habitsJson));
  }

  Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsString = prefs.getString(_habitsKey);
    if (habitsString != null) {
      final List<dynamic> habitsJson = jsonDecode(habitsString);
      return habitsJson.map((json) => Habit.fromJson(json)).toList();
    }
    return [];
  }

  // Notifications methods
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }
  
  // Individual habit notification settings
  Future<void> saveHabitNotificationSetting(String habitId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('habit_notification_${habitId}', enabled);
  }

  Future<bool> getHabitNotificationSetting(String habitId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('habit_notification_${habitId}') ?? false;
  }

  Future<void> setSelectedHabitsForNotifications(List<String> habitIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedHabitsForNotificationsKey, habitIds);
  }

  Future<List<String>> getSelectedHabitsForNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedHabitsForNotificationsKey) ?? [];
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

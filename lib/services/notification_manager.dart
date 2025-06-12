import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'habit_service.dart';

/// A manager class that integrates notification service with habit tracking
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();
  final HabitService _habitService = HabitService();
  
  // Notification times
  static const int morningHour = 8;
  static const int afternoonHour = 14;
  static const int eveningHour = 19;
  
  // Test notification ID
  static const int testNotificationId = 9999;

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();
  
  /// Initialize the notification system
  Future<void> initialize() async {
    // Initialize notification service (this will set up timezones as well)
    await _notificationService.init();
    
    // If notifications are enabled, check permissions and schedule them on app start
    bool enabled = await _storageService.getNotificationsEnabled();
    if (enabled) {
      // Check if we have notification permissions
      bool permissionsGranted = await areNotificationsPermissionsGranted();
      
      if (!permissionsGranted) {
        // Try to request permissions
        permissionsGranted = await requestPermissions();
      }
      
      if (permissionsGranted) {
        await scheduleAllNotifications();
      } else {
        debugPrint('Notification permissions not granted, disabling notifications');
        // Turn off notifications since permissions are denied
        await _storageService.setNotificationsEnabled(false);
      }
    }
  }
  
  // We've removed the duplicated notification initialization code
  // since we're using NotificationService directly
  
  /// Schedule notifications for all selected habits
  Future<void> scheduleAllNotifications() async {
    bool enabled = await _storageService.getNotificationsEnabled();
    if (!enabled) {
      debugPrint('Notifications are disabled, not scheduling');
      return;
    }
    
    List<String> selectedHabitIds = await _storageService.getSelectedHabitsForNotifications();
    if (selectedHabitIds.isEmpty) {
      debugPrint('No habits selected for notifications');
      return;
    }
    
    List<Habit> allHabits = await _habitService.getHabits();
    List<Habit> selectedHabits = allHabits
        .where((habit) => selectedHabitIds.contains(habit.id))
        .toList();
    
    if (selectedHabits.isEmpty) {
      debugPrint('No matching habits found for notification');
      return;
    }
    
    // Cancel existing notifications before scheduling new ones
    await _notificationService.cancelAllNotifications();
    
    // Schedule for all three time periods
    await _scheduleNotificationsForTime(selectedHabits, morningHour, 0, 'Morning');
    await _scheduleNotificationsForTime(selectedHabits, afternoonHour, 0, 'Afternoon');
    await _scheduleNotificationsForTime(selectedHabits, eveningHour, 0, 'Evening');
    
    debugPrint('Successfully scheduled notifications for ${selectedHabits.length} habits');
  }
  
  /// Schedule notifications for a specific time of day
  Future<void> _scheduleNotificationsForTime(
      List<Habit> habits, int hour, int minute, String timeOfDay) async {
    await _notificationService.scheduleNotificationsForTime(
      habits, hour, minute, '$timeOfDay Habit Reminders');
  }
  
  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }
  
  /// Request notification permissions for the current platform
  Future<bool> requestPermissions() async {
    // Request iOS permissions
    final bool iosPermission = await _notificationService.flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
        
    // Request Android permissions
    final bool androidPermission = await _notificationService.requestAndroidNotificationPermission();
    
    // Request exact alarms permission for Android
    final bool exactAlarmsPermission = await _notificationService.requestExactAlarmsPermission();
    
    debugPrint('Notification permission request results: iOS=$iosPermission, Android=$androidPermission, ExactAlarms=$exactAlarmsPermission');
    
    // Return true if either platform's permissions are granted
    return iosPermission || androidPermission;
  }
  
  /// Check if notification permissions are granted
  Future<bool> areNotificationsPermissionsGranted() async {
    return await _notificationService.checkNotificationPermissions();
  }
  
  /// Toggle notifications for a specific habit
  Future<void> toggleHabitNotification(String habitId) async {
    List<String> selectedIds = await _storageService.getSelectedHabitsForNotifications();
    
    if (selectedIds.contains(habitId)) {
      selectedIds.remove(habitId);
    } else {
      selectedIds.add(habitId);
    }
    
    await _storageService.setSelectedHabitsForNotifications(selectedIds);
    
    // Reschedule notifications with the updated list
    bool enabled = await _storageService.getNotificationsEnabled();
    if (enabled) {
      await scheduleAllNotifications();
    }
  }
  
  /// Enable or disable all notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _storageService.setNotificationsEnabled(enabled);
    
    if (enabled) {
      await scheduleAllNotifications();
    } else {
      await cancelAllNotifications();
      // Optionally clear selected habits
      // await _storageService.setSelectedHabitsForNotifications([]);
    }
  }
  
  /// Get notification times for display
  Map<String, String> getNotificationTimesForDisplay() {
    return {
      'Morning': '$morningHour:00 AM',
      'Afternoon': '$afternoonHour:00 PM',
      'Evening': '$eveningHour:00 PM',
    };
  }
  
  /// Diagnostic method to check notification status and log information
  Future<Map<String, dynamic>> getNotificationDiagnostics() async {
    final Map<String, dynamic> diagnostics = {};
    
    try {
      // Check overall notification settings
      diagnostics['notificationsEnabled'] = await _storageService.getNotificationsEnabled();
      
      // Check permissions
      diagnostics['permissionsGranted'] = await areNotificationsPermissionsGranted();
      
      // Check selected habits
      final selectedIds = await _storageService.getSelectedHabitsForNotifications();
      diagnostics['selectedHabitsCount'] = selectedIds.length;
      
      // Check pending notifications
      final pendingNotifications = 
          await _notificationService.flutterLocalNotificationsPlugin.pendingNotificationRequests();
      diagnostics['pendingNotificationsCount'] = pendingNotifications.length;
      
      // Get timezone info
      try {
        final now = tz.TZDateTime.now(tz.local);
        diagnostics['timezone'] = tz.local.name;
        diagnostics['currentLocalTime'] = now.toString();
      } catch (e) {
        diagnostics['timezoneError'] = e.toString();
      }
      
    } catch (e) {
      diagnostics['error'] = e.toString();
    }
    
    debugPrint('Notification diagnostics: $diagnostics');
    return diagnostics;
  }

  /// Schedule a test notification that will appear in 5 seconds
  Future<void> scheduleTestNotification() async {
    // First, cancel any existing test notifications
    await _notificationService.flutterLocalNotificationsPlugin.cancel(testNotificationId);
    
    // Create notification details for Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_notification_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    // Create notification details for iOS and macOS
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Combine platform-specific details
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    
    // Schedule the notification to appear 5 seconds from now
    final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
    
    debugPrint('Scheduling test notification for: ${scheduledTime.toString()}');
    
    // Use the notification service to schedule the test notification
    await _notificationService.flutterLocalNotificationsPlugin.zonedSchedule(
      testNotificationId,
      'Test Notification',
      'This is a test notification from Habit Tracker. If you can see this, notifications are working correctly!',
      _notificationService.convertToTZDateTime(scheduledTime),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint('Test notification scheduled successfully');
  }
}

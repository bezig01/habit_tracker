import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/habit.dart';
import 'storage_service.dart';
import 'habit_service.dart';
import '../main.dart' show notificationTapBackground;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final StorageService _storageService = StorageService();
  final HabitService _habitService = HabitService();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();
    // Set local timezone
    tz.setLocalLocation(tz.getLocation('America/New_York')); // Default to ET, could be made configurable
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {},
    );
    
    // Adding macOS settings (same as iOS for Darwin platforms)
    final DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Handle notification tapped logic here
        debugPrint('Notification tapped with payload: ${details.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Request Android notification permissions (for Android 13+)
  Future<bool> requestAndroidNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation == null) {
      return false;
    }
    
    final bool? granted = await androidImplementation.requestNotificationsPermission();
    return granted ?? false;
  }
  
  // Request exact alarms permission on Android
  Future<bool> requestExactAlarmsPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation == null) {
      return false;
    }
    
    return await androidImplementation.requestExactAlarmsPermission() ?? false;
  }
  
  // Check if notification permissions are granted
  Future<bool> checkNotificationPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation == null) {
      return true; // Not on Android, so assume granted
    }
    
    return await androidImplementation.areNotificationsEnabled() ?? false;
  }

  // This method is kept for backward compatibility
  // It's better to use NotificationManager.scheduleAllNotifications() instead
  Future<void> scheduleNotifications() async {
    // Clear any existing notifications first
    await flutterLocalNotificationsPlugin.cancelAll();
    
    bool notificationsEnabled = await _storageService.getNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }

    List<String> selectedHabitIds = await _storageService.getSelectedHabitsForNotifications();
    if (selectedHabitIds.isEmpty) {
      return;
    }

    List<Habit> allHabits = await _habitService.getHabits();
    List<Habit> selectedHabits = allHabits
        .where((habit) => selectedHabitIds.contains(habit.id))
        .toList();

    if (selectedHabits.isEmpty) {
      return;
    }

    // Schedule morning notifications at 8:00 AM
    await scheduleNotificationsForTime(
      selectedHabits, 
      8, 
      0, 
      'Morning Habit Reminders',
    );

    // Schedule afternoon notifications at 2:00 PM
    await scheduleNotificationsForTime(
      selectedHabits, 
      14, 
      0, 
      'Afternoon Habit Reminders',
    );

    // Schedule evening notifications at 7:00 PM
    await scheduleNotificationsForTime(
      selectedHabits, 
      19, 
      0, 
      'Evening Habit Reminders',
    );

    debugPrint('Scheduled notifications for ${selectedHabits.length} habits');
  }

  Future<void> scheduleNotificationsForTime(
    List<Habit> habits, 
    int hour, 
    int minute, 
    String groupTitle,
  ) async {
    final now = DateTime.now();
    
    // Set the notification time for today
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Group notification (summary notification)
    if (habits.length > 1) {
      await _scheduleSingleNotification(
        id: hour * 100, // Unique ID based on hour
        title: groupTitle,
        body: 'You have ${habits.length} habits to complete',
        scheduledDate: scheduledDate,
        payload: 'habit_group',
        groupKey: 'com.habittracker.notifications.${hour}',
        setAsGroupSummary: true,
      );
    }

    // Individual habit notifications
    for (int i = 0; i < habits.length; i++) {
      Habit habit = habits[i];
      await _scheduleSingleNotification(
        id: hour * 100 + i + 1, // Ensure unique IDs
        title: habit.name,
        body: 'Time to complete your habit!',
        scheduledDate: scheduledDate,
        payload: habit.id,
        groupKey: 'com.habittracker.notifications.${hour}',
      );
    }
  }

  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
    required String groupKey,
    bool setAsGroupSummary = false,
  }) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'habit_reminder_channel',
      'Habit Reminders',
      channelDescription: 'Notifications for habit reminders',
      importance: Importance.high,
      priority: Priority.high,
      groupKey: groupKey,
      setAsGroupSummary: setAsGroupSummary,
    );

    DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      threadIdentifier: groupKey,
    );
    
    // Using the same settings for macOS
    DarwinNotificationDetails macOSNotificationDetails = DarwinNotificationDetails(
      threadIdentifier: groupKey,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
      macOS: macOSNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      convertToTZDateTime(scheduledDate),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint('Scheduled notification: $title at ${scheduledDate.toString()}');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Schedule a notification for a specific habit
  Future<void> scheduleHabitReminder(Habit habit) async {
    int id = int.parse(habit.id.hashCode.toString().substring(0, 6).replaceAll('-', ''));
    
    // Set for default time (8:00 AM)
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      8, // 8 AM default
      0,
    );
    
    // If the scheduled time is already past for today, set it for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    await _scheduleSingleNotification(
      id: id,
      title: 'Reminder: ${habit.name}',
      body: 'Time to work on your habit!',
      scheduledDate: scheduledDate,
      payload: habit.id,
      groupKey: 'com.habittracker.notifications.habit',
    );
    
    // Save to preferences that this habit has notifications enabled
    await _storageService.saveHabitNotificationSetting(habit.id, true);
  }
  
  // Cancel notifications for a specific habit
  Future<void> cancelHabitReminder(Habit habit) async {
    int id = int.parse(habit.id.hashCode.toString().substring(0, 6).replaceAll('-', ''));
    await flutterLocalNotificationsPlugin.cancel(id);
    
    // Save to preferences that this habit has notifications disabled
    await _storageService.saveHabitNotificationSetting(habit.id, false);
  }
  
  // Check if a habit has notifications enabled
  Future<bool> isHabitReminderEnabled(String habitId) async {
    return await _storageService.getHabitNotificationSetting(habitId);
  }
  
  // Helper method to convert DateTime to TZDateTime safely
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    try {
      return tz.TZDateTime.from(dateTime, tz.local);
    } catch (e) {
      // Fallback if there's an issue with the timezone
      debugPrint('Error converting to TZDateTime: $e');
      final now = tz.TZDateTime.now(tz.local);
      return tz.TZDateTime(tz.local, now.year, now.month, now.day, 
          dateTime.hour, dateTime.minute);
    }
  }
  
  // Public method for clients to convert DateTime to TZDateTime
  tz.TZDateTime convertToTZDateTime(DateTime dateTime) {
    return _convertToTZDateTime(dateTime);
  }
}

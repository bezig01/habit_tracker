import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/habit_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final StorageService _storageService = StorageService();
  final HabitService _habitService = HabitService();
  
  bool _notificationsEnabled = false;
  List<Habit> _habits = [];
  List<String> _selectedHabitIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    _notificationsEnabled = await _storageService.getNotificationsEnabled();
    _habits = await _habitService.getHabits();
    _selectedHabitIds = await _storageService.getSelectedHabitsForNotifications();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    await _storageService.setNotificationsEnabled(enabled);
    setState(() {
      _notificationsEnabled = enabled;
    });

    if (!enabled) {
      // Clear selected habits if notifications are disabled
      await _storageService.setSelectedHabitsForNotifications([]);
      setState(() {
        _selectedHabitIds.clear();
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled 
              ? 'Notifications enabled' 
              : 'Notifications disabled'),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _toggleHabitNotification(String habitId) async {
    setState(() {
      if (_selectedHabitIds.contains(habitId)) {
        _selectedHabitIds.remove(habitId);
      } else {
        _selectedHabitIds.add(habitId);
      }
    });

    await _storageService.setSelectedHabitsForNotifications(_selectedHabitIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNotificationSettings(),
    );
  }

  Widget _buildNotificationSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main notification toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _notificationsEnabled 
                  ? Colors.green.shade50 
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _notificationsEnabled 
                    ? Colors.green.shade200 
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: _notificationsEnabled 
                      ? Colors.green 
                      : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enable Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _notificationsEnabled
                            ? 'You will receive reminders for selected habits'
                            : 'Turn on to receive habit reminders',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notification schedule info
          if (_notificationsEnabled) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Notification Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildScheduleItem('Morning', '8:00 AM', Icons.wb_sunny),
                  _buildScheduleItem('Afternoon', '2:00 PM', Icons.wb_cloudy),
                  _buildScheduleItem('Evening', '7:00 PM', Icons.nightlight),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Habit selection
            const Text(
              'Select Habits for Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which habits you want to receive reminders for',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            if (_habits.isEmpty)
              _buildEmptyHabitsState()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    final isSelected = _selectedHabitIds.contains(habit.id);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _toggleHabitNotification(habit.id),
                        title: Text(habit.name),
                        secondary: CircleAvatar(
                          backgroundColor: habit.color,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        subtitle: Text(
                          isSelected 
                              ? 'You will receive reminders for this habit'
                              : 'Tap to enable reminders',
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.green.shade600 
                                : Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Summary
            if (_selectedHabitIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive ${_selectedHabitIds.length} habit reminder(s) three times a day.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Disabled state message
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notifications Disabled',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable notifications to receive habit reminders',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String schedule, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            '$time: $schedule',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHabitsState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No habits found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some habits first to set up notifications',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

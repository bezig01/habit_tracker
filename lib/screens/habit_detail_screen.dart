import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/habits/habits_cubit.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({
    Key? key,
    required this.habit,
  }) : super(key: key);

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  bool _notificationsEnabled = false;
  Map<String, int> _weeklyProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _selectedColor = widget.habit.color;
    _loadWeeklyProgress();
    _checkNotificationStatus();
  }
  
  Future<void> _checkNotificationStatus() async {
    final notificationService = NotificationService();
    final isEnabled = await notificationService.isHabitReminderEnabled(widget.habit.id);
    
    setState(() {
      _notificationsEnabled = isEnabled;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyProgress() async {
    setState(() {
      _isLoading = true;
    });
    
    // Get the habit's completion data for the past week
    final habits = await context.read<HabitsCubit>().getHabits();
    final habit = habits.firstWhere((h) => h.id == widget.habit.id, orElse: () => widget.habit);
    
    // Calculate weekly progress for this specific habit
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
      
      bool isCompletedOnDay = habit.completedDates.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day
      );
      
      weeklyProgress[dayName] = isCompletedOnDay ? 1 : 0;
    }
    
    setState(() {
      _weeklyProgress = weeklyProgress;
      _isLoading = false;
    });
  }

  // Check if habit is completed today
  bool _isTodayCompleted() {
    final today = DateTime.now();
    
    return widget.habit.completedDates.any((date) =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day
    );
  }
  
  // Toggle today's completion status for this habit
  Future<void> _toggleTodayCompletion() async {
    await context.read<HabitsCubit>().toggleHabitCompletion(widget.habit.id);
    
    // Refresh the weekly progress data
    _loadWeeklyProgress();
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTodayCompleted() 
          ? 'Habit marked as completed today!' 
          : 'Habit marked as incomplete today'
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: _isTodayCompleted() ? Colors.green : Colors.orange,
      ),
    );
  }

  void _updateHabit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit name cannot be empty')),
      );
      return;
    }
    
    // Update habit with new name and color
    context.read<HabitsCubit>().updateHabit(
      widget.habit.id,
      _nameController.text.trim(),
      _selectedColor,
    );
    
    // Update notification settings if they changed
    final notificationService = NotificationService();
    if (_notificationsEnabled) {
      notificationService.scheduleHabitReminder(
        widget.habit.copyWith(
          name: _nameController.text.trim(),
          color: _selectedColor,
        ),
      );
    }
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Habit updated successfully')),
    );
    
    Navigator.pop(context, true);  // Return true to indicate a change was made
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Details'),
        backgroundColor: _selectedColor,
        actions: [
          // Toggle today's completion button
          IconButton(
            icon: Icon(
              _isTodayCompleted() ? Icons.undo : Icons.check_circle_outline,
              color: Colors.white,
            ),
            tooltip: _isTodayCompleted() ? 'Mark as incomplete today' : 'Mark as completed today',
            onPressed: _toggleTodayCompletion,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateHabit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit Name
            const Text(
              'Habit Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter habit name',
              ),
            ),
            const SizedBox(height: 24),
            
            // Color Selection
            const Text(
              'Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildColorSelector(),
            const SizedBox(height: 24),
            
            // Notifications Toggle
            SwitchListTile(
              title: const Text(
                'Remind me daily',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Receive daily notifications for this habit'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                final notificationService = NotificationService();
                
                setState(() {
                  _notificationsEnabled = value;
                });
                
                if (value) {
                  await notificationService.scheduleHabitReminder(widget.habit);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Daily reminder set for this habit'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  await notificationService.cancelHabitReminder(widget.habit);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder cancelled for this habit'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Weekly Report
            const Text(
              'Weekly Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildWeeklyReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedColor == color
                    ? Colors.white
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: _selectedColor == color
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: _selectedColor == color
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyReport() {
    // Calculate current streak
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    int currentStreak = 0;
    int completedDays = 0;
    
    // Count completed days
    weekdays.forEach((day) {
      if ((_weeklyProgress[day] ?? 0) > 0) {
        completedDays++;
      }
    });
    
    // Calculate streak from today backwards
    final now = DateTime.now();
    int currentDayIndex = now.weekday - 1; // 0-based index (0 = Monday)
    
    for (int i = currentDayIndex; i >= 0; i--) {
      if ((_weeklyProgress[weekdays[i]] ?? 0) > 0) {
        currentStreak++;
      } else {
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Completion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$completedDays/7 days',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (currentStreak > 0) 
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Current streak: $currentStreak day${currentStreak == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _buildWeeklyCircles(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyCircles() {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final shortWeekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    // Get current day index (0-based, Monday = 0)
    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(7, (index) {
        final completed = _weeklyProgress[weekdays[index]] ?? 0;
        final isCompleted = completed > 0;
        final isCurrentDay = index == currentDayIndex;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle indicator with animation
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? _selectedColor : Colors.transparent,
                border: Border.all(
                  color: isCompleted 
                    ? _selectedColor 
                    : isCurrentDay 
                      ? _selectedColor.withOpacity(0.5)
                      : Colors.grey.shade400,
                  width: isCurrentDay ? 2.5 : 2,
                ),
                boxShadow: isCompleted 
                  ? [
                      BoxShadow(
                        color: _selectedColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ] 
                  : null,
              ),
              child: Center(
                child: isCompleted 
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 22,
                    )
                  : isCurrentDay
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedColor.withOpacity(0.5),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Day label
            Text(
              shortWeekdays[index],
              style: TextStyle(
                fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                color: isCompleted 
                  ? _selectedColor 
                  : isCurrentDay 
                    ? Colors.black87
                    : Colors.grey.shade600,
              ),
            ),
            // Date number
            Text(
              _getDayNumber(index),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                color: isCurrentDay ? Colors.black54 : Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }
  
  String _getDayNumber(int dayIndex) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: now.weekday - 1 - dayIndex));
    return '${date.day}';
  }
}

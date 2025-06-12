import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/habit.dart';
import '../bloc/habits/habits_cubit.dart';
import '../bloc/habits/habits_state.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _initialHabits = []; // Store initial state for comparison
  
  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    // Load habits when screen initializes
    context.read<HabitsCubit>().loadHabits();
  }

  Future<void> _addHabit() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddHabitDialog(availableColors: _availableColors),
    );

    if (result != null) {
      context.read<HabitsCubit>().addHabit(result['name'], result['color']);
    }
  }

  Future<void> _deleteHabit(String habitId, String habitName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "$habitName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<HabitsCubit>().deleteHabit(habitId);
    }
  }

  // Method to check if habits have changed
  bool _hasChangesOccurred(List<Habit> currentHabits) {
    if (_initialHabits.length != currentHabits.length) return true;
    
    // Check if habit IDs are the same (simple comparison)
    final initialIds = _initialHabits.map((h) => h.id).toSet();
    final currentIds = currentHabits.map((h) => h.id).toSet();
    
    return !initialIds.containsAll(currentIds) || !currentIds.containsAll(initialIds);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HabitsCubit, HabitsState>(
      listener: (context, state) {
        if (state is HabitsOperationSuccess) {
          // Store initial state for comparison if not already set
          if (_initialHabits.isEmpty) {
            _initialHabits = List.from(state.habits);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is HabitsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is HabitsLoaded && _initialHabits.isEmpty) {
          // Store initial state for comparison
          _initialHabits = List.from(state.habits);
        }
      },
      child: BlocBuilder<HabitsCubit, HabitsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Manage Habits'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final hasChanges = state is HabitsLoaded 
                      ? _hasChangesOccurred(state.habits)
                      : false;
                  Navigator.of(context).pop(hasChanges);
                },
              ),
            ),
            body: _buildBody(state),
            floatingActionButton: FloatingActionButton(
              onPressed: _addHabit,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(HabitsState state) {
    if (state is HabitsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is HabitsLoaded || state is HabitsOperationSuccess) {
      final habits = state is HabitsLoaded 
          ? state.habits 
          : (state as HabitsOperationSuccess).habits;
      
      return habits.isEmpty
          ? _buildEmptyState()
          : _buildHabitsList(habits);
    } else if (state is HabitsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<HabitsCubit>().loadHabits(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No habits yet!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first habit.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList(List<Habit> habits) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Habits (${habits.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final completedDaysThisWeek = _getCompletedDaysThisWeek(habit);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: habit.color,
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      habit.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Completed $completedDaysThisWeek days this week'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: completedDaysThisWeek / 7,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(habit.color),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteHabit(habit.id, habit.name),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getCompletedDaysThisWeek(Habit habit) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (habit.completedDates.any((date) =>
        date.year == day.year &&
        date.month == day.month &&
        date.day == day.day
      )) {
        count++;
      }
    }
    return count;
  }
}

class _AddHabitDialog extends StatefulWidget {
  final List<Color> availableColors;

  const _AddHabitDialog({required this.availableColors});

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.availableColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Habit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Habit Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const Text('Choose a color:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.availableColors.map((color) {
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
                          ? Colors.black 
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _selectedColor == color
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'color': _selectedColor,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

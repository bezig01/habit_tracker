import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/habits/habits_cubit.dart';
import '../bloc/habits/habits_state.dart';
import '../models/habit.dart';
import 'profile_screen.dart';
import 'habits_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load habits when screen initializes
    context.read<HabitsCubit>().loadHabits();
  }

  Future<void> _toggleHabitCompletion(String habitId) async {
    context.read<HabitsCubit>().toggleHabitCompletion(habitId);
  }

  Future<void> _logout() async {
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Habit Tracker'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Tracker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Build better habits, one day at a time. Track your daily progress and achieve your goals.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Daily habit tracking'),
            Text('• Weekly progress reports'),
            Text('• Custom habit colors'),
            Text('• Notification reminders'),
            Text('• Profile management'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated && authState is! AuthProfileUpdateSuccess) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final currentUser = authState is AuthAuthenticated 
              ? authState.user 
              : (authState as AuthProfileUpdateSuccess).user;

          return BlocBuilder<HabitsCubit, HabitsState>(
            builder: (context, habitsState) {
              List<Habit> completedHabits = [];
              List<Habit> incompleteHabits = [];
              bool isLoading = habitsState is HabitsLoading;

              if (habitsState is HabitsLoaded) {
                completedHabits = habitsState.completedHabits;
                incompleteHabits = habitsState.incompleteHabits;
              } else if (habitsState is HabitsOperationSuccess) {
                completedHabits = habitsState.completedHabits;
                incompleteHabits = habitsState.incompleteHabits;
              }

              if (isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return _buildHomeScreen(currentUser, completedHabits, incompleteHabits);
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(user, List<Habit> completedHabits, List<Habit> incompleteHabits) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name ?? 'User'}!'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: _buildDrawer(user),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<HabitsCubit>().loadHabits();
        },
        child: _buildBody(completedHabits, incompleteHabits),
      ),
    );
  }

  Widget _buildDrawer(user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: Text(
              user.name ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              '@${user.username ?? 'username'}',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: true,
            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () async {
              Navigator.of(context).pop(); // Close drawer
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              if (result == true) {
                context.read<HabitsCubit>().loadHabits();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Manage Habits'),
            onTap: () async {
              Navigator.of(context).pop(); // Close drawer
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HabitsScreen()),
              );
              if (result == true) {
                context.read<HabitsCubit>().loadHabits();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              _showAboutDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Habit> completedHabits, List<Habit> incompleteHabits) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Progress Section
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressItem(
                  'Completed',
                  completedHabits.length,
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildProgressItem(
                  'Remaining',
                  incompleteHabits.length,
                  Colors.orange,
                  Icons.pending,
                ),
                _buildProgressItem(
                  'Total',
                  completedHabits.length + incompleteHabits.length,
                  Colors.blue,
                  Icons.list,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Incomplete Habits Section
          if (incompleteHabits.isNotEmpty) ...[
            const Text(
              'Habits to Complete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: incompleteHabits.length,
                itemBuilder: (context, index) {
                  final habit = incompleteHabits[index];
                  return _buildHabitTile(habit, false);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Completed Habits Section
          if (completedHabits.isNotEmpty) ...[
            const Text(
              'Completed Habits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: completedHabits.length,
                itemBuilder: (context, index) {
                  final habit = completedHabits[index];
                  return _buildHabitTile(habit, true);
                },
              ),
            ),
          ],
          
          // Empty state
          if (completedHabits.isEmpty && incompleteHabits.isEmpty) ...[
            Expanded(
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
                      'No habits yet!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go to the menu to add your first habit.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
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

  Widget _buildProgressItem(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitTile(Habit habit, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: habit.color,
          child: Icon(
            isCompleted ? Icons.check : Icons.circle_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isCompleted ? Icons.undo : Icons.check,
            color: isCompleted ? Colors.orange : Colors.green,
          ),
          onPressed: () => _toggleHabitCompletion(habit.id),
        ),
        onTap: () => _navigateToHabitDetails(habit),
      ),
    );
  }
  
  Future<void> _navigateToHabitDetails(Habit habit) async {
    // Import at the top of the file: import 'habit_detail_screen.dart';
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habit: habit),
      ),
    );
    
    // Reload habits if changes were made
    if (result == true) {
      context.read<HabitsCubit>().loadHabits();
    }
  }
}

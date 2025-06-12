import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final HabitService _habitService = HabitService();
  Map<String, int> _weeklyProgress = {};
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    setState(() {
      _isLoading = true;
    });

    _weeklyProgress = await _habitService.getWeeklyProgress();
    _habits = await _habitService.getHabits();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? _buildEmptyState()
              : _buildReportsContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No data to show',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some habits and start tracking to see your progress.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent() {
    return RefreshIndicator(
      onRefresh: _loadReportsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Progress Chart
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed habits for each day of the week',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildBarChart(),
            ),
            const SizedBox(height: 32),

            // Weekly Summary
            const Text(
              'Weekly Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeeklySummary(),
            const SizedBox(height: 32),

            // Habits Overview
            const Text(
              'Habits Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHabitsOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final data = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _habits.length.toDouble() + 1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blue.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = data[group.x.toInt()];
              final count = rod.toY.round();
              return BarTooltipItem(
                '$day\n$count habits completed',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < weekdays.length) {
                  return Text(
                    weekdays[value.toInt()],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final count = _weeklyProgress[day] ?? 0;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: _getBarColor(count),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getBarColor(int count) {
    if (count == 0) return Colors.grey.shade300;
    if (count <= 2) return Colors.orange;
    if (count <= 4) return Colors.blue;
    return Colors.green;
  }

  Widget _buildWeeklySummary() {
    final totalCompleted = _weeklyProgress.values.reduce((a, b) => a + b);
    final totalPossible = _habits.length * 7;
    final completionRate = totalPossible > 0 ? (totalCompleted / totalPossible) : 0.0;
    final bestDay = _weeklyProgress.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Completed',
                totalCompleted.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildSummaryItem(
                'Completion Rate',
                '${(completionRate * 100).toStringAsFixed(1)}%',
                Icons.percent,
                Colors.blue,
              ),
              _buildSummaryItem(
                'Best Day',
                bestDay.key.substring(0, 3),
                Icons.star,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completionRate,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              completionRate > 0.7 ? Colors.green : 
              completionRate > 0.4 ? Colors.orange : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weekly completion: ${(completionRate * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHabitsOverview() {
    final completedHabits = _habits.where((habit) => habit.isCompletedToday()).toList();
    final incompleteHabits = _habits.where((habit) => !habit.isCompletedToday()).toList();

    return Column(
      children: [
        // Today's Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today\'s Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      'Completed',
                      completedHabits.length,
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      'Remaining',
                      incompleteHabits.length,
                      Colors.orange,
                      Icons.pending,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Habit List
        ...completedHabits.map((habit) => _buildHabitCard(habit, true)),
        ...incompleteHabits.map((habit) => _buildHabitCard(habit, false)),
      ],
    );
  }

  Widget _buildStatusCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
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
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: habit.color,
          child: Icon(
            isCompleted ? Icons.check : Icons.circle_outlined,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

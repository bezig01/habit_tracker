import 'package:equatable/equatable.dart';
import '../../models/habit.dart';

abstract class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {}

class HabitsLoading extends HabitsState {}

class HabitsLoaded extends HabitsState {
  final List<Habit> habits;
  final List<Habit> completedHabits;
  final List<Habit> incompleteHabits;

  const HabitsLoaded({
    required this.habits,
    required this.completedHabits,
    required this.incompleteHabits,
  });

  @override
  List<Object?> get props => [habits, completedHabits, incompleteHabits];
}

class HabitsError extends HabitsState {
  final String message;

  const HabitsError(this.message);

  @override
  List<Object?> get props => [message];
}

class HabitsOperationSuccess extends HabitsState {
  final String message;
  final List<Habit> habits;
  final List<Habit> completedHabits;
  final List<Habit> incompleteHabits;

  const HabitsOperationSuccess({
    required this.message,
    required this.habits,
    required this.completedHabits,
    required this.incompleteHabits,
  });

  @override
  List<Object?> get props => [message, habits, completedHabits, incompleteHabits];
}

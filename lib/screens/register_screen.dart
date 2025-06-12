import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/countries/countries_cubit.dart';
import '../bloc/countries/countries_state.dart';
import '../bloc/habits/habits_cubit.dart';
import '../services/countries_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  
  List<String> availableHabits = [
    'Wake Up Early',
    'Workout',
    'Drink Water',
    'Meditate',
    'Read a Book',
    'Practice Gratitude',
    'Sleep 8 Hours',
    'Eat Healthy',
    'Journal',
    'Walk 10,000 Steps'
  ];
  
  List<String> selectedHabits = [];

  @override
  void initState() {
    super.initState();
    context.read<CountriesCubit>().loadCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      final countriesState = context.read<CountriesCubit>().state;
      String countryName = '';
      
      if (countriesState is CountriesLoaded && countriesState.selectedCountry != null) {
        countryName = countriesState.selectedCountry!.name;
      } else if (countriesState is CountriesError && countriesState.fallbackCountries.isNotEmpty) {
        countryName = _countryController.text.trim();
      } else {
        countryName = _countryController.text.trim();
      }
      
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          _nameController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text,
          int.parse(_ageController.text),
          countryName,
        ),
      );
      
      // We'll handle habit creation in the listener after successful registration
    }
  }
  
  void _createInitialHabits() {
    // Prepare data for batch add
    final habitsData = selectedHabits.map((habitName) {
      // We'll use different colors for different habits
      final color = Colors.primaries[availableHabits.indexOf(habitName) % Colors.primaries.length];
      return {
        'name': habitName,
        'color': color,
      };
    }).toList();
    
    // Add all habits at once using batch method
    context.read<HabitsCubit>().addMultipleHabits(habitsData);
  }
  
  void _toggleHabitSelection(String habit) {
    setState(() {
      if (selectedHabits.contains(habit)) {
        selectedHabits.remove(habit);
      } else {
        selectedHabits.add(habit);
      }
    });
  }

  Widget _buildCountryField() {
    return BlocBuilder<CountriesCubit, CountriesState>(
      builder: (context, state) {
        if (state is CountriesLoading) {
          return DropdownButtonFormField<Country>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.public),
            ),
            hint: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading countries...'),
              ],
            ),
          );
        }

        List<Country> countries = [];
        Country? selectedCountry;
        bool hasError = false;

        if (state is CountriesLoaded) {
          countries = state.countries;
          selectedCountry = state.selectedCountry;
        } else if (state is CountriesError) {
          countries = state.fallbackCountries;
          hasError = true;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Country>(
              value: selectedCountry,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
              hint: const Text('Select your country'),
              items: countries.map((Country country) {
                return DropdownMenuItem<Country>(
                  value: country,
                  child: Text(country.name),
                );
              }).toList(),
              onChanged: (Country? newValue) {
                context.read<CountriesCubit>().selectCountry(newValue);
                _countryController.text = newValue?.name ?? '';
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your country';
                }
                return null;
              },
              isExpanded: true,
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              const Text(
                'Using offline countries list. Check your internet connection.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Create selected habits before navigating away from this screen
          if (selectedHabits.isNotEmpty) {
            _createInitialHabits();
          }
          
          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Register'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 1 || age > 120) {
                        return 'Please enter a valid age';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCountryField(),
                  const SizedBox(height: 24),
                  const Text(
                    'Select habits you want to track:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Choose habits you\'d like to start tracking right away',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableHabits.map((habit) {
                      final isSelected = selectedHabits.contains(habit);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(habit),
                        onSelected: (selected) {
                          _toggleHabitSelection(habit);
                        },
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Register'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

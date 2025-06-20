import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/countries/countries_cubit.dart';
import '../bloc/countries/countries_state.dart';
import '../services/countries_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CountriesCubit>().loadCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _populateFields(User user) {
    _nameController.text = user.name;
    _usernameController.text = user.username;
    _ageController.text = user.age.toString();
    _countryController.text = user.country;
    // Set the initial country in the cubit directly when populating fields
    context.read<CountriesCubit>().setInitialCountry(user.country);
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final countriesState = context.read<CountriesCubit>().state;
      String countryName = '';
      
      if (countriesState is CountriesLoaded && countriesState.selectedCountry != null) {
        countryName = countriesState.selectedCountry!.name;
      } else {
        countryName = _countryController.text.trim();
      }
      
      context.read<AuthBloc>().add(
        AuthProfileUpdateRequested(
          _nameController.text.trim(),
          _usernameController.text.trim(),
          int.parse(_ageController.text),
          countryName,
        ),
      );
    }
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
        if (state is AuthProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate changes were made
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        User? currentUser;
        bool isLoading = authState is AuthLoading;

        if (authState is AuthAuthenticated) {
          currentUser = authState.user;
          _populateFields(currentUser);
        } else if (authState is AuthProfileUpdateSuccess) {
          currentUser = authState.user;
          _populateFields(currentUser);
        }

        // Listen to countries state and set initial country when ready
        return BlocBuilder<CountriesCubit, CountriesState>(
          builder: (context, countriesState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: isLoading ? null : _saveProfile,
                  ),
                ],
              ),
              body: _buildProfileForm(currentUser, isLoading),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileForm(User? currentUser, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            
            // Account Information Display
            if (currentUser != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Profile Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Name:', currentUser.name),
                    _buildInfoRow('Username:', currentUser.username),
                    _buildInfoRow('Age:', currentUser.age.toString()),
                    _buildInfoRow('Country:', currentUser.country),
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

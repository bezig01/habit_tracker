import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:habit_tracker/screens/profile_screen.dart';
import 'package:habit_tracker/bloc/auth/auth_bloc.dart';
import 'package:habit_tracker/bloc/auth/auth_state.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';
import 'package:habit_tracker/services/countries_service.dart';
import 'package:habit_tracker/models/user.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockCountriesCubit extends Mock implements CountriesCubit {}
class MockCountriesService extends Mock implements CountriesService {}

void main() {
  group('Profile Screen - Pending Country Integration Test', () {
    late MockAuthBloc mockAuthBloc;
    late MockCountriesCubit mockCountriesCubit;
    late MockCountriesService mockCountriesService;
    
    final testUser = User(
      name: 'Test User',
      username: 'testuser',
      age: 25,
      country: 'Canada',
      password: 'testpass123',
    );

    final testCountries = [
      const Country(name: 'United States', code: 'US'),
      const Country(name: 'Canada', code: 'CA'),
      const Country(name: 'United Kingdom', code: 'GB'),
    ];

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockCountriesCubit = MockCountriesCubit();
      mockCountriesService = MockCountriesService();
      
      // Set up default mocks for loadCountries and setInitialCountry
      when(() => mockCountriesCubit.loadCountries()).thenAnswer((_) async {});
      when(() => mockCountriesCubit.setInitialCountry(any())).thenReturn(null);
    });

    Widget createProfileScreen() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<CountriesCubit>.value(value: mockCountriesCubit),
          ],
          child: const ProfileScreen(),
        ),
      );
    }

    testWidgets('Profile screen calls setInitialCountry when user is authenticated', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.fromIterable([AuthAuthenticated(testUser)]));
      
      when(() => mockCountriesCubit.state).thenReturn(CountriesLoaded(countries: testCountries));
      when(() => mockCountriesCubit.stream).thenAnswer((_) => Stream.fromIterable([CountriesLoaded(countries: testCountries)]));
      
      // Act
      await tester.pumpWidget(createProfileScreen());
      await tester.pump(); // Allow the widget to build
      
      // Assert
      verify(() => mockCountriesCubit.loadCountries()).called(1);
      verify(() => mockCountriesCubit.setInitialCountry('Canada')).called(greaterThan(0));
    });

    testWidgets('Profile screen displays country dropdown when countries are loaded', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.fromIterable([AuthAuthenticated(testUser)]));
      
      when(() => mockCountriesCubit.state).thenReturn(
        CountriesLoaded(
          countries: testCountries,
          selectedCountry: testCountries.firstWhere((c) => c.name == 'Canada'),
        ),
      );
      when(() => mockCountriesCubit.stream).thenAnswer((_) => Stream.fromIterable([
        CountriesLoaded(
          countries: testCountries,
          selectedCountry: testCountries.firstWhere((c) => c.name == 'Canada'),
        ),
      ]));
      
      // Act
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      
      // Assert
      expect(find.byType(DropdownButtonFormField<Country>), findsOneWidget);
      expect(find.text('Canada'), findsWidgets); // Should appear in dropdown and current details
      expect(find.text('Select your country'), findsNothing); // Hint should not be visible when country is selected
    });

    testWidgets('Profile screen shows loading state when countries are loading', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.fromIterable([AuthAuthenticated(testUser)]));
      
      when(() => mockCountriesCubit.state).thenReturn(CountriesLoading());
      when(() => mockCountriesCubit.stream).thenAnswer((_) => Stream.fromIterable([CountriesLoading()]));
      
      // Act
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      
      // Assert
      expect(find.text('Loading countries...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets); // Multiple loading indicators
    });

    testWidgets('Profile screen displays user information correctly', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.fromIterable([AuthAuthenticated(testUser)]));
      
      when(() => mockCountriesCubit.state).thenReturn(CountriesLoaded(countries: testCountries));
      when(() => mockCountriesCubit.stream).thenAnswer((_) => Stream.fromIterable([CountriesLoaded(countries: testCountries)]));
      
      // Act
      await tester.pumpWidget(createProfileScreen());
      await tester.pump();
      
      // Assert - Check if user data is populated in the form fields
      expect(find.text('Test User'), findsWidgets); // In both form field and current details
      expect(find.text('testuser'), findsWidgets);
      expect(find.text('25'), findsWidgets);
      expect(find.text('Canada'), findsWidgets);
      
      // Check if the form fields are populated
      final nameField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
      expect(nameField.controller?.text, equals('Test User'));
      
      final usernameField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
      expect(usernameField.controller?.text, equals('testuser'));
      
      final ageField = tester.widget<TextFormField>(find.byType(TextFormField).at(2));
      expect(ageField.controller?.text, equals('25'));
    });
  });
}

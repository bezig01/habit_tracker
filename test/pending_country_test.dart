import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:habit_tracker/services/countries_service.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';

class MockCountriesService extends Mock implements CountriesService {}

void main() {
  group('CountriesCubit Pending Country Tests', () {
    late MockCountriesService mockCountriesService;
    late CountriesCubit countriesCubit;
    
    final testCountries = [
      const Country(name: 'United States', code: 'US'),
      const Country(name: 'Canada', code: 'CA'),
      const Country(name: 'United Kingdom', code: 'GB'),
    ];

    setUp(() {
      mockCountriesService = MockCountriesService();
      countriesCubit = CountriesCubit(mockCountriesService);
    });

    tearDown(() {
      countriesCubit.close();
    });

    test('setInitialCountry stores pending country when countries not loaded', () async {
      // Arrange: Don't load countries yet
      expect(countriesCubit.state, isA<CountriesInitial>());
      
      // Act: Try to set initial country before countries are loaded
      countriesCubit.setInitialCountry('Canada');
      
      // Assert: State should remain unchanged (still CountriesInitial)
      expect(countriesCubit.state, isA<CountriesInitial>());
    });

    test('pending country is selected after countries load successfully', () async {
      // Arrange: Set up mock to return countries
      when(() => mockCountriesService.getCountries())
          .thenAnswer((_) async => testCountries);
      
      // Act: Set initial country before loading
      countriesCubit.setInitialCountry('Canada');
      expect(countriesCubit.state, isA<CountriesInitial>());
      
      // Load countries
      await countriesCubit.loadCountries();
      
      // Assert: Countries loaded and Canada is selected
      expect(countriesCubit.state, isA<CountriesLoaded>());
      final loadedState = countriesCubit.state as CountriesLoaded;
      expect(loadedState.selectedCountry, isNotNull);
      expect(loadedState.selectedCountry?.name, equals('Canada'));
      expect(loadedState.selectedCountry?.code, equals('CA'));
    });

    test('pending country is selected after countries load with error (fallback)', () async {
      // Arrange: Set up mock to throw error and return fallback
      when(() => mockCountriesService.getCountries())
          .thenThrow(Exception('Network error'));
      when(() => mockCountriesService.getFallbackCountries())
          .thenReturn(testCountries);
      
      // Act: Set initial country before loading
      countriesCubit.setInitialCountry('United Kingdom');
      expect(countriesCubit.state, isA<CountriesInitial>());
      
      // Load countries (will fail and use fallback)
      await countriesCubit.loadCountries();
      
      // Assert: After loading and setting initial country, we should have CountriesLoaded
      // because selectCountry transitions from CountriesError to CountriesLoaded
      expect(countriesCubit.state, isA<CountriesLoaded>());
      final loadedState = countriesCubit.state as CountriesLoaded;
      expect(loadedState.selectedCountry?.name, equals('United Kingdom'));
      expect(loadedState.selectedCountry?.code, equals('GB'));
      expect(loadedState.countries, equals(testCountries));
    });

    test('pending country creates fallback when not found in loaded countries', () async {
      // Arrange: Set up mock to return countries
      when(() => mockCountriesService.getCountries())
          .thenAnswer((_) async => testCountries);
      
      // Act: Set initial country that doesn't exist in the list
      countriesCubit.setInitialCountry('Unknown Country');
      
      // Load countries
      await countriesCubit.loadCountries();
      
      // Assert: Countries loaded and fallback country is created
      expect(countriesCubit.state, isA<CountriesLoaded>());
      final loadedState = countriesCubit.state as CountriesLoaded;
      expect(loadedState.selectedCountry, isNotNull);
      expect(loadedState.selectedCountry?.name, equals('Unknown Country'));
      expect(loadedState.selectedCountry?.code, equals(''));
    });

    test('setInitialCountry works normally when countries already loaded', () async {
      // Arrange: Load countries first
      when(() => mockCountriesService.getCountries())
          .thenAnswer((_) async => testCountries);
      
      await countriesCubit.loadCountries();
      expect(countriesCubit.state, isA<CountriesLoaded>());
      
      // Act: Set initial country after countries are loaded
      countriesCubit.setInitialCountry('United States');
      
      // Assert: US is selected immediately
      final loadedState = countriesCubit.state as CountriesLoaded;
      expect(loadedState.selectedCountry?.name, equals('United States'));
      expect(loadedState.selectedCountry?.code, equals('US'));
    });

    test('multiple setInitialCountry calls - only last one is pending', () async {
      // Arrange: Set up mock to return countries
      when(() => mockCountriesService.getCountries())
          .thenAnswer((_) async => testCountries);
      
      // Act: Set multiple initial countries before loading
      countriesCubit.setInitialCountry('United States');
      countriesCubit.setInitialCountry('Canada');
      countriesCubit.setInitialCountry('United Kingdom');
      
      // Load countries
      await countriesCubit.loadCountries();
      
      // Assert: Only the last country (United Kingdom) is selected
      expect(countriesCubit.state, isA<CountriesLoaded>());
      final loadedState = countriesCubit.state as CountriesLoaded;
      expect(loadedState.selectedCountry?.name, equals('United Kingdom'));
      expect(loadedState.selectedCountry?.code, equals('GB'));
    });
  });
}

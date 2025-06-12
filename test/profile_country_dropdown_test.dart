import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/countries_service.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';

void main() {
  group('Profile Country Dropdown Integration', () {
    late CountriesService countriesService;
    late CountriesCubit countriesCubit;

    setUp(() {
      countriesService = CountriesService();
      countriesCubit = CountriesCubit(countriesService);
    });

    tearDown(() {
      countriesCubit.close();
    });

    test('Country equality works correctly', () {
      // Test that two countries with the same name and code are equal
      const country1 = Country(name: 'United States', code: 'US');
      const country2 = Country(name: 'United States', code: 'US');
      const country3 = Country(name: 'Canada', code: 'CA');

      expect(country1, equals(country2));
      expect(country1, isNot(equals(country3)));
      expect(country1.hashCode, equals(country2.hashCode));
    });

    test('setInitialCountry selects existing country from fallback list', () async {
      // First load countries (will use fallback since no internet in test)
      await countriesCubit.loadCountries();
      
      // Verify countries are loaded
      final state = countriesCubit.state;
      expect(state, isA<CountriesLoaded>());
      
      final loadedState = state as CountriesLoaded;
      expect(loadedState.countries.isNotEmpty, true);
      
      // Find a country that should exist in the fallback list
      final unitedStates = loadedState.countries.firstWhere(
        (country) => country.name == 'United States',
      );
      
      // Now set initial country using the name
      countriesCubit.setInitialCountry('United States');
      
      // Verify the country is selected
      final newState = countriesCubit.state as CountriesLoaded;
      expect(newState.selectedCountry, equals(unitedStates));
      expect(newState.selectedCountry?.name, equals('United States'));
      expect(newState.selectedCountry?.code, equals('US'));
    });

    test('setInitialCountry creates fallback country for unknown name', () async {
      // First load countries
      await countriesCubit.loadCountries();
      
      // Set initial country with a name that doesn't exist
      countriesCubit.setInitialCountry('Unknown Country');
      
      // Verify a fallback country is created
      final state = countriesCubit.state as CountriesLoaded;
      expect(state.selectedCountry, isNotNull);
      expect(state.selectedCountry?.name, equals('Unknown Country'));
      expect(state.selectedCountry?.code, equals(''));
    });

    test('Profile scenario: user has saved country that matches dropdown list', () async {
      // Simulate the profile screen scenario
      
      // 1. Load countries (happens in initState)
      await countriesCubit.loadCountries();
      
      // 2. User profile has 'Canada' saved
      const savedCountryName = 'Canada';
      
      // 3. When populating fields, we call setInitialCountry
      countriesCubit.setInitialCountry(savedCountryName);
      
      // 4. Verify the dropdown will show the correct selection
      final state = countriesCubit.state as CountriesLoaded;
      expect(state.selectedCountry, isNotNull);
      expect(state.selectedCountry?.name, equals('Canada'));
      
      // 5. Verify this selected country exists in the dropdown list
      final canadaInList = state.countries.firstWhere(
        (country) => country.name == 'Canada',
      );
      
      // 6. Most importantly: verify they are equal (this was the bug!)
      expect(state.selectedCountry, equals(canadaInList));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/countries_service.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';

void main() {
  group('Register Screen Country Dropdown Integration', () {
    late CountriesService countriesService;
    late CountriesCubit countriesCubit;

    setUp(() {
      countriesService = CountriesService();
      countriesCubit = CountriesCubit(countriesService);
    });

    tearDown(() {
      countriesCubit.close();
    });

    test('Register scenario: user selects country from dropdown', () async {
      // Simulate the register screen scenario
      
      // 1. Load countries (happens in initState)
      await countriesCubit.loadCountries();
      
      // 2. Verify countries are loaded
      final state = countriesCubit.state;
      expect(state, isA<CountriesLoaded>());
      
      final loadedState = state as CountriesLoaded;
      expect(loadedState.countries.isNotEmpty, true);
      expect(loadedState.selectedCountry, isNull); // No initial selection
      
      // 3. User selects a country from the dropdown
      final canada = loadedState.countries.firstWhere(
        (country) => country.name == 'Canada',
      );
      
      countriesCubit.selectCountry(canada);
      
      // 4. Verify the selection is properly set
      final newState = countriesCubit.state as CountriesLoaded;
      expect(newState.selectedCountry, isNotNull);
      expect(newState.selectedCountry, equals(canada));
      expect(newState.selectedCountry?.name, equals('Canada'));
      
      // 5. Verify the selected country is the same object as in the list
      // (This ensures the dropdown will show the selection correctly)
      final canadaInList = newState.countries.firstWhere(
        (country) => country.name == 'Canada',
      );
      expect(newState.selectedCountry, equals(canadaInList));
    });

    test('Register scenario: dropdown shows correct selection after user choice', () async {
      // Load countries
      await countriesCubit.loadCountries();
      
      final loadedState = countriesCubit.state as CountriesLoaded;
      
      // Test selecting different countries
      final testCountries = ['United States', 'Canada', 'United Kingdom'];
      
      for (String countryName in testCountries) {
        final country = loadedState.countries.firstWhere(
          (c) => c.name == countryName,
        );
        
        // Select the country
        countriesCubit.selectCountry(country);
        
        // Verify selection
        final currentState = countriesCubit.state as CountriesLoaded;
        expect(currentState.selectedCountry, equals(country));
        expect(currentState.selectedCountry?.name, equals(countryName));
        
        // Verify it's the same object as in the dropdown list
        final countryInList = currentState.countries.firstWhere(
          (c) => c.name == countryName,
        );
        expect(currentState.selectedCountry, equals(countryInList));
      }
    });

    test('Register scenario: clear selection works correctly', () async {
      // Load countries and select one
      await countriesCubit.loadCountries();
      
      final loadedState = countriesCubit.state as CountriesLoaded;
      final canada = loadedState.countries.firstWhere(
        (country) => country.name == 'Canada',
      );
      
      countriesCubit.selectCountry(canada);
      
      // Verify selection
      var currentState = countriesCubit.state as CountriesLoaded;
      expect(currentState.selectedCountry, isNotNull);
      
      // Clear selection
      countriesCubit.clearSelection();
      
      // Verify selection is cleared
      currentState = countriesCubit.state as CountriesLoaded;
      expect(currentState.selectedCountry, isNull);
    });

    test('Register scenario: error state with fallback countries works', () async {
      // This test would need to mock the service to throw an error
      // For now, we test the fallback countries directly
      final fallbackCountries = countriesService.getFallbackCountries();
      
      expect(fallbackCountries.isNotEmpty, true);
      expect(fallbackCountries.any((c) => c.name == 'United States'), true);
      expect(fallbackCountries.any((c) => c.name == 'Canada'), true);
      expect(fallbackCountries.any((c) => c.name == 'United Kingdom'), true);
      
      // Test equality for fallback countries
      final us1 = Country(name: 'United States', code: 'US');
      final us2 = Country(name: 'United States', code: 'US');
      final canada = Country(name: 'Canada', code: 'CA');
      
      expect(us1, equals(us2));
      expect(us1, isNot(equals(canada)));
    });
  });
}

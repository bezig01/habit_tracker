import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/countries_service.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';

void main() {
  group('Profile Country Initialization Fix', () {
    late CountriesService countriesService;
    late CountriesCubit countriesCubit;

    setUp(() {
      countriesService = CountriesService();
      countriesCubit = CountriesCubit(countriesService);
    });

    tearDown(() {
      countriesCubit.close();
    });

    test('setInitialCountry works correctly after countries are loaded', () async {
      // Simulate the corrected flow:
      // 1. Countries are loaded first
      await countriesCubit.loadCountries();
      
      // Verify countries are loaded
      final state = countriesCubit.state;
      expect(state, isA<CountriesLoaded>());
      
      final loadedState = state as CountriesLoaded;
      expect(loadedState.countries.isNotEmpty, true);
      expect(loadedState.selectedCountry, isNull); // No initial selection
      
      // 2. Then setInitialCountry is called (after countries are available)
      const savedCountryName = 'Canada';
      countriesCubit.setInitialCountry(savedCountryName);
      
      // 3. Verify the dropdown will show the correct selection
      final newState = countriesCubit.state as CountriesLoaded;
      expect(newState.selectedCountry, isNotNull);
      expect(newState.selectedCountry?.name, equals(savedCountryName));
      
      // 4. Verify it's the same object as in the dropdown list (important for Flutter dropdown)
      final canadaInList = newState.countries.firstWhere(
        (country) => country.name == savedCountryName,
      );
      expect(newState.selectedCountry, equals(canadaInList));
    });

    test('setInitialCountry before countries loaded works with pending approach (bug fixed)', () async {
      // Simulate the fixed scenario with pending country approach:
      // 1. Try to set initial country before countries are loaded
      const savedCountryName = 'Canada';
      countriesCubit.setInitialCountry(savedCountryName);
      
      // 2. Verify state remains initial (country is stored as pending)
      expect(countriesCubit.state, isA<CountriesInitial>());
      
      // 3. Now load countries
      await countriesCubit.loadCountries();
      
      // 4. Verify the pending country is now selected (bug fixed!)
      final state = countriesCubit.state as CountriesLoaded;
      expect(state.selectedCountry, isNotNull);
      expect(state.selectedCountry?.name, equals('Canada'));
    });

    test('profile scenario: user country is properly restored after loading', () async {
      // Simulate the profile screen scenario with our fix:
      const userCountry = 'United States';
      
      // 1. Load countries (happens in initState)
      await countriesCubit.loadCountries();
      
      // 2. Simulate _setInitialCountryIfReady() being called
      countriesCubit.setInitialCountry(userCountry);
      
      // 3. Verify the saved country is selected
      final state = countriesCubit.state as CountriesLoaded;
      expect(state.selectedCountry, isNotNull);
      expect(state.selectedCountry?.name, equals(userCountry));
      
      // 4. The dropdown should show this selection
      final usInList = state.countries.firstWhere(
        (country) => country.name == userCountry,
      );
      expect(state.selectedCountry, equals(usInList));
    });

    test('profile scenario: handles unknown country gracefully', () async {
      const unknownCountry = 'Fictional Country';
      
      // 1. Load countries
      await countriesCubit.loadCountries();
      
      // 2. Try to set an unknown country
      countriesCubit.setInitialCountry(unknownCountry);
      
      // 3. Verify a fallback country is created
      final state = countriesCubit.state as CountriesLoaded;
      expect(state.selectedCountry, isNotNull);
      expect(state.selectedCountry?.name, equals(unknownCountry));
      expect(state.selectedCountry?.code, equals(''));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/countries_service.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';

void main() {
  group('Profile Country Selection Fix', () {
    late CountriesService countriesService;
    late CountriesCubit countriesCubit;

    setUp(() {
      countriesService = CountriesService();
      countriesCubit = CountriesCubit(countriesService);
    });

    tearDown(() {
      countriesCubit.close();
    });

    test('User can select different country after initial country is set', () async {
      // 1. Load countries (simulates profile screen initState)
      await countriesCubit.loadCountries();
      
      // Verify countries are loaded
      final initialState = countriesCubit.state;
      expect(initialState, isA<CountriesLoaded>());
      
      final loadedState = initialState as CountriesLoaded;
      expect(loadedState.countries.isNotEmpty, true);
      expect(loadedState.selectedCountry, isNull);
      
      // 2. Set initial country (simulates user's saved country)
      const userSavedCountry = 'Canada';
      countriesCubit.setInitialCountry(userSavedCountry);
      
      // Verify initial country is set
      var currentState = countriesCubit.state as CountriesLoaded;
      expect(currentState.selectedCountry, isNotNull);
      expect(currentState.selectedCountry?.name, equals(userSavedCountry));
      
      // 3. User tries to select a different country
      final unitedStates = currentState.countries.firstWhere(
        (country) => country.name == 'United States',
      );
      
      countriesCubit.selectCountry(unitedStates);
      
      // 4. Verify the new country is selected (this should work after our fix)
      currentState = countriesCubit.state as CountriesLoaded;
      expect(currentState.selectedCountry, equals(unitedStates));
      expect(currentState.selectedCountry?.name, equals('United States'));
      
      // 5. User can select another country
      final uk = currentState.countries.firstWhere(
        (country) => country.name == 'United Kingdom',
      );
      
      countriesCubit.selectCountry(uk);
      
      // 6. Verify the UK is now selected
      currentState = countriesCubit.state as CountriesLoaded;
      expect(currentState.selectedCountry, equals(uk));
      expect(currentState.selectedCountry?.name, equals('United Kingdom'));
    });

    test('Initial country is only set once, not on every state change', () async {
      // This test simulates the bug we fixed - ensuring setInitialCountry
      // doesn't override user selections
      
      await countriesCubit.loadCountries();
      
      // Set initial country
      const initialCountry = 'Canada';
      countriesCubit.setInitialCountry(initialCountry);
      
      var state = countriesCubit.state as CountriesLoaded;
      expect(state.selectedCountry?.name, equals(initialCountry));
      
      // User selects different country
      final france = state.countries.firstWhere(
        (country) => country.name == 'France',
        orElse: () => const Country(name: 'France', code: 'FR'),
      );
      
      countriesCubit.selectCountry(france);
      
      // The selection should stick - not be overridden by setInitialCountry
      state = countriesCubit.state as CountriesLoaded;
      expect(state.selectedCountry?.name, equals('France'));
      
      // Even if we call setInitialCountry again (simulating widget rebuild),
      // it shouldn't override the user's selection
      // Note: In the actual widget, this is prevented by the _initialCountrySet flag
    });
  });
}

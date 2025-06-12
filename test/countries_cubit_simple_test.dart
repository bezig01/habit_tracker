import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';
import 'package:habit_tracker/services/countries_service.dart';

// Simple mock that returns test data
class MockCountriesService extends CountriesService {
  final bool shouldFail;
  
  MockCountriesService({this.shouldFail = false});
  
  @override
  Future<List<Country>> getCountries() async {
    if (shouldFail) {
      throw Exception('Network error');
    }
    
    return [
      const Country(name: 'United States', code: 'US'),
      const Country(name: 'Canada', code: 'CA'),
      const Country(name: 'United Kingdom', code: 'GB'),
    ];
  }
}

void main() {
  group('CountriesCubit', () {
    late CountriesCubit countriesCubit;
    late MockCountriesService mockCountriesService;

    setUp(() {
      mockCountriesService = MockCountriesService();
      countriesCubit = CountriesCubit(mockCountriesService);
    });

    tearDown(() {
      countriesCubit.close();
    });

    test('initial state is CountriesInitial', () {
      expect(countriesCubit.state, isA<CountriesInitial>());
    });

    test('selectCountry updates state correctly', () async {
      const testCountry = Country(name: 'Test Country', code: 'TC');
      
      // First load countries
      await countriesCubit.loadCountries();
      
      // Then select a country
      countriesCubit.selectCountry(testCountry);
      
      final state = countriesCubit.state;
      expect(state, isA<CountriesLoaded>());
      
      final loadedState = state as CountriesLoaded;
      expect(loadedState.selectedCountry, equals(testCountry));
    });

    test('setInitialCountry works with existing country', () async {
      // First load countries
      await countriesCubit.loadCountries();
      
      // Set initial country by name
      countriesCubit.setInitialCountry('Canada');
      
      final state = countriesCubit.state;
      expect(state, isA<CountriesLoaded>());
      
      final loadedState = state as CountriesLoaded;
      expect(loadedState.selectedCountry?.name, equals('Canada'));
    });

    test('clearSelection removes selected country', () async {
      const testCountry = Country(name: 'Test Country', code: 'TC');
      
      // First load countries and select one
      await countriesCubit.loadCountries();
      countriesCubit.selectCountry(testCountry);
      
      // Clear selection
      countriesCubit.clearSelection();
      
      final state = countriesCubit.state;
      expect(state, isA<CountriesLoaded>());
      
      final loadedState = state as CountriesLoaded;
      expect(loadedState.selectedCountry, isNull);
    });
  });
}

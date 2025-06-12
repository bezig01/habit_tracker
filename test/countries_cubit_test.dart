import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:habit_tracker/bloc/countries/countries_cubit.dart';
import 'package:habit_tracker/bloc/countries/countries_state.dart';
import 'package:habit_tracker/services/countries_service.dart';

// Mock class for CountriesService
class MockCountriesService extends Mock implements CountriesService {}

void main() {
  group('CountriesCubit', () {
    late CountriesCubit countriesCubit;
    late MockCountriesService mockCountriesService;
    
    final testCountries = [
      Country(name: 'United States', code: 'US'),
      Country(name: 'Canada', code: 'CA'),
      Country(name: 'United Kingdom', code: 'GB'),
    ];

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

    group('loadCountries', () {
      blocTest<CountriesCubit, CountriesState>(
        'emits [CountriesLoading, CountriesLoaded] when loadCountries succeeds',
        build: () {
          when(() => mockCountriesService.getCountries())
              .thenAnswer((_) async => testCountries);
          return countriesCubit;
        },
        act: (cubit) => cubit.loadCountries(),
        expect: () => [
          isA<CountriesLoading>(),
          isA<CountriesLoaded>().having(
            (state) => state.countries,
            'countries',
            testCountries,
          ),
        ],
        verify: (_) {
          verify(() => mockCountriesService.getCountries()).called(1);
        },
      );

      blocTest<CountriesCubit, CountriesState>(
        'emits [CountriesLoading, CountriesError] when loadCountries fails',
        build: () {
          when(() => mockCountriesService.getCountries())
              .thenThrow(Exception('Network error'));
          when(() => mockCountriesService.getFallbackCountries())
              .thenReturn(testCountries);
          return countriesCubit;
        },
        act: (cubit) => cubit.loadCountries(),
        expect: () => [
          isA<CountriesLoading>(),
          isA<CountriesError>(),
        ],
      );
    });

    group('selectCountry', () {
      blocTest<CountriesCubit, CountriesState>(
        'updates selected country when state is CountriesLoaded',
        build: () => countriesCubit,
        seed: () => CountriesLoaded(countries: testCountries),
        act: (cubit) => cubit.selectCountry(testCountries.first),
        expect: () => [
          CountriesLoaded(
            countries: testCountries,
            selectedCountry: testCountries.first,
          ),
        ],
      );

      blocTest<CountriesCubit, CountriesState>(
        'transitions from error to loaded when selecting country',
        build: () => countriesCubit,
        seed: () => const CountriesError(
          message: 'Error loading countries',
          fallbackCountries: [],
        ),
        act: (cubit) => cubit.selectCountry(testCountries.first),
        expect: () => [
          CountriesLoaded(
            countries: const [],
            selectedCountry: testCountries.first,
          ),
        ],
      );
    });

    group('setInitialCountry', () {
      blocTest<CountriesCubit, CountriesState>(
        'sets initial country by name when countries are loaded',
        build: () => countriesCubit,
        seed: () => CountriesLoaded(countries: testCountries),
        act: (cubit) => cubit.setInitialCountry('Canada'),
        expect: () => [
          CountriesLoaded(
            countries: testCountries,
            selectedCountry: testCountries[1], // Canada
          ),
        ],
      );

      blocTest<CountriesCubit, CountriesState>(
        'creates new country if not found in list',
        build: () => countriesCubit,
        seed: () => CountriesLoaded(countries: testCountries),
        act: (cubit) => cubit.setInitialCountry('Unknown Country'),
        expect: () => [
          CountriesLoaded(
            countries: testCountries,
            selectedCountry: const Country(name: 'Unknown Country', code: ''),
          ),
        ],
      );
    });

    group('clearSelection', () {
      blocTest<CountriesCubit, CountriesState>(
        'clears selected country',
        build: () => countriesCubit,
        seed: () => CountriesLoaded(
          countries: testCountries,
          selectedCountry: testCountries.first,
        ),
        act: (cubit) => cubit.clearSelection(),
        expect: () => [
          CountriesLoaded(
            countries: testCountries,
            selectedCountry: null,
          ),
        ],
      );
    });
  });
}

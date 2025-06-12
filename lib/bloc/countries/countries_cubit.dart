import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/countries_service.dart';
import 'countries_state.dart';

class CountriesCubit extends Cubit<CountriesState> {
  final CountriesService _countriesService;
  String? _pendingCountryName;

  CountriesCubit(this._countriesService) : super(CountriesInitial());

  Future<void> loadCountries() async {
    emit(CountriesLoading());
    
    try {
      final countries = await _countriesService.getCountries();
      emit(CountriesLoaded(countries: countries));
      
      // If there was a pending country name, try to select it now
      if (_pendingCountryName != null) {
        setInitialCountry(_pendingCountryName!);
        _pendingCountryName = null;
      }
    } catch (e) {
      // Get fallback countries if API fails
      final fallbackCountries = _countriesService.getFallbackCountries();
      emit(CountriesError(
        message: 'Failed to load countries from API. Using offline list.',
        fallbackCountries: fallbackCountries,
      ));
      
      // If there was a pending country name, try to select it now
      if (_pendingCountryName != null) {
        setInitialCountry(_pendingCountryName!);
        _pendingCountryName = null;
      }
    }
  }

  void selectCountry(Country? country) {
    final currentState = state;
    if (currentState is CountriesLoaded) {
      emit(currentState.copyWith(selectedCountry: country));
    } else if (currentState is CountriesError) {
      emit(CountriesLoaded(
        countries: currentState.fallbackCountries,
        selectedCountry: country,
      ));
    }
  }

  void setInitialCountry(String countryName) {
    final currentState = state;
    List<Country> countries = [];
    
    if (currentState is CountriesLoaded) {
      countries = currentState.countries;
    } else if (currentState is CountriesError) {
      countries = currentState.fallbackCountries;
    } else {
      // If countries aren't loaded yet, store the country name for later
      _pendingCountryName = countryName;
      return;
    }

    if (countries.isNotEmpty) {
      final matchingCountry = countries.firstWhere(
        (country) => country.name == countryName,
        orElse: () => Country(name: countryName, code: ''),
      );
      
      selectCountry(matchingCountry);
    }
  }

  void clearSelection() {
    final currentState = state;
    if (currentState is CountriesLoaded) {
      emit(currentState.copyWith(clearSelectedCountry: true));
    }
  }
}

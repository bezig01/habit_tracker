import 'package:equatable/equatable.dart';
import '../../services/countries_service.dart';

abstract class CountriesState extends Equatable {
  const CountriesState();

  @override
  List<Object?> get props => [];
}

class CountriesInitial extends CountriesState {}

class CountriesLoading extends CountriesState {}

class CountriesLoaded extends CountriesState {
  final List<Country> countries;
  final Country? selectedCountry;

  const CountriesLoaded({
    required this.countries,
    this.selectedCountry,
  });

  @override
  List<Object?> get props => [countries, selectedCountry];

  CountriesLoaded copyWith({
    List<Country>? countries,
    Country? selectedCountry,
    bool clearSelectedCountry = false,
  }) {
    return CountriesLoaded(
      countries: countries ?? this.countries,
      selectedCountry: clearSelectedCountry ? null : (selectedCountry ?? this.selectedCountry),
    );
  }
}

class CountriesError extends CountriesState {
  final String message;
  final List<Country> fallbackCountries;

  const CountriesError({
    required this.message,
    required this.fallbackCountries,
  });

  @override
  List<Object> get props => [message, fallbackCountries];
}

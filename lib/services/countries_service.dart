import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';

class Country extends Equatable {
  final String name;
  final String code;

  const Country({required this.name, required this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']?['common'] ?? '',
      code: json['cca2'] ?? '',
    );
  }

  @override
  String toString() => name;

  @override
  List<Object> get props => [name, code];
}

class CountriesService {
  static const String _baseUrl = 'https://restcountries.com/v3.1/all';

  Future<List<Country>> getCountries() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?fields=name,cca2'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final countries = data
            .map((json) => Country.fromJson(json))
            .toList();
        
        // Sort countries alphabetically
        countries.sort((a, b) => a.name.compareTo(b.name));
        return countries;
      } else {
        throw Exception('Failed to load countries: ${response.statusCode}');
      }
    } catch (e) {
      // Return a fallback list of common countries if API fails
      return getFallbackCountries();
    }
  }

  List<Country> getFallbackCountries() {
    return [
      Country(name: 'Afghanistan', code: 'AF'),
      Country(name: 'Albania', code: 'AL'),
      Country(name: 'Algeria', code: 'DZ'),
      Country(name: 'Argentina', code: 'AR'),
      Country(name: 'Armenia', code: 'AM'),
      Country(name: 'Australia', code: 'AU'),
      Country(name: 'Austria', code: 'AT'),
      Country(name: 'Bangladesh', code: 'BD'),
      Country(name: 'Belgium', code: 'BE'),
      Country(name: 'Brazil', code: 'BR'),
      Country(name: 'Canada', code: 'CA'),
      Country(name: 'China', code: 'CN'),
      Country(name: 'Denmark', code: 'DK'),
      Country(name: 'Egypt', code: 'EG'),
      Country(name: 'Finland', code: 'FI'),
      Country(name: 'France', code: 'FR'),
      Country(name: 'Germany', code: 'DE'),
      Country(name: 'Greece', code: 'GR'),
      Country(name: 'India', code: 'IN'),
      Country(name: 'Indonesia', code: 'ID'),
      Country(name: 'Iran', code: 'IR'),
      Country(name: 'Iraq', code: 'IQ'),
      Country(name: 'Ireland', code: 'IE'),
      Country(name: 'Israel', code: 'IL'),
      Country(name: 'Italy', code: 'IT'),
      Country(name: 'Japan', code: 'JP'),
      Country(name: 'Mexico', code: 'MX'),
      Country(name: 'Netherlands', code: 'NL'),
      Country(name: 'New Zealand', code: 'NZ'),
      Country(name: 'Norway', code: 'NO'),
      Country(name: 'Pakistan', code: 'PK'),
      Country(name: 'Poland', code: 'PL'),
      Country(name: 'Portugal', code: 'PT'),
      Country(name: 'Russia', code: 'RU'),
      Country(name: 'Saudi Arabia', code: 'SA'),
      Country(name: 'South Africa', code: 'ZA'),
      Country(name: 'South Korea', code: 'KR'),
      Country(name: 'Spain', code: 'ES'),
      Country(name: 'Sweden', code: 'SE'),
      Country(name: 'Switzerland', code: 'CH'),
      Country(name: 'Turkey', code: 'TR'),
      Country(name: 'Ukraine', code: 'UA'),
      Country(name: 'United Kingdom', code: 'GB'),
      Country(name: 'United States', code: 'US'),
    ];
  }
}

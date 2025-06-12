import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/countries_service.dart';

void main() {
  group('CountriesService Tests', () {
    test('Country model should work correctly', () {
      final country = Country(name: 'Test Country', code: 'TC');
      
      expect(country.name, equals('Test Country'));
      expect(country.code, equals('TC'));
      expect(country.toString(), equals('Test Country'));
    });

    test('Country fromJson should parse correctly', () {
      final json = {
        'name': {'common': 'United States'},
        'cca2': 'US'
      };
      
      final country = Country.fromJson(json);
      
      expect(country.name, equals('United States'));
      expect(country.code, equals('US'));
    });

    test('Country fromJson should handle missing fields', () {
      final json = <String, dynamic>{};
      
      final country = Country.fromJson(json);
      
      expect(country.name, equals(''));
      expect(country.code, equals(''));
    });
  });
}

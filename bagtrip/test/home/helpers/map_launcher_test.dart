import 'package:flutter_test/flutter_test.dart';

void main() {
  group('map URL generation', () {
    test('iOS Apple Maps URL format', () {
      const location = 'Eiffel Tower, Paris';
      final encoded = Uri.encodeComponent(location);
      final url = 'maps:?q=$encoded';
      expect(url, contains('maps:?q='));
      expect(url, contains('Eiffel'));
    });

    test('Android geo URL format', () {
      const location = 'Eiffel Tower, Paris';
      final encoded = Uri.encodeComponent(location);
      final url = 'geo:0,0?q=$encoded';
      expect(url, startsWith('geo:0,0?q='));
      expect(url, contains('Eiffel'));
    });

    test('fallback Google Maps web URL format', () {
      const location = 'Eiffel Tower, Paris';
      final encoded = Uri.encodeComponent(location);
      final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
      expect(url, startsWith('https://www.google.com/maps/search/'));
      expect(url, contains('Eiffel'));
    });

    test('special characters are encoded', () {
      const location = 'Café de Flore, 172 Bd Saint-Germain';
      final encoded = Uri.encodeComponent(location);
      expect(encoded, isNot(contains(' ')));
      expect(encoded, contains('Caf'));
    });
  });
}

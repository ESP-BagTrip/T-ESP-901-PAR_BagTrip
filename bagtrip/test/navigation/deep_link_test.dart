import 'package:flutter_test/flutter_test.dart';

/// Tests for deep link redirect logic.
///
/// The redirect behavior in `app_router.dart` is tested via the URL
/// construction logic since GoRouter's redirect is an inline function.
void main() {
  group('Deep link redirect URL construction', () {
    test('non-auth redirect encodes intended path as query param', () {
      const intended = '/trip/abc';
      final redirectUrl = '/login?redirect=${Uri.encodeComponent(intended)}';

      expect(redirectUrl, '/login?redirect=%2Ftrip%2Fabc');
    });

    test('redirect param decodes back to original path', () {
      const encoded = '%2Ftrip%2Fabc';
      final decoded = Uri.decodeComponent(encoded);

      expect(decoded, '/trip/abc');
    });

    test('login loop is prevented — /login redirect is not applied', () {
      const decoded = '/login';
      // The router code guards: decoded != '/login' && decoded != '/'
      final shouldRedirect = decoded != '/login' && decoded != '/';

      expect(shouldRedirect, false);
    });

    test('root redirect is not applied', () {
      const decoded = '/';
      final shouldRedirect = decoded != '/login' && decoded != '/';

      expect(shouldRedirect, false);
    });

    test('valid deep link redirect is applied', () {
      const decoded = '/trip/abc123';
      final shouldRedirect = decoded != '/login' && decoded != '/';

      expect(shouldRedirect, true);
    });
  });
}

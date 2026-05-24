import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late MockFirebaseCrashlytics mockCrashlytics;
  late CrashlyticsService service;

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(
      FlutterErrorDetails(exception: Exception('fallback')),
    );
  });

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    service = CrashlyticsService(crashlytics: mockCrashlytics);

    when(
      () => mockCrashlytics.setCrashlyticsCollectionEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCrashlytics.setUserIdentifier(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCrashlytics.setCustomKey(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCrashlytics.recordError(
        any(),
        any(),
        reason: any(named: 'reason'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockCrashlytics.recordFlutterFatalError(any()),
    ).thenAnswer((_) async {});
  });

  group('CrashlyticsService', () {
    test('initialize disables collection in debug mode', () async {
      await service.initialize();
      verify(
        () => mockCrashlytics.setCrashlyticsCollectionEnabled(!kDebugMode),
      ).called(1);
    });

    test('setUserId sets user identifier', () async {
      await service.setUserId('user-123');
      verify(() => mockCrashlytics.setUserIdentifier('user-123')).called(1);
    });

    test('clearUserId clears user identifier', () async {
      await service.clearUserId();
      verify(() => mockCrashlytics.setUserIdentifier('')).called(1);
    });

    test('recordFlutterFatalError delegates to crashlytics', () {
      final details = FlutterErrorDetails(exception: Exception('test'));
      service.recordFlutterFatalError(details);
      verify(() => mockCrashlytics.recordFlutterFatalError(details)).called(1);
    });

    test('recordPlatformError records as fatal', () {
      final error = Exception('platform error');
      final stack = StackTrace.current;
      final result = service.recordPlatformError(error, stack);
      expect(result, isTrue);
      verify(
        () => mockCrashlytics.recordError(error, stack, fatal: true),
      ).called(1);
    });

    // recordAppError skips in debug mode, so these verify no calls in test env
    test('recordAppError skips in debug mode', () async {
      const error = ServerError('server down', statusCode: 500);
      await service.recordAppError(error);
      // In debug mode (kDebugMode == true during tests), no recording happens
      verifyNever(
        () => mockCrashlytics.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
        ),
      );
    });
  });
}

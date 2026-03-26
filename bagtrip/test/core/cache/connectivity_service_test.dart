import 'dart:async';

import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityService service;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() async {
    await service.dispose();
    await connectivityController.close();
  });

  group('ConnectivityService', () {
    test('isOnline defaults to true', () {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      service = ConnectivityService(connectivity: mockConnectivity);
      expect(service.isOnline, isTrue);
    });

    test('initialize sets isOnline based on initial check', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      service = ConnectivityService(connectivity: mockConnectivity);
      await service.initialize();

      expect(service.isOnline, isFalse);
    });

    test('stream emits when connectivity changes', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      service = ConnectivityService(connectivity: mockConnectivity);
      await service.initialize();

      final emissions = <bool>[];
      service.onConnectivityChanged.listen(emissions.add);

      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, [false]);
      expect(service.isOnline, isFalse);
    });

    test('deduplicates identical connectivity states', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      service = ConnectivityService(connectivity: mockConnectivity);
      await service.initialize();

      final emissions = <bool>[];
      service.onConnectivityChanged.listen(emissions.add);

      // Already online, sending wifi again should not emit
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, isEmpty);
    });

    test('emits on transition from offline to online', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      service = ConnectivityService(connectivity: mockConnectivity);
      await service.initialize();

      final emissions = <bool>[];
      service.onConnectivityChanged.listen(emissions.add);

      connectivityController.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, [true]);
      expect(service.isOnline, isTrue);
    });
  });
}

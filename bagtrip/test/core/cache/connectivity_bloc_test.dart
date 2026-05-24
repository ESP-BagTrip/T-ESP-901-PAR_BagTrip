import 'dart:async';

import 'package:bagtrip/core/cache/connectivity_bloc.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockConnectivityService mockService;
  late StreamController<bool> connectivityController;

  setUp(() {
    mockService = MockConnectivityService();
    connectivityController = StreamController<bool>.broadcast();
    when(() => mockService.isOnline).thenReturn(true);
    when(
      () => mockService.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() async {
    await connectivityController.close();
  });

  group('ConnectivityBloc', () {
    blocTest<ConnectivityBloc, ConnectivityState>(
      'initial state is ConnectivityOnline when service is online',
      build: () => ConnectivityBloc(connectivityService: mockService),
      verify: (bloc) {
        expect(bloc.state, isA<ConnectivityOnline>());
      },
    );

    blocTest<ConnectivityBloc, ConnectivityState>(
      'emits ConnectivityOffline when service reports offline initially',
      setUp: () {
        when(() => mockService.isOnline).thenReturn(false);
      },
      build: () => ConnectivityBloc(connectivityService: mockService),
      expect: () => [isA<ConnectivityOffline>()],
    );

    blocTest<ConnectivityBloc, ConnectivityState>(
      'emits ConnectivityOffline then ConnectivityOnline on stream changes',
      build: () => ConnectivityBloc(connectivityService: mockService),
      act: (bloc) {
        connectivityController.add(false);
        connectivityController.add(true);
      },
      expect: () => [isA<ConnectivityOffline>(), isA<ConnectivityOnline>()],
    );

    blocTest<ConnectivityBloc, ConnectivityState>(
      'emits ConnectivityOffline on connectivity lost',
      build: () => ConnectivityBloc(connectivityService: mockService),
      act: (bloc) {
        connectivityController.add(false);
      },
      expect: () => [isA<ConnectivityOffline>()],
    );
  });
}

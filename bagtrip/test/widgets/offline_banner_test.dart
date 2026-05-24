import 'dart:async';

import 'package:bagtrip/components/offline_banner.dart';
import 'package:bagtrip/core/cache/connectivity_bloc.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  Widget buildApp(ConnectivityBloc bloc) {
    return MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: BlocProvider<ConnectivityBloc>.value(
          value: bloc,
          child: const OfflineBanner(),
        ),
      ),
    );
  }

  group('OfflineBanner', () {
    testWidgets('is hidden when connectivity is online', (tester) async {
      final bloc = ConnectivityBloc(connectivityService: mockService);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pump();

      expect(find.byKey(const ValueKey('online')), findsOneWidget);
      expect(find.byKey(const ValueKey('offline')), findsNothing);
      expect(find.text('You are offline. Showing cached data.'), findsNothing);
    });

    testWidgets('becomes visible when connectivity goes offline', (
      tester,
    ) async {
      final bloc = ConnectivityBloc(connectivityService: mockService);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pump();

      // Simulate losing connectivity.
      connectivityController.add(false);
      await tester.pump();
      // Let the AnimatedSwitcher cross-fade finish.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('offline')), findsOneWidget);
      expect(
        find.text('You are offline. Showing cached data.'),
        findsOneWidget,
      );
    });

    testWidgets('hides again when connectivity is restored', (tester) async {
      final bloc = ConnectivityBloc(connectivityService: mockService);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pump();

      connectivityController.add(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('offline')), findsOneWidget);

      connectivityController.add(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('online')), findsOneWidget);
      expect(find.byKey(const ValueKey('offline')), findsNothing);
    });

    testWidgets('shows banner immediately when starting offline', (
      tester,
    ) async {
      when(() => mockService.isOnline).thenReturn(false);
      final bloc = ConnectivityBloc(connectivityService: mockService);
      addTearDown(bloc.close);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('offline')), findsOneWidget);
    });
  });
}

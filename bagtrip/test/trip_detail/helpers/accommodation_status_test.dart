import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/helpers/accommodation_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('deriveAccommodationStatus', () {
    test(
      'returns confirmed when bookingReference is non-null and non-empty',
      () {
        final a = makeAccommodation(bookingReference: 'BK-123');
        expect(
          deriveAccommodationStatus(a),
          AccommodationDisplayStatus.confirmed,
        );
      },
    );

    test('returns pending when bookingReference is null', () {
      final a = makeAccommodation();
      expect(deriveAccommodationStatus(a), AccommodationDisplayStatus.pending);
    });

    test('returns pending when bookingReference is empty', () {
      final a = makeAccommodation(bookingReference: '');
      expect(deriveAccommodationStatus(a), AccommodationDisplayStatus.pending);
    });
  });

  group('accommodationStatusColor', () {
    test('confirmed → success color', () {
      expect(
        accommodationStatusColor(AccommodationDisplayStatus.confirmed),
        AppColors.success,
      );
    });

    test('pending → warning color', () {
      expect(
        accommodationStatusColor(AccommodationDisplayStatus.pending),
        AppColors.warning,
      );
    });
  });

  group('accommodationStatusLabel', () {
    testWidgets('returns correct labels', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        accommodationStatusLabel(AccommodationDisplayStatus.confirmed, l10n),
        'Confirmed',
      );
      expect(
        accommodationStatusLabel(AccommodationDisplayStatus.pending, l10n),
        'Pending',
      );
    });
  });
}

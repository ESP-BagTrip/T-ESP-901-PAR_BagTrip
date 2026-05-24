import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app_en.arb and app_fr.arb have identical keys', () {
    final en = _loadArbKeys('lib/l10n/app_en.arb');
    final fr = _loadArbKeys('lib/l10n/app_fr.arb');

    final missingInFr = en.difference(fr);
    final missingInEn = fr.difference(en);

    expect(
      missingInFr,
      isEmpty,
      reason: 'Keys in EN but missing in FR: $missingInFr',
    );
    expect(
      missingInEn,
      isEmpty,
      reason: 'Keys in FR but missing in EN: $missingInEn',
    );
  });

  test('ARB files are valid JSON', () {
    for (final path in ['lib/l10n/app_en.arb', 'lib/l10n/app_fr.arb']) {
      final content = File(path).readAsStringSync();
      expect(
        () => jsonDecode(content),
        returnsNormally,
        reason: '$path is not valid JSON',
      );
    }
  });
}

Set<String> _loadArbKeys(String relativePath) {
  final file = File(relativePath);
  final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return map.keys.where((k) => !k.startsWith('@')).toSet();
}

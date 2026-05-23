import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/home_summary.dart';

/// Single aggregated read for the home screen (SMP327-021).
abstract class HomeRepository {
  /// `GET /home` — grouped trips + user + active-trip activities + weather.
  Future<Result<HomeSummary>> getHome();
}

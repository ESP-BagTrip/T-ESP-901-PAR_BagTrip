import 'package:bagtrip/core/app_error.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

extension ResultX<T> on Result<T> {
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };
}

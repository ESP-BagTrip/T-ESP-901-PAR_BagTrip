import 'package:flutter/material.dart';

/// A loading indicator that automatically renders the native look on each
/// platform:
/// - Android: [CircularProgressIndicator]
/// - iOS: [CupertinoActivityIndicator]
///
/// Uses Flutter's built-in `.adaptive()` constructor.
class AdaptiveIndicator extends StatelessWidget {
  const AdaptiveIndicator({super.key, this.radius, this.color});

  final double? radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator.adaptive(
      valueColor: color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
    );
  }
}

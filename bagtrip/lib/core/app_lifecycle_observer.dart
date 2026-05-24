import 'package:flutter/widgets.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResumed;

  AppLifecycleObserver({required this.onResumed});

  void initialize() => WidgetsBinding.instance.addObserver(this);
  void dispose() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}

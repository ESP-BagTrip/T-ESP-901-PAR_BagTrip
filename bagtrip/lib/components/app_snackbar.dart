import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class AppSnackBar {
  static OverlayEntry? _currentEntry;

  static void showError(BuildContext context, {required String message}) {
    // Remove existing snackbar if any
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => _SnackBarWidget(
            message: message,
            onDismiss: () {
              if (_currentEntry == overlayEntry) {
                _currentEntry = null;
              }
              overlayEntry.remove();
            },
          ),
    );

    _currentEntry = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

class _SnackBarWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _SnackBarWidget({required this.message, required this.onDismiss});

  @override
  State<_SnackBarWidget> createState() => _SnackBarWidgetState();
}

class _SnackBarWidgetState extends State<_SnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.allEdgeInsetSpace16,
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.error,
                    borderRadius: AppRadius.large16,
                    boxShadow: [
                      BoxShadow(
                        color: ColorName.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

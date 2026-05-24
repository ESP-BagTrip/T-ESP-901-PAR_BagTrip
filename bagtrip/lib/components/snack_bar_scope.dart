import 'dart:ui';

import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

enum SnackBarType {
  error(AppColors.errorDark),
  success(AppColors.success),
  info(AppColors.primaryTrueDark);

  const SnackBarType(this.color);
  final Color color;
}

abstract class SnackBarScopeController {
  void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
  });
}

class SnackBarScope extends StatefulWidget {
  const SnackBarScope({required this.child, super.key});

  final Widget child;

  static SnackBarScopeController of(BuildContext context) {
    final data = context
        .dependOnInheritedWidgetOfExactType<_SnackBarScopeData>();
    assert(data != null, 'No SnackBarScope found in context');
    return data!.state;
  }

  @override
  State<SnackBarScope> createState() => _SnackBarScopeState();
}

class _SnackBarScopeState extends State<SnackBarScope>
    implements SnackBarScopeController {
  OverlayEntry? _currentEntry;

  @override
  void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
  }) {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _SnackBarWidget(
        message: message,
        type: type,
        onDismiss: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  @override
  void dispose() {
    _currentEntry?.remove();
    _currentEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SnackBarScopeData(state: this, child: widget.child);
  }
}

class _SnackBarScopeData extends InheritedWidget {
  const _SnackBarScopeData({required this.state, required super.child});

  final _SnackBarScopeState state;

  @override
  bool updateShouldNotify(_SnackBarScopeData oldWidget) =>
      state != oldWidget.state;
}

class _SnackBarWidget extends StatefulWidget {
  const _SnackBarWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final SnackBarType type;
  final VoidCallback onDismiss;

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
      begin: const Offset(0, -1),
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
    final isIOS = AdaptivePlatform.isIOS;

    return Positioned(
      top: 0,
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
                child: isIOS ? _buildIOSToast() : _buildMaterialToast(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSToast() {
    return ClipRRect(
      borderRadius: AppRadius.large16,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.type.color.withValues(alpha: 0.85),
            borderRadius: AppRadius.large16,
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialToast() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.type.color,
        borderRadius: AppRadius.large16,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTrueDark.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Text(
        widget.message,
        style: const TextStyle(
          color: AppColors.surface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

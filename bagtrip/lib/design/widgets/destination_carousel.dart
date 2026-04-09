import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Horizontal paginated carousel for destination cards.
///
/// Pure design-system component — no BLoC dependency.
class DestinationCarousel extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int? selectedIndex;
  final ValueChanged<int>? onPageChanged;
  final double viewportFraction;
  final bool showIndicators;
  final double? height;
  final int initialPage;

  const DestinationCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.selectedIndex,
    this.onPageChanged,
    this.viewportFraction = 0.85,
    this.showIndicators = true,
    this.height,
    this.initialPage = 0,
  });

  @override
  State<DestinationCarousel> createState() => _DestinationCarouselState();
}

class _DestinationCarouselState extends State<DestinationCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.selectedIndex ?? widget.initialPage;
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    AppHaptics.light();
    widget.onPageChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height ?? 320,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.itemCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  // ignore: unnecessary_this
                  double scale = 1.0;
                  if (_pageController.position.haveDimensions) {
                    final page =
                        _pageController.page ?? _currentPage.toDouble();
                    final diff = (page - index).abs();
                    scale = (1 - diff * 0.08).clamp(0.92, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: widget.itemBuilder(context, index),
              );
            },
          ),
        ),
        if (widget.showIndicators) ...[
          const SizedBox(height: AppSpacing.space16),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.itemCount, (i) {
              final isActive = i == _currentPage;
              return Padding(
                padding: EdgeInsets.only(
                  right: i < widget.itemCount - 1 ? AppSpacing.space8 : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? ColorName.primary
                        : ColorName.primarySoftLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

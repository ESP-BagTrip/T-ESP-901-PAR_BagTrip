import 'dart:async';

import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/progression_cta_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/data/manual_destination_catalog.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class StepDestinationView extends StatefulWidget {
  const StepDestinationView({super.key});

  @override
  State<StepDestinationView> createState() => _StepDestinationViewState();
}

class _StepDestinationViewState extends State<StepDestinationView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.removeListener(_onFocusChanged);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      context.read<PlanTripBloc>().add(
        const PlanTripEvent.searchDestination(''),
      );
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<PlanTripBloc>().add(PlanTripEvent.searchDestination(query));
    });
  }

  String _countryCodeToFlag(String code) {
    if (code.length != 2) return '';
    return String.fromCharCodes([
      code.codeUnitAt(0) - 0x41 + 0x1F1E6,
      code.codeUnitAt(1) - 0x41 + 0x1F1E6,
    ]);
  }

  String _displayLine(LocationResult loc) {
    if (loc.countryName.isEmpty) return loc.name;
    return '${loc.name}, ${loc.countryName}';
  }

  void _selectDestination(LocationResult loc) {
    AppHaptics.light();
    _searchController.text = _displayLine(loc);
    context.read<PlanTripBloc>().add(
      PlanTripEvent.selectManualDestination(loc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final focused = _searchFocus.hasFocus;

    return BlocConsumer<PlanTripBloc, PlanTripState>(
      listenWhen: (prev, curr) =>
          prev.isLoadingAiSuggestions != curr.isLoadingAiSuggestions,
      listener: (context, state) {
        if (state.currentStep == 2 &&
            !state.isLoadingAiSuggestions &&
            state.aiSuggestions.isNotEmpty) {
          context.read<PlanTripBloc>().add(const PlanTripEvent.goToStep(3));
        }
      },
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space22,
            AppSpacing.space22,
            AppSpacing.space22,
            40,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  l10n.destinationSectionLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorName.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: AppRadius.large13,
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: ColorName.secondary.withValues(alpha: 0.22),
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: ColorName.surface,
                  borderRadius: AppRadius.large13,
                  border: Border.all(
                    color: focused
                        ? ColorName.secondary.withValues(alpha: 0.45)
                        : ColorName.primarySoftLight,
                  ),
                ),
                child: TextField(
                  focusNode: _searchFocus,
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    color: PersonalizationColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.destinationPlaceholder,
                    hintStyle: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: ColorName.hint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: focused ? ColorName.secondary : ColorName.hint,
                      size: 22,
                    ),
                    suffixIcon: _buildSearchSuffix(state),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            if (state.searchResults.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space8),
              _SearchResultsPanel(
                locations: state.searchResults,
                flagFor: _countryCodeToFlag,
                onSelect: _selectDestination,
              ),
            ],

            if (state.selectedManualDestination == null &&
                state.selectedManualDestination != null) ...[
              const SizedBox(height: AppSpacing.space16),
              Center(
                child: Text(
                  l10n.destinationNoResults,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                    color: ColorName.hint,
                  ),
                ),
              ),
            ],

            if (state.selectedManualDestination != null) ...[
              const SizedBox(height: AppSpacing.space24),
              _SelectedBadge(
                location: state.selectedManualDestination!,
                flag: _countryCodeToFlag(
                  state.selectedManualDestination!.countryCode.toUpperCase(),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              ProgressionCtaButton(
                text: l10n.continueButton,
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  AppHaptics.medium();
                  context.read<PlanTripBloc>().add(
                    const PlanTripEvent.nextStep(),
                  );
                },
              ),
            ],

            const SizedBox(height: AppSpacing.space24),
            _OrSeparator(label: l10n.destinationOrSeparator),
            const SizedBox(height: AppSpacing.space24),

            _InspireMeButton(
              isLoading: state.isLoadingAiSuggestions,
              onPressed: state.isLoadingAiSuggestions
                  ? null
                  : () {
                      AppHaptics.medium();
                      context.read<PlanTripBloc>().add(
                        const PlanTripEvent.requestAiSuggestions(),
                      );
                    },
            ),

            const SizedBox(height: AppSpacing.space24),
            Text(
              l10n.destinationPopularSectionLabel,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ColorName.hint,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _PopularDestinationsGrid(
              onSelect: _selectDestination,
              flagFor: _countryCodeToFlag,
            ),

            if (state.error != null) ...[
              const SizedBox(height: AppSpacing.space16),
              Center(
                child: Text(
                  toUserFriendlyMessage(
                    state.error!,
                    AppLocalizations.of(context)!,
                  ),
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget? _buildSearchSuffix(PlanTripState state) {
    if (state.isSearching) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorName.secondary,
          ),
        ),
      );
    }
    if (_searchController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.close_rounded, size: 20, color: ColorName.hint),
        onPressed: () {
          _searchController.clear();
          context.read<PlanTripBloc>().add(
            const PlanTripEvent.searchDestination(''),
          );
        },
      );
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Search results (single panel + dividers)
// ---------------------------------------------------------------------------

class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel({
    required this.locations,
    required this.flagFor,
    required this.onSelect,
  });

  final List<LocationResult> locations;
  final String Function(String code) flagFor;
  final void Function(LocationResult loc) onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.surface,
      borderRadius: AppRadius.large13,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.large13,
          border: Border.all(color: ColorName.primarySoftLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < locations.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: ColorName.primarySoftLight),
              InkWell(
                onTap: () => onSelect(locations[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        flagFor(locations[i].countryCode.toUpperCase()),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locations[i].name,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: PersonalizationColors.textPrimary,
                              ),
                            ),
                            if (locations[i].countryName.isNotEmpty)
                              Text(
                                locations[i].countryName,
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: PersonalizationColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: ColorName.hint.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "OU" separator
// ---------------------------------------------------------------------------

class _OrSeparator extends StatelessWidget {
  final String label;

  const _OrSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: ColorName.primarySoftLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ColorName.hint,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(child: Divider(color: ColorName.primarySoftLight)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Inspire-moi" button
// ---------------------------------------------------------------------------

class _InspireMeButton extends StatefulWidget {
  const _InspireMeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<_InspireMeButton> createState() => _InspireMeButtonState();
}

class _InspireMeButtonState extends State<_InspireMeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (!widget.isLoading) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _InspireMeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _pulse.stop();
      } else {
        _pulse.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.pill,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorName.primary, ColorName.secondary],
                ),
              ),
              child: SizedBox(height: 52, width: double.infinity),
            ),
            if (!widget.isLoading)
              Positioned.fill(
                child: Shimmer.fromColors(
                  baseColor: ColorName.shimmerBase.withValues(alpha: 0.15),
                  highlightColor: Colors.white.withValues(alpha: 0.35),
                  period: const Duration(milliseconds: 2000),
                  child: Container(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: AppRadius.pill,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space15,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _pulse,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: const Text(
                              '✦',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        const SizedBox(width: AppSpacing.space8),
                        Text(
                          l10n.inspireMe,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: FontFamily.b612,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popular destinations grid
// ---------------------------------------------------------------------------

class _PopularDestinationsGrid extends StatefulWidget {
  const _PopularDestinationsGrid({
    required this.onSelect,
    required this.flagFor,
  });

  final void Function(LocationResult loc) onSelect;
  final String Function(String code) flagFor;

  @override
  State<_PopularDestinationsGrid> createState() =>
      _PopularDestinationsGridState();
}

class _PopularDestinationsGridState extends State<_PopularDestinationsGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _totalMs = 520.0;
  static const _staggerMs = 40.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _staggerValue(int index) {
    final start = (index * _staggerMs) / _totalMs;
    final v = _controller.value;
    if (v <= start) return 0;
    return Curves.easeOutCubic.transform(
      ((v - start) / (1 - start)).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = ManualDestinationCatalog.popular;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.space12,
            crossAxisSpacing: AppSpacing.space12,
          ),
          itemCount: spots.length,
          itemBuilder: (context, index) {
            final t = _staggerValue(index);
            final spot = spots[index];
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - t)),
                child: _PopularDestinationCard(
                  spot: spot,
                  flag: widget.flagFor(spot.location.countryCode.toUpperCase()),
                  onTap: () => widget.onSelect(spot.location),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PopularDestinationCard extends StatelessWidget {
  const _PopularDestinationCard({
    required this.spot,
    required this.flag,
    required this.onTap,
  });

  final ManualPopularDestination spot;
  final String flag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.large13,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        borderRadius: AppRadius.large13,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: spot.gradient,
            ),
            borderRadius: AppRadius.large13,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 10,
                bottom: 10,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      flag,
                      style: const TextStyle(fontSize: 20, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.location.name,
                      style: TextStyle(
                        fontFamily: FontFamily.dMSans,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selected destination badge
// ---------------------------------------------------------------------------

class _SelectedBadge extends StatelessWidget {
  final LocationResult location;
  final String flag;

  const _SelectedBadge({required this.location, required this.flag});

  @override
  Widget build(BuildContext context) {
    final label = location.iataCode.isNotEmpty
        ? '${location.name} (${location.iataCode})'
        : location.name;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: ColorName.surface,
          borderRadius: AppRadius.pill,
          border: Border.all(color: ColorName.primarySoftLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: ColorName.secondary,
            ),
            const SizedBox(width: AppSpacing.space8),
            if (flag.isNotEmpty) ...[
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.space4),
            ],
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primaryTrueDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

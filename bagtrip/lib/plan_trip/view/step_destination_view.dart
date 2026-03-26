import 'dart:async';

import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepDestinationView extends StatefulWidget {
  const StepDestinationView({super.key});

  @override
  State<StepDestinationView> createState() => _StepDestinationViewState();
}

class _StepDestinationViewState extends State<StepDestinationView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        final query = _searchController.text.trim();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            // Section header
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

            // Search field
            Container(
              decoration: BoxDecoration(
                color: ColorName.surface,
                borderRadius: AppRadius.large16,
                border: Border.all(color: ColorName.primarySoftLight),
              ),
              child: TextField(
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
                    color: ColorName.hint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: ColorName.hint,
                    size: 22,
                  ),
                  suffixIcon: _buildSearchSuffix(state),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // "OU" separator
            _OrSeparator(label: l10n.destinationOrSeparator),
            const SizedBox(height: AppSpacing.space24),

            // "Inspire-moi" CTA
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

            // AI loading indicator
            if (state.isLoadingAiSuggestions) ...[
              const SizedBox(height: AppSpacing.space24),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PersonalizationColors.accentViolet,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      l10n.destinationAiLoading,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: PersonalizationColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Search results
            if (state.searchResults.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space16),
              ...state.searchResults.map(
                (loc) => _LocationResultTile(
                  location: loc,
                  flag: _countryCodeToFlag(loc.countryCode.toUpperCase()),
                  onTap: () {
                    AppHaptics.light();
                    _searchController.clear();
                    context.read<PlanTripBloc>().add(
                      PlanTripEvent.selectManualDestination(loc),
                    );
                  },
                ),
              ),
            ],

            // No results
            if (state.searchResults.isEmpty &&
                !state.isSearching &&
                query.length >= 2) ...[
              const SizedBox(height: AppSpacing.space24),
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

            // Selected destination badge + Continue
            if (state.selectedManualDestination != null) ...[
              const SizedBox(height: AppSpacing.space24),
              _SelectedBadge(
                location: state.selectedManualDestination!,
                flag: _countryCodeToFlag(
                  state.selectedManualDestination!.countryCode.toUpperCase(),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              _ContinueButton(
                onPressed: () {
                  AppHaptics.medium();
                  context.read<PlanTripBloc>().add(
                    const PlanTripEvent.nextStep(),
                  );
                },
              ),
            ],

            // Error
            if (state.error != null) ...[
              const SizedBox(height: AppSpacing.space16),
              Center(
                child: Text(
                  state.error!,
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

class _InspireMeButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _InspireMeButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: PersonalizationColors.accentGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PersonalizationColors.accentBlue.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Location result tile
// ---------------------------------------------------------------------------

class _LocationResultTile extends StatelessWidget {
  final LocationResult location;
  final String flag;
  final VoidCallback onTap;

  const _LocationResultTile({
    required this.location,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Material(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space12,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.large16,
              border: Border.all(color: ColorName.primarySoftLight),
            ),
            child: Row(
              children: [
                if (flag.isNotEmpty)
                  Text(flag, style: const TextStyle(fontSize: 24)),
                if (flag.isNotEmpty) const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: PersonalizationColors.textPrimary,
                        ),
                      ),
                      if (location.countryName.isNotEmpty)
                        Text(
                          location.countryName,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 12,
                            color: PersonalizationColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (location.iataCode.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space8,
                      vertical: AppSpacing.space4,
                    ),
                    decoration: const BoxDecoration(
                      color: ColorName.primaryLight,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      location.iataCode,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primaryTrueDark,
                      ),
                    ),
                  ),
              ],
            ),
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

// ---------------------------------------------------------------------------
// Continue button (same pattern as other steps)
// ---------------------------------------------------------------------------

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorName.primary, ColorName.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Text(
              l10n.continueButton,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: FontFamily.b612,
                fontWeight: FontWeight.w600,
                color: ColorName.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/models/trip_summary.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/assets.gen.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Mock: category labels for day-by-day timeline (index 0..4).
const List<String> _mockDayCategoryKeys = [
  'summaryCategoryTravelDay',
  'summaryCategoryCulture',
  'summaryCategoryCuisine',
  'summaryCategoryDayTrip',
  'summaryCategoryDeparture',
];

/// Mock: accommodation subtitle (not in TripSummary).
const String _mockAccommodationSubtitle = 'Le Marais, Paris · 4-star boutique';

/// Mock flight content uses L10n: summaryFlightRouteMock, summaryFlightDetailsMock.

class CreateTripAiSummaryView extends StatefulWidget {
  const CreateTripAiSummaryView({super.key});

  @override
  State<CreateTripAiSummaryView> createState() =>
      _CreateTripAiSummaryViewState();
}

class _CreateTripAiSummaryViewState extends State<CreateTripAiSummaryView> {
  /// Local state for essentials checklist (checked indices).
  final Set<int> _essentialChecked = {};

  String _getCategoryLabel(AppLocalizations l10n, int index) {
    if (index >= _mockDayCategoryKeys.length) return '';
    switch (_mockDayCategoryKeys[index]) {
      case 'summaryCategoryTravelDay':
        return l10n.summaryCategoryTravelDay;
      case 'summaryCategoryCulture':
        return l10n.summaryCategoryCulture;
      case 'summaryCategoryCuisine':
        return l10n.summaryCategoryCuisine;
      case 'summaryCategoryDayTrip':
        return l10n.summaryCategoryDayTrip;
      case 'summaryCategoryDeparture':
        return l10n.summaryCategoryDeparture;
      default:
        return '';
    }
  }

  IconData _getCategoryIcon(int index) {
    if (index >= _mockDayCategoryKeys.length) return Icons.circle;
    switch (_mockDayCategoryKeys[index]) {
      case 'summaryCategoryTravelDay':
        return Icons.train;
      case 'summaryCategoryCulture':
        return Icons.museum;
      case 'summaryCategoryCuisine':
        return Icons.restaurant;
      case 'summaryCategoryDayTrip':
        return Icons.castle;
      case 'summaryCategoryDeparture':
        return Icons.flight_takeoff;
      default:
        return Icons.circle;
    }
  }

  IconData _getEssentialIcon(int index) {
    const icons = [
      Icons.public,
      Icons.power,
      Icons.wb_sunny,
      Icons.medical_services,
      Icons.directions_walk,
    ];
    return index < icons.length ? icons[index] : Icons.checklist;
  }

  String _getDayDate(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.summaryDay1Date;
      case 1:
        return l10n.summaryDay2Date;
      case 2:
        return l10n.summaryDay3Date;
      case 3:
        return l10n.summaryDay4Date;
      case 4:
        return l10n.summaryDay5Date;
      default:
        return '${l10n.summaryDayPrefix}${index + 1}';
    }
  }

  String _getDayDescription(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.summaryDay1Description;
      case 1:
        return l10n.summaryDay2Description;
      case 2:
        return l10n.summaryDay3Description;
      case 3:
        return l10n.summaryDay4Description;
      case 4:
        return l10n.summaryDay5Description;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
      builder: (context, state) {
        if (state is CreateTripAiSummaryLoaded) {
          return _buildSummary(context, state.summary);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildSummary(BuildContext context, TripSummary s) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ColorName.surfaceLight,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            _buildUpcomingJourney(context, l10n, s),
            SliverToBoxAdapter(child: _buildWhiteSheet(context, l10n, s)),
          ],
        ),
      ),
    );
  }

  /// [1] Upcoming Journey block (image background, extends under top safe area).
  Widget _buildUpcomingJourney(
    BuildContext context,
    AppLocalizations l10n,
    TripSummary s,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverToBoxAdapter(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Image.asset(
              Assets.images.parisMockPicture.path,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2A4A6E).withValues(alpha: 0.3),
                    const Color(0xFF1F3A5F).withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.space8,
              right: AppSpacing.space24,
              top: topPadding + AppSpacing.space8,
              bottom: AppSpacing.space24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorName.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: ColorName.surface,
                      size: 24,
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.space16,
                    right: AppSpacing.space8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        s.destination,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.destinationCountry,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      Row(
                        children: [
                          _upcomingChip(
                            icon: Icons.calendar_today_rounded,
                            label: l10n.summaryDaysCount(s.durationDays),
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          _upcomingChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: l10n.summaryBudgetAmount(
                              _formatBudget(s.budgetEur),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          _upcomingChip(
                            icon: Icons.person_outline,
                            label: l10n.summarySolo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBudget(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')},${value % 1000 == 0 ? '000' : value % 1000}';
    }
    return value.toString();
  }

  Widget _upcomingChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: ColorName.primary,
        borderRadius: AppRadius.medium8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorName.primaryLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 13,
              color: ColorName.surface,
            ),
          ),
        ],
      ),
    );
  }

  /// [3] White sheet: highlights, accommodation, timeline, essentials, buttons.
  Widget _buildWhiteSheet(
    BuildContext context,
    AppLocalizations l10n,
    TripSummary s,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ColorName.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: AppSpacing.horizontalSpace16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _sheetSectionLabel(l10n.summarySectionCurated),
            const SizedBox(height: 4),
            Text(
              l10n.summaryTripHighlights,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s.highlights.map((h) => _highlightChip(h)).toList(),
            ),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionWhereStay),
            const SizedBox(height: 4),
            Text(
              l10n.summaryAccommodation,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildAccommodationCard(context, l10n, s.accommodation),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionFlight),
            const SizedBox(height: 4),
            Text(
              l10n.summaryFlight,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildFlightCard(context, l10n),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionYourJourney),
            const SizedBox(height: 4),
            Text(
              l10n.summaryDayByDay,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            _buildDayByDayTimeline(context, l10n, s.dayByDayProgram),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionEssentials),
            const SizedBox(height: 4),
            Text(
              l10n.summaryWhatToBring,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildEssentialsList(context, l10n, s.essentialItems),
            const SizedBox(height: AppSpacing.space32),
            _buildSaveButton(context, l10n),
            const SizedBox(height: AppSpacing.space8),
            _buildRegenerateButton(context, l10n),
            const SizedBox(height: AppSpacing.space48),
          ],
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: FontFamily.b612,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ColorName.textMutedLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _highlightChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorName.surfaceLight,
        borderRadius: AppRadius.medium8,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '◆ ',
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              color: ColorName.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 13,
              color: ColorName.primaryTrueDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccommodationCard(
    BuildContext context,
    AppLocalizations l10n,
    String accommodationName,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: ColorName.primarySoftLight.withValues(alpha: 0.5),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(2)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ColorName.primary, ColorName.secondary],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: ColorName.primaryLight,
              borderRadius: AppRadius.medium8,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.home_rounded, color: ColorName.primary),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        accommodationName,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primaryTrueDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorName.success.withValues(alpha: 0.2),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        l10n.summaryBestPick,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ColorName.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  _mockAccommodationSubtitle,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: ColorName.textMutedLight,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < 4 ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 18,
                      color: i < 4 ? ColorName.warning : ColorName.hint,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: ColorName.primarySoftLight.withValues(alpha: 0.5),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(2)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ColorName.primary, ColorName.secondary],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: ColorName.primaryLight,
              borderRadius: AppRadius.medium8,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.flight_rounded, color: ColorName.primary),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.summaryFlightRouteMock,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primaryTrueDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.summaryFlightDetailsMock,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: ColorName.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayByDayTimeline(
    BuildContext context,
    AppLocalizations l10n,
    List<String> dayByDayProgram,
  ) {
    final count = dayByDayProgram.length;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space8),
      child: Column(
        children: List.generate(count, (i) {
          final isLast = i == count - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: ColorName.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${l10n.summaryDayPrefix}${i + 1}',
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: ColorName.primarySoftLight,
                        ),
                      )
                    else
                      const SizedBox(height: 24),
                  ],
                ),
                const SizedBox(width: AppSpacing.space16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDayDate(l10n, i),
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ColorName.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayByDayProgram[i],
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorName.primaryTrueDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDayDescription(l10n, i),
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 13,
                            color: ColorName.textMutedLight,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: ColorName.surfaceVariant,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(i),
                                size: 14,
                                color: ColorName.textMutedLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getCategoryLabel(l10n, i),
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 12,
                                  color: ColorName.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEssentialsList(
    BuildContext context,
    AppLocalizations l10n,
    List<String> essentialItems,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large16,
        child: Column(
          children: List.generate(essentialItems.length, (i) {
            final checked = _essentialChecked.contains(i);
            return InkWell(
              onTap: () {
                setState(() {
                  if (checked) {
                    _essentialChecked.remove(i);
                  } else {
                    _essentialChecked.add(i);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border:
                      i < essentialItems.length - 1
                          ? const Border(
                            bottom: BorderSide(
                              color: ColorName.primarySoftLight,
                            ),
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checked ? ColorName.success : Colors.transparent,
                        border: Border.all(
                          color: checked ? ColorName.success : ColorName.border,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child:
                          checked
                              ? const Icon(
                                Icons.check,
                                size: 16,
                                color: ColorName.surface,
                              )
                              : null,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Text(
                        essentialItems[i],
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 14,
                          color: ColorName.primaryTrueDark,
                        ),
                      ),
                    ),
                    Icon(
                      _getEssentialIcon(i),
                      size: 20,
                      color: ColorName.textMutedLight,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.summaryTripSaved)));
            context.go('/planifier');
          },
          borderRadius: AppRadius.large16,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorName.primary, ColorName.secondary],
              ),
              borderRadius: AppRadius.large16,
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.summarySaveTrip,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorName.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          context.read<CreateTripAiBloc>().add(CreateTripAiRegenerate());
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: ColorName.primarySoftLight),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
        ),
        child: Text(
          l10n.summaryRegenerate,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorName.primaryTrueDark,
          ),
        ),
      ),
    );
  }
}

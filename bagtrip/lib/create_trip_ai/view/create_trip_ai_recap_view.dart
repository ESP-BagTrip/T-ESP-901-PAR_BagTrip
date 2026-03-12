import 'package:bagtrip/components/custom_calendar_picker.dart';
import 'package:bagtrip/components/summary_date_card.dart';
import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search/widgets/section_card.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const Color _kRecapTravelTypesTint = Color(0xFFE8F5E9);
const Color _kRecapStyleTint = Color(0xFFE3F2FD);
const Color _kRecapBudgetTint = Color(0xFFFFF3E0);
const Color _kRecapCompanionsTint = Color(0xFFF3E5F5);

class CreateTripAiRecapView extends StatelessWidget {
  const CreateTripAiRecapView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
      builder: (context, state) {
        if (state is CreateTripAiRecapLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is! CreateTripAiRecapLoaded) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return _buildLoaded(context, state);
      },
    );
  }

  Widget _buildLoaded(BuildContext context, CreateTripAiRecapLoaded s) {
    final l10n = AppLocalizations.of(context)!;
    final canLaunch = s.departureDate != null && s.returnDate != null;

    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        backgroundColor: PersonalizationColors.gradientStart,
        foregroundColor: PersonalizationColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/planifier');
            }
          },
        ),
        title: const SizedBox.shrink(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildHeader(context, l10n),
              const SizedBox(height: 24),
              _buildPreferencesSection(context, l10n, s),
              const SizedBox(height: 24),
              _buildDatesSection(context, l10n, s),
              const SizedBox(height: 32),
              _buildLaunchButton(context, l10n, canLaunch),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.diamond, size: 14, color: ColorName.secondary),
            const SizedBox(width: 6),
            Text(
              l10n.recapFinalStepLabel,
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
        const SizedBox(height: 8),
        Text(
          l10n.recapTitle,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ColorName.primaryTrueDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    AppLocalizations l10n,
    CreateTripAiRecapLoaded s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.preferencesTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            TextButton.icon(
              onPressed:
                  () => context.push('/personalization?from=createTripAi'),
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: ColorName.hint,
              ),
              label: Text(
                l10n.modifyButton,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  color: ColorName.hint,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: ColorName.hint,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _preferenceRow(
                  context,
                  iconBg: _kRecapTravelTypesTint,
                  iconData: Icons.terrain,
                  label: l10n.recapTravelTypesLabel,
                  child: _buildTravelTypesChips(s.travelTypes),
                ),
              ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _preferenceRow(
                  context,
                  iconBg: _kRecapStyleTint,
                  iconData: Icons.schedule,
                  label: l10n.recapStyleLabel,
                  value: s.travelStyle,
                ),
              ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _preferenceRow(
                  context,
                  iconBg: _kRecapBudgetTint,
                  iconData: Icons.euro,
                  label: l10n.recapBudgetLabel,
                  value: s.budget,
                ),
              ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _preferenceRow(
                  context,
                  iconBg: _kRecapCompanionsTint,
                  iconData: Icons.people_outline,
                  label: l10n.recapCompanionsLabel,
                  value: s.companions,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preferenceRow(
    BuildContext context, {
    required Color iconBg,
    required IconData iconData,
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(iconData, size: 20, color: ColorName.primaryTrueDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ColorName.hint,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              if (child != null)
                child
              else
                Text(
                  value ?? '—',
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelTypesChips(String travelTypes) {
    final list =
        travelTypes
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    if (list.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 14,
          color: ColorName.primaryTrueDark,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          list
              .map(
                (label) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _kRecapTravelTypesTint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _kRecapTravelTypesTint),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildDatesSection(
    BuildContext context,
    AppLocalizations l10n,
    CreateTripAiRecapLoaded s,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.travelDatesLabel,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ColorName.primaryTrueDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryDateCard(
                label: l10n.departLabel.toUpperCase(),
                date: s.departureDate,
                onTap:
                    () => _pickDate(
                      context,
                      s.departureDate ?? DateTime.now(),
                      s.returnDate,
                      true,
                      (start, end) {
                        context.read<CreateTripAiBloc>().add(
                          CreateTripAiSetDepartureDate(start),
                        );
                        if (end != null) {
                          context.read<CreateTripAiBloc>().add(
                            CreateTripAiSetReturnDate(end),
                          );
                        }
                      },
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryDateCard(
                label: l10n.returnLabel.toUpperCase(),
                date: s.returnDate,
                onTap:
                    () => _pickDate(
                      context,
                      s.departureDate ?? DateTime.now(),
                      s.returnDate,
                      true,
                      (start, end) {
                        if (end != null) {
                          context.read<CreateTripAiBloc>().add(
                            CreateTripAiSetReturnDate(end),
                          );
                        }
                        context.read<CreateTripAiBloc>().add(
                          CreateTripAiSetDepartureDate(start),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLaunchButton(
    BuildContext context,
    AppLocalizations l10n,
    bool canLaunch,
  ) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            canLaunch
                ? () {
                  context.read<CreateTripAiBloc>().add(
                    CreateTripAiLaunchSearch(),
                  );
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorName.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          l10n.recapLaunchSearchButton,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime initialStart,
    DateTime? initialEnd,
    bool range,
    void Function(DateTime start, DateTime? end) onPicked,
  ) async {
    final result = await showCustomCalendarPicker(
      context: context,
      initialDate: initialStart,
      initialEndDate: initialEnd,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      isRangeSelection: range,
    );
    if (result != null && context.mounted) {
      onPicked(result.startDate, result.endDate);
    }
  }
}

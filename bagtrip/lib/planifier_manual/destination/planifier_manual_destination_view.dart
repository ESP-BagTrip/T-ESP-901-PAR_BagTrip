import 'package:bagtrip/components/custom_calendar_picker.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// First step of manual trip planning: destination, dates, number of travelers.
/// Minimalist design aligned with flight search; navigates to flight-search on Next.
class PlanifierManualDestinationView extends StatefulWidget {
  const PlanifierManualDestinationView({super.key});

  @override
  State<PlanifierManualDestinationView> createState() =>
      _PlanifierManualDestinationViewState();
}

class _PlanifierManualDestinationViewState
    extends State<PlanifierManualDestinationView> {
  final _destinationController = TextEditingController();
  DateTime? _departureDate;
  DateTime? _returnDate;
  int _travelersCount = 2;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDepartureDate() async {
    final picked = await showCustomCalendarPicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() => _departureDate = picked.startDate);
    }
  }

  Future<void> _pickReturnDate() async {
    final picked = await showCustomCalendarPicker(
      context: context,
      initialDate: _returnDate ?? _departureDate ?? DateTime.now(),
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() => _returnDate = picked.startDate);
    }
  }

  void _onNext() {
    context.push('/trips/planifier/manual/transport');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const sectionSpacing = 24.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _DestinationField(
          controller: _destinationController,
          label: l10n.destinationLabel,
          placeholder: l10n.destinationPlaceholder,
        ),
        const SizedBox(height: sectionSpacing),
        Row(
          children: [
            Expanded(
              child: _DateInputCard(
                label: l10n.departLabel,
                date: _departureDate,
                dateFormatHint: l10n.dateFormatHint,
                onTap: _pickDepartureDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateInputCard(
                label: l10n.returnLabel,
                date: _returnDate,
                dateFormatHint: l10n.dateFormatHint,
                onTap: _pickReturnDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: sectionSpacing),
        _TravelersSection(
          label: l10n.numberOfTravelersLabel,
          selectedCount: _travelersCount,
          onSelect: (count) => setState(() => _travelersCount = count),
          travelerCount5Plus: l10n.travelerCount5Plus,
        ),
        const SizedBox(height: 32),
        _NextButton(onPressed: _onNext),
      ],
    );
  }
}

class _DestinationField extends StatelessWidget {
  const _DestinationField({
    required this.controller,
    required this.label,
    required this.placeholder,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 18,
              color: ColorName.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
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
        Container(
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorName.primarySoftLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ColorName.primaryTrueDark,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: FontFamily.b612,
                color: ColorName.hint,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateInputCard extends StatelessWidget {
  const _DateInputCard({
    required this.label,
    required this.date,
    required this.dateFormatHint,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final String dateFormatHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayText =
        date != null ? DateFormat('dd/MM/yyyy').format(date!) : dateFormatHint;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorName.surfaceLight,
            borderRadius: AppRadius.large16,
            border: Border.all(
              color: ColorName.primarySoftLight.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: ColorName.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ColorName.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            date != null
                                ? ColorName.primaryTrueDark
                                : ColorName.hint,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: ColorName.hint.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelersSection extends StatelessWidget {
  const _TravelersSection({
    required this.label,
    required this.selectedCount,
    required this.onSelect,
    required this.travelerCount5Plus,
  });

  final String label;
  final int selectedCount;
  final ValueChanged<int> onSelect;
  final String travelerCount5Plus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 18,
              color: ColorName.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
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
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 1; i <= 4; i++) ...[
              if (i > 1) const SizedBox(width: 8),
              Expanded(
                child: _TravelerChip(
                  label: '$i',
                  selected: selectedCount == i,
                  onTap: () => onSelect(i),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: _TravelerChip(
                label: travelerCount5Plus,
                selected: selectedCount >= 5,
                onTap: () => onSelect(5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TravelerChip extends StatelessWidget {
  const _TravelerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? ColorName.primary : ColorName.surfaceLight,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color:
                  selected
                      ? ColorName.primary
                      : ColorName.primarySoftLight.withValues(alpha: 0.6),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? ColorName.surface : ColorName.primaryTrueDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 56,
      width: double.infinity,
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
              l10n.nextButton,
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

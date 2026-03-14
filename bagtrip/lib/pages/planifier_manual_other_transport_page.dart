import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Other transport form: type (car/train/bus/flight booked), details, budget.
/// Shown when user selects "Non, autre transport" on Transport page. UI only.
class PlanifierManualOtherTransportPage extends StatefulWidget {
  const PlanifierManualOtherTransportPage({super.key});

  @override
  State<PlanifierManualOtherTransportPage> createState() =>
      _PlanifierManualOtherTransportPageState();
}

class _PlanifierManualOtherTransportPageState
    extends State<PlanifierManualOtherTransportPage> {
  int _selectedTypeIndex = 0;
  final _detailsController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const sectionSpacing = 24.0;

    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.otherTransportTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: PersonalizationColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: PersonalizationColors.gradientStart,
        foregroundColor: PersonalizationColors.textPrimary,
      ),
      body: SafeArea(
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text(
              l10n.transportTypeLabel,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorName.secondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TransportTypeCard(
                    icon: Icons.directions_car_rounded,
                    label: l10n.transportTypeCar,
                    selected: _selectedTypeIndex == 0,
                    onTap: () => setState(() => _selectedTypeIndex = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TransportTypeCard(
                    icon: Icons.train_rounded,
                    label: l10n.transportTypeTrain,
                    selected: _selectedTypeIndex == 1,
                    onTap: () => setState(() => _selectedTypeIndex = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TransportTypeCard(
                    icon: Icons.directions_bus_rounded,
                    label: l10n.transportTypeBus,
                    selected: _selectedTypeIndex == 2,
                    onTap: () => setState(() => _selectedTypeIndex = 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TransportTypeCard(
                    icon: Icons.flight_rounded,
                    label: l10n.transportTypeFlightBooked,
                    selected: _selectedTypeIndex == 3,
                    onTap: () => setState(() => _selectedTypeIndex = 3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: sectionSpacing),
            _LabeledTextField(
              label: l10n.transportDetailsLabel,
              controller: _detailsController,
              placeholder: l10n.transportDetailsPlaceholder,
            ),
            const SizedBox(height: sectionSpacing),
            _BudgetField(
              label: l10n.transportBudgetLabel,
              controller: _budgetController,
              placeholder: l10n.transportBudgetPlaceholder,
              hint: l10n.transportBudgetHint,
            ),
            const SizedBox(height: 32),
            _ContinueButton(
              onPressed: () {
                final types = ['car', 'train', 'bus', 'flight_booked'];
                final result = {
                  'type': types[_selectedTypeIndex],
                  'details': _detailsController.text.trim(),
                  'budget': _budgetController.text.trim(),
                };
                context.pop(result);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  l10n.skipThisStepLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorName.primaryTrueDark,
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

class _TransportTypeCard extends StatelessWidget {
  const _TransportTypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? ColorName.primary : ColorName.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? ColorName.primary
                      : ColorName.primarySoftLight.withValues(alpha: 0.6),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? ColorName.surface : ColorName.primaryTrueDark,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? ColorName.surface : ColorName.primaryTrueDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.placeholder,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class _BudgetField extends StatelessWidget {
  const _BudgetField({
    required this.label,
    required this.controller,
    required this.placeholder,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
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
            keyboardType: TextInputType.number,
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
        const SizedBox(height: 8),
        Text(
          hint,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 12,
            color: ColorName.hint,
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.continueButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w600,
                    color: ColorName.surface,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ColorName.surface,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

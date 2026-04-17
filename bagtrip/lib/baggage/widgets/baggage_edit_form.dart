import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Map<String, String> _categoryLabels(AppLocalizations l10n) => {
  'DOCUMENTS': l10n.baggageCategoryDocuments,
  'CLOTHING': l10n.baggageCategoryClothing,
  'ELECTRONICS': l10n.baggageCategoryElectronics,
  'TOILETRIES': l10n.baggageCategoryHygiene,
  'HEALTH': l10n.baggageCategoryMedication,
  'ACCESSORIES': l10n.baggageCategoryAccessories,
  'OTHER': l10n.baggageCategoryOther,
};

class BaggageEditForm extends StatefulWidget {
  final String tripId;
  final BaggageItem item;

  /// Optional submission hook. When provided, the form calls it with the
  /// `{name, quantity, category}` payload and the caller is responsible
  /// for dispatching (e.g. to `TripDetailBloc` from a panel). When `null`,
  /// falls back to the legacy behaviour: dispatches [UpdateBaggageItem] on
  /// the ambient [BaggageBloc].
  final void Function(Map<String, dynamic> data)? onSubmit;

  const BaggageEditForm({
    super.key,
    required this.tripId,
    required this.item,
    this.onSubmit,
  });

  @override
  State<BaggageEditForm> createState() => _BaggageEditFormState();
}

class _BaggageEditFormState extends State<BaggageEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _quantity;
  late String _category;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantity = widget.item.quantity ?? 1;
    _category = widget.item.category ?? 'OTHER';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'quantity': _quantity,
      'category': _category,
    };
    if (widget.onSubmit != null) {
      widget.onSubmit!(data);
    } else {
      context.read<BaggageBloc>().add(
        UpdateBaggageItem(
          tripId: widget.tripId,
          itemId: widget.item.id,
          name: data['name'] as String,
          quantity: data['quantity'] as int,
          category: data['category'] as String,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = _categoryLabels(l10n);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cornerRadius20),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.space16,
        right: AppSpacing.space16,
        top: AppSpacing.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                l10n.baggageEditItemTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.baggageItemName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.luggage_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Quantity stepper
              Row(
                children: [
                  Text(
                    l10n.baggageQuantityLabel,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppRadius.medium8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          tooltip: l10n.decreaseQuantityTooltip,
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          visualDensity: VisualDensity.compact,
                        ),
                        Padding(
                          padding: AppSpacing.horizontalSpace8,
                          child: Text(
                            '$_quantity',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          tooltip: l10n.increaseQuantityTooltip,
                          onPressed: () => setState(() => _quantity++),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),

              // Category chips
              Text(
                l10n.baggageCategoryLabel,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.space8),
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: categories.entries.map((entry) {
                  final isSelected = _category == entry.key;
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.light();
                      setState(() => _category = entry.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primarySoftLight
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space24),

              // Save button
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: AppSpacing.verticalSpace16,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.large16,
                  ),
                ),
                child: Text(
                  l10n.saveButton,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }
}

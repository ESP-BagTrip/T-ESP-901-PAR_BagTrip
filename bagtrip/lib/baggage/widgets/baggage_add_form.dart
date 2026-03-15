import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BaggageAddForm extends StatefulWidget {
  final String tripId;

  const BaggageAddForm({super.key, required this.tripId});

  @override
  State<BaggageAddForm> createState() => _BaggageAddFormState();
}

class _BaggageAddFormState extends State<BaggageAddForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int _quantity = 1;
  String _category = 'Autre';

  static const _categories = [
    'Vetements',
    'Electronique',
    'Toilette',
    'Documents',
    'Sante',
    'Accessoires',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<BaggageBloc>().add(
      CreateBaggageItem(
        tripId: widget.tripId,
        name: _nameController.text.trim(),
        quantity: _quantity,
        category: _category,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                l10n.baggageAddItemTitle,
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
                          onPressed: () => setState(() => _quantity++),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.baggageCategoryLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Autre'),
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

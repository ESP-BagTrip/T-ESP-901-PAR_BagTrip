import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/widgets/baggage_item_form_content.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BaggageEditForm extends StatefulWidget {
  final String tripId;
  final BaggageItem item;
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

    return Form(
      key: _formKey,
      child: ItemFormScaffold(
        title: l10n.baggageEditItemTitle,
        fields: BaggageItemFormContent(
          nameController: _nameController,
          quantity: _quantity,
          category: _category,
          onQuantityChanged: (q) => setState(() => _quantity = q),
          onCategoryChanged: (c) => setState(() => _category = c),
          nameValidator: (v) =>
              (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
        ),
        actions: [
          ItemFormPrimaryButton(label: l10n.saveButton, onPressed: _submit),
        ],
      ),
    );
  }
}

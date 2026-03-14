import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/baggage_ai_service.dart';
import 'package:bagtrip/service/baggage_item_service.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';

class BaggagePage extends StatefulWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const BaggagePage({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  State<BaggagePage> createState() => _BaggagePageState();
}

class _BaggagePageState extends State<BaggagePage> {
  final _baggageItemService = BaggageItemService();
  final _baggageAiService = BaggageAiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  List<BaggageItem> _baggageItems = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  bool _isAdding = false;
  bool _isSuggestLoading = false;
  String? _errorMessage;
  String? _selectedCategory;

  static const _categories = [
    'Documents',
    'Vêtements',
    'Electronique',
    'Hygiène',
    'Médicaments',
    'Accessoires',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadBaggageItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadBaggageItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _baggageItemService.getByTrip(widget.tripId);
      setState(() {
        _baggageItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTogglePacked(BaggageItem item) async {
    try {
      await _baggageItemService.updateBaggageItem(widget.tripId, item.id, {
        'isPacked': !item.isPacked,
      });
      await _loadBaggageItems();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: toUserFriendlyMessage(e));
      }
    }
  }

  Future<void> _handleAddBaggageItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      final quantityText = _quantityController.text.trim();
      await _baggageItemService.createBaggageItem(
        widget.tripId,
        name: _nameController.text.trim(),
        quantity: quantityText.isNotEmpty ? int.tryParse(quantityText) ?? 1 : 1,
        category: _selectedCategory,
      );

      _nameController.clear();
      _quantityController.text = '1';
      _selectedCategory = null;

      await _loadBaggageItems();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Élément ajouté')));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _handleDeleteBaggageItem(String baggageItemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'élément'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ColorName.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _baggageItemService.deleteBaggageItem(
          widget.tripId,
          baggageItemId,
        );
        await _loadBaggageItems();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Élément supprimé')));
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, message: toUserFriendlyMessage(e));
        }
      }
    }
  }

  Future<void> _handleSuggestBaggage() async {
    final authService = getIt<AuthService>();
    final user = await authService.getCurrentUser();
    if (user != null &&
        user.isFree &&
        user.aiGenerationsRemaining != null &&
        user.aiGenerationsRemaining! <= 0) {
      if (mounted) {
        PremiumPaywall.show(context);
      }
      return;
    }

    setState(() {
      _isSuggestLoading = true;
    });
    try {
      final suggestions = await _baggageAiService.suggestBaggage(widget.tripId);
      setState(() {
        _suggestions = suggestions;
        _isSuggestLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSuggestLoading = false;
      });
      if (mounted) {
        AppSnackBar.showError(context, message: toUserFriendlyMessage(e));
      }
    }
  }

  Future<void> _handleAddSuggestion(Map<String, dynamic> suggestion) async {
    try {
      await _baggageItemService.createBaggageItem(
        widget.tripId,
        name: suggestion['name'] ?? '',
        quantity: suggestion['quantity'] ?? 1,
        category: suggestion['category'],
      );
      setState(() {
        _suggestions.remove(suggestion);
      });
      await _loadBaggageItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Élément ajouté depuis suggestion')),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: toUserFriendlyMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final packedCount = _baggageItems.where((item) => item.isPacked).length;
    final isViewer = widget.role == 'VIEWER';
    final isReadOnly = isViewer || widget.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bagages'),
        actions: [
          if (!isReadOnly)
            IconButton(
              icon: _isSuggestLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              tooltip: 'Suggestions IA',
              onPressed: _isSuggestLoading ? null : _handleSuggestBaggage,
            ),
          if (_baggageItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$packedCount/${_baggageItems.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _baggageItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.luggage_outlined,
                                  size: 64,
                                  color: AppColors.hint,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun élément',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: AppColors.hint),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajoutez des éléments à votre liste de bagages',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMutedLight,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _baggageItems.length,
                            itemBuilder: (context, index) {
                              final item = _baggageItems[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: item.isPacked,
                                    onChanged: isReadOnly
                                        ? null
                                        : (_) => _handleTogglePacked(item),
                                  ),
                                  title: Text(
                                    item.name,
                                    style: TextStyle(
                                      decoration: item.isPacked
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: item.isPacked
                                          ? AppColors.hint
                                          : null,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (item.category != null)
                                        Chip(
                                          label: Text(
                                            item.category!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (item.quantity != null &&
                                          item.quantity! > 1) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          'x${item.quantity}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: isReadOnly
                                      ? null
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _handleDeleteBaggageItem(item.id),
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_suggestions.isNotEmpty && !isReadOnly)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F7FF),
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Suggestions IA',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    setState(() => _suggestions = []),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final s = _suggestions[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(s['name'] ?? ''),
                                  subtitle: Text(
                                    '${s['category'] ?? 'Autre'} · x${s['quantity'] ?? 1}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                    onPressed: () => _handleAddSuggestion(s),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isReadOnly)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ajouter un élément',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom *',
                                      border: OutlineInputBorder(),
                                      hintText: 'ex: Passeport',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Requis';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantityController,
                                    decoration: const InputDecoration(
                                      labelText: 'Qté',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Catégorie (optionnel)',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: ColorName.errorDark,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isAdding
                                  ? null
                                  : _handleAddBaggageItem,
                              icon: _isAdding
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: const Text('Ajouter'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

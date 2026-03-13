import 'package:flutter/material.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/baggage_ai_service.dart';

class BaggageItemService {
  final ApiClient _apiClient;

  BaggageItemService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> getBaggageItems(String tripId) async {
    final response = await _apiClient.get('/trips/$tripId/baggage');
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      if (data is List) {
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    }
    return [];
  }

  Future<void> createBaggageItem(
    String tripId, {
    required String name,
    int quantity = 1,
    String? category,
    bool packed = false,
  }) async {
    await _apiClient.post('/trips/$tripId/baggage', data: {
      'name': name,
      'quantity': quantity,
      'category': category ?? 'Autre',
      'packed': packed,
    });
  }

  Future<void> updateBaggageItem(
    String tripId,
    String itemId, {
    String? name,
    int? quantity,
    String? category,
    bool? packed,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (quantity != null) data['quantity'] = quantity;
    if (category != null) data['category'] = category;
    if (packed != null) data['packed'] = packed;
    await _apiClient.patch('/trips/$tripId/baggage/$itemId', data: data);
  }

  Future<void> deleteBaggageItem(String tripId, String itemId) async {
    await _apiClient.delete('/trips/$tripId/baggage/$itemId');
  }
}

class BaggagePage extends StatefulWidget {
  final String tripId;
  final bool isReadOnly;

  const BaggagePage({super.key, required this.tripId, this.isReadOnly = false});

  @override
  State<BaggagePage> createState() => _BaggagePageState();
}

class _BaggagePageState extends State<BaggagePage> {
  final _baggageItemService = BaggageItemService();
  final _baggageAiService = BaggageAiService();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  bool _isSuggestLoading = false;
  String _selectedCategory = 'Autre';

  final List<String> _categories = [
    'Documents',
    'Vêtements',
    'Electronique',
    'Hygiène',
    'Médicaments',
    'Accessoires',
    'Autre',
  ];

  bool get isReadOnly => widget.isReadOnly;

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
    try {
      final items = await _baggageItemService.getBaggageItems(widget.tripId);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleAddItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    try {
      await _baggageItemService.createBaggageItem(
        widget.tripId,
        name: name,
        quantity: quantity,
        category: _selectedCategory,
      );
      _nameController.clear();
      _quantityController.text = '1';
      _selectedCategory = 'Autre';
      await _loadBaggageItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleTogglePacked(Map<String, dynamic> item) async {
    try {
      await _baggageItemService.updateBaggageItem(
        widget.tripId,
        item['id'].toString(),
        packed: !(item['packed'] == true),
      );
      await _loadBaggageItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleDeleteItem(Map<String, dynamic> item) async {
    try {
      await _baggageItemService.deleteBaggageItem(
        widget.tripId,
        item['id'].toString(),
      );
      await _loadBaggageItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleSuggestBaggage() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  int get _packedCount => _items.where((i) => i['packed'] == true).length;

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_packedCount/${_items.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun élément de bagage',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final isPacked = item['packed'] == true;
                            return ListTile(
                              leading: Checkbox(
                                value: isPacked,
                                onChanged: isReadOnly
                                    ? null
                                    : (_) => _handleTogglePacked(item),
                              ),
                              title: Text(
                                item['name'] ?? '',
                                style: TextStyle(
                                  decoration: isPacked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                '${item['category'] ?? 'Autre'} · x${item['quantity'] ?? 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: isReadOnly
                                  ? null
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _handleDeleteItem(item),
                                    ),
                            );
                          },
                        ),
                ),
                if (_suggestions.isNotEmpty && !isReadOnly)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green, size: 24),
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: const Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Ajouter un élément...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (_) => _handleAddItem(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedCategory,
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c, style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: _handleAddItem,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

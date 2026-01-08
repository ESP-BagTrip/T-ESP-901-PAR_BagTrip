import 'package:flutter/material.dart';
import 'package:bagtrip/chat/models/context.dart';

class WarningWidget extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const WarningWidget({super.key, required this.widgetData, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange[300]!),
        ),
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec icône warning
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[800],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widgetData.title ?? 'Avertissement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Message
              if (widgetData.subtitle != null)
                Text(
                  widgetData.subtitle!,
                  style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                ),

              // Informations supplémentaires
              if (widgetData.data != null && widgetData.data!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildWarningDetails(widgetData.data!),
              ],

              // Actions
              if (widgetData.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widgetData.actions.map((action) {
                        return OutlinedButton(
                          onPressed: () {
                            onAction?.call(action.type, widgetData.offerId);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            side: BorderSide(color: Colors.orange[800]!),
                            foregroundColor: Colors.orange[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(action.label),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningDetails(Map<String, dynamic> data) {
    final List<Widget> items = [];

    if (data['type'] != null) {
      items.add(_buildDetailRow('Type', data['type'] as String));
    }

    if (data['message'] != null) {
      items.add(_buildDetailRow('Message', data['message'] as String));
    }

    if (data['action_required'] != null) {
      items.add(
        _buildDetailRow(
          'Action requise',
          data['action_required'] as String,
          isImportant: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isImportant = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[800],
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

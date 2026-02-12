import 'package:bagtrip/chat/models/context.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

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
          side: const BorderSide(color: ColorName.warningLight),
        ),
        color: ColorName.warningLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorName.warningLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: ColorName.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widgetData.title ?? 'Avertissement',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorName.warning,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColorName.warning,
                  ),
                ),

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
                            side: const BorderSide(color: ColorName.warning),
                            foregroundColor: ColorName.warning,
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
            style: const TextStyle(
              fontSize: 12,
              color: ColorName.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: ColorName.warning,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

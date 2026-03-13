import 'package:flutter/material.dart';

class PostTripSuggestionView extends StatelessWidget {
  final Map<String, dynamic> suggestion;

  const PostTripSuggestionView({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final destination = suggestion['destination'] ?? '';
    final country = suggestion['destinationCountry'] ?? '';
    final duration = suggestion['durationDays'] ?? 0;
    final budget = suggestion['budgetEur'] ?? 0;
    final description = suggestion['description'] ?? '';
    final highlights =
        (suggestion['highlightsMatch'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final activities = (suggestion['activities'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Prochain voyage suggere')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$destination, $country',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text('$duration jours')),
                const SizedBox(width: 8),
                Chip(label: Text('$budget\u20ac')),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Base sur vos preferences',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    highlights
                        .map(
                          (h) => Chip(
                            avatar: const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            label: Text(
                              h,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
            if (activities.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Activites proposees',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...activities.map((a) {
                final activity = a is Map ? a : {};
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(activity['title'] ?? ''),
                    subtitle: Text(activity['description'] ?? ''),
                    trailing:
                        activity['estimatedCost'] != null
                            ? Text('~${activity['estimatedCost']}\u20ac')
                            : null,
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to trip creation or back to trips
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.flight_takeoff),
                label: const Text('Creer ce voyage'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

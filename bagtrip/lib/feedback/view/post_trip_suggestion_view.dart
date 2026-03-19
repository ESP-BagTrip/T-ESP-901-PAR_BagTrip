import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.postTripSuggestionTitle),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.allEdgeInsetSpace16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$destination, $country',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                Chip(label: Text('$duration jours')),
                const SizedBox(width: AppSpacing.space8),
                Chip(label: Text('$budget\u20ac')),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space24),
              Text(
                AppLocalizations.of(context)!.postTripBasedOnPreferences,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.space8),
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: highlights
                    .map(
                      (h) => Chip(
                        avatar: const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.success,
                        ),
                        label: Text(h, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (activities.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space24),
              Text(
                AppLocalizations.of(context)!.postTripProposedActivities,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.space8),
              ...activities.map((a) {
                final activity = a is Map ? a : {};
                return Card(
                  margin: AppSpacing.onlyBottomSpace8,
                  child: ListTile(
                    title: Text(activity['title'] ?? ''),
                    subtitle: Text(activity['description'] ?? ''),
                    trailing: activity['estimatedCost'] != null
                        ? Text('~${activity['estimatedCost']}\u20ac')
                        : null,
                  ),
                );
              }),
            ],
            const SizedBox(height: AppSpacing.space24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to trip creation or back to trips
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.flight_takeoff),
                label: Text(AppLocalizations.of(context)!.postTripCreateTrip),
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

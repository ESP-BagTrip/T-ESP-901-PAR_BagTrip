import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/transports/widgets/manual_flight_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddFlightSheet extends StatelessWidget {
  final String tripId;

  const AddFlightSheet({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorName.hint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.addFlight,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorName.primaryTrueDark,
            ),
          ),
          const SizedBox(height: 24),

          // Option 1: Search flight (Amadeus)
          _OptionTile(
            icon: Icons.search_rounded,
            title: l10n.searchFlightOption,
            subtitle: l10n.searchFlightOptionSubtitle,
            onTap: () {
              Navigator.of(context).pop();
              const TripFlightSearchRoute().go(context);
            },
          ),
          const SizedBox(height: 12),

          // Option 2: Add manually
          _OptionTile(
            icon: Icons.edit_rounded,
            title: l10n.addManuallyOption,
            subtitle: l10n.addManuallyOptionSubtitle,
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<TransportBloc>(),
                  child: ManualFlightForm(tripId: tripId),
                ),
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.large16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: ColorName.primarySoftLight),
          borderRadius: AppRadius.large16,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.medium8,
              ),
              child: Icon(icon, color: ColorName.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: ColorName.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ColorName.hint),
          ],
        ),
      ),
    );
  }
}

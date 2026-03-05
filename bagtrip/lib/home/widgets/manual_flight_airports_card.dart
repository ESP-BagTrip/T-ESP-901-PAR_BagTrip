import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/home/models/airport_type.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Manual flight form airports card: departure/destination with dots, pills, swap.
class ManualFlightAirportsCard extends StatelessWidget {
  const ManualFlightAirportsCard({super.key, required this.state});

  final HomeFlightLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space24),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large24,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AirportRow(
            dotColor: ColorName.secondary,
            label: l10n.departureLabel.toUpperCase(),
            airport: state.departureAirport,
            onTap:
                () => _openAirportPicker(
                  context,
                  type: AirportType.departure,
                  onSelect:
                      (a) => context.read<HomeFlightBloc>().add(
                        SelectDepartureAirport(a),
                      ),
                ),
          ),
          const SizedBox(height: 16),
          _SeparatorWithSwap(
            onSwap: () {
              HapticFeedback.lightImpact();
              context.read<HomeFlightBloc>().add(SwapAirports());
            },
          ),
          const SizedBox(height: 16),
          _AirportRow(
            dotColor: ColorName.hint,
            label: l10n.destinationLabel.toUpperCase(),
            airport: state.arrivalAirport,
            onTap:
                () => _openAirportPicker(
                  context,
                  type: AirportType.arrival,
                  onSelect:
                      (a) => context.read<HomeFlightBloc>().add(
                        SelectArrivalAirport(a),
                      ),
                ),
          ),
        ],
      ),
    );
  }

  void _openAirportPicker(
    BuildContext context, {
    required AirportType type,
    required void Function(Map<String, dynamic>) onSelect,
  }) {
    final bloc = context.read<HomeFlightBloc>();
    final hint =
        type == AirportType.departure
            ? AppLocalizations.of(context)!.airportDepartureHint
            : AppLocalizations.of(context)!.airportArrivalHint;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => BlocProvider.value(
            value: bloc,
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder:
                  (_, scrollController) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ColorName.primarySoftLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextField(
                            autofocus: true,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 16,
                              color: ColorName.primaryTrueDark,
                            ),
                            decoration: InputDecoration(
                              hintText: hint,
                              hintStyle: const TextStyle(
                                fontFamily: FontFamily.b612,
                                color: AppColors.hint,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: ColorName.hint,
                                size: 22,
                              ),
                              filled: true,
                              fillColor: ColorName.primaryLight.withValues(
                                alpha: 0.5,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              if (value.length >= 2) {
                                bloc.add(
                                  type == AirportType.departure
                                      ? SearchDepartureAirport(value)
                                      : SearchArrivalAirport(value),
                                );
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: BlocBuilder<HomeFlightBloc, HomeFlightState>(
                            builder: (context, state) {
                              final results =
                                  state is HomeFlightLoaded
                                      ? state.searchResults
                                      : null;
                              if (results == null || results.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Type to search',
                                    style: TextStyle(
                                      fontFamily: FontFamily.b612,
                                      color: AppColors.hint,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: results.length,
                                separatorBuilder:
                                    (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final airport = results[index];
                                  return ListTile(
                                    title: Text(
                                      airport['name'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: FontFamily.b612,
                                        fontWeight: FontWeight.w600,
                                        color: ColorName.primaryTrueDark,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [airport['iataCode'], airport['city']]
                                          .where(
                                            (e) =>
                                                e != null &&
                                                e.toString().isNotEmpty,
                                          )
                                          .join(' · '),
                                      style: const TextStyle(
                                        fontFamily: FontFamily.b612,
                                        fontSize: 13,
                                        color: AppColors.hint,
                                      ),
                                    ),
                                    onTap: () {
                                      onSelect(airport);
                                      Navigator.of(sheetContext).pop();
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
    );
  }
}

class _AirportRow extends StatelessWidget {
  const _AirportRow({
    required this.dotColor,
    required this.label,
    required this.airport,
    required this.onTap,
  });

  final Color dotColor;
  final String label;
  final Map<String, dynamic>? airport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final city = airport?['city'] ?? airport?['name'] ?? '';
    final code = airport?['iataCode'] ?? '';
    final name = airport?['name'] ?? '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ColorName.hint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            city.isNotEmpty ? city : 'Select airport',
                            style: TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color:
                                  city.isNotEmpty
                                      ? ColorName.primaryTrueDark
                                      : AppColors.hint,
                            ),
                          ),
                        ),
                        if (code.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorName.primaryLight.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ColorName.primaryTrueDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (name.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                          color: AppColors.hint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeparatorWithSwap extends StatefulWidget {
  const _SeparatorWithSwap({required this.onSwap});

  final VoidCallback onSwap;

  @override
  State<_SeparatorWithSwap> createState() => _SeparatorWithSwapState();
}

class _SeparatorWithSwapState extends State<_SeparatorWithSwap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(ColorName.hint),
            const SizedBox(width: 8),
            _dot(ColorName.secondary),
            const SizedBox(width: 8),
            _dot(ColorName.hint),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: ColorName.primarySoftLight.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onSwap,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorName.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_vert_rounded,
                color: ColorName.primaryTrueDark,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

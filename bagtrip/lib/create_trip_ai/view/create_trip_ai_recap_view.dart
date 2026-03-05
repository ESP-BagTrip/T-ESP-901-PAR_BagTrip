import 'package:bagtrip/components/custom_calendar_picker.dart';
import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/flight_search/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CreateTripAiRecapView extends StatelessWidget {
  const CreateTripAiRecapView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
      builder: (context, state) {
        if (state is CreateTripAiRecapLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is! CreateTripAiRecapLoaded) {
          return const Scaffold(body: SizedBox.shrink());
        }
        return _buildLoaded(context, state);
      },
    );
  }

  Widget _buildLoaded(BuildContext context, CreateTripAiRecapLoaded s) {
    final canLaunch = s.departureDate != null && s.returnDate != null;

    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        title: const Text('Récapitulatif'),
        backgroundColor: PersonalizationColors.gradientStart,
        foregroundColor: PersonalizationColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Préférences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryTrueDark,
                  fontFamily: FontFamily.b612,
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Types de voyage', s.travelTypes),
                    if (s.travelStyle != null) _row('Style', s.travelStyle!),
                    if (s.budget != null) _row('Budget', s.budget!),
                    if (s.companions != null) _row('Compagnons', s.companions!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed:
                    () => context.push('/personalization?from=createTripAi'),
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: ColorName.primary,
                ),
                label: const Text('Modifier mes préférences'),
                style: TextButton.styleFrom(
                  foregroundColor: ColorName.primary,
                  textStyle: const TextStyle(fontFamily: FontFamily.b612),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dates du voyage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryTrueDark,
                  fontFamily: FontFamily.b612,
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _dateBlock(
                            context,
                            'Date de départ',
                            s.departureDate,
                            () => _pickDate(
                              context,
                              s.departureDate ?? DateTime.now(),
                              s.returnDate,
                              true,
                              (start, end) {
                                context.read<CreateTripAiBloc>().add(
                                  CreateTripAiSetDepartureDate(start),
                                );
                                if (end != null) {
                                  context.read<CreateTripAiBloc>().add(
                                    CreateTripAiSetReturnDate(end),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateBlock(
                            context,
                            'Date de retour',
                            s.returnDate,
                            () => _pickDate(
                              context,
                              s.departureDate ?? DateTime.now(),
                              s.returnDate,
                              true,
                              (start, end) {
                                if (end != null) {
                                  context.read<CreateTripAiBloc>().add(
                                    CreateTripAiSetReturnDate(end),
                                  );
                                }
                                context.read<CreateTripAiBloc>().add(
                                  CreateTripAiSetDepartureDate(start),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      canLaunch
                          ? () {
                            context.read<CreateTripAiBloc>().add(
                              CreateTripAiLaunchSearch(),
                            );
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorName.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Lancer la recherche IA'),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: ColorName.secondary,
                fontFamily: FontFamily.b612,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: ColorName.primaryTrueDark,
                fontFamily: FontFamily.b612,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBlock(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ColorName.secondary,
              fontWeight: FontWeight.w600,
              fontFamily: FontFamily.b612,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: AppSpacing.allEdgeInsetSpace16,
            decoration: BoxDecoration(
              color: ColorName.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              date != null ? dateFormat.format(date) : 'Choisir',
              style: TextStyle(
                fontSize: 14,
                color:
                    date != null ? ColorName.primaryTrueDark : AppColors.hint,
                fontFamily: FontFamily.b612,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime initialStart,
    DateTime? initialEnd,
    bool range,
    void Function(DateTime start, DateTime? end) onPicked,
  ) async {
    final result = await showCustomCalendarPicker(
      context: context,
      initialDate: initialStart,
      initialEndDate: initialEnd,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      isRangeSelection: range,
    );
    if (result != null && context.mounted) {
      onPicked(result.startDate, result.endDate);
    }
  }
}

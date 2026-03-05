import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/models/trip_summary.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateTripAiSummaryView extends StatelessWidget {
  const CreateTripAiSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
      builder: (context, state) {
        if (state is CreateTripAiSummaryLoaded) {
          return _buildSummary(context, state.summary);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildSummary(BuildContext context, TripSummary s) {
    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Retour'),
        backgroundColor: PersonalizationColors.gradientStart,
        foregroundColor: PersonalizationColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColorName.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Votre voyage sur mesure',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primaryTrueDark,
                        fontFamily: FontFamily.b612,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Généré par l\'IA',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorName.secondary,
                  fontFamily: FontFamily.b612,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: AppSpacing.allEdgeInsetSpace24,
                decoration: BoxDecoration(
                  color: ColorName.primarySoftLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.destination}, ${s.destinationCountry}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primaryTrueDark,
                        fontFamily: FontFamily.b612,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: ColorName.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${s.durationDays} jours',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ColorName.secondary,
                            fontFamily: FontFamily.b612,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.euro,
                          size: 18,
                          color: ColorName.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${s.budgetEur}€',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ColorName.secondary,
                            fontFamily: FontFamily.b612,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Points forts du voyage'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    s.highlights
                        .map((h) => _chip(h, Icons.auto_awesome, context))
                        .toList(),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Hébergement'),
              const SizedBox(height: 8),
              _chip(s.accommodation, Icons.hotel, context),
              const SizedBox(height: 24),
              _sectionTitle('Programme jour par jour'),
              const SizedBox(height: 8),
              ...List.generate(s.dayByDayProgram.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: ColorName.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFamily: FontFamily.b612,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.dayByDayProgram[i],
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
              }),
              const SizedBox(height: 24),
              _sectionTitle('Objets à emporter'),
              const SizedBox(height: 8),
              ...s.essentialItems.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: ColorName.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ColorName.primaryTrueDark,
                          fontFamily: FontFamily.b612,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorName.primary, ColorName.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voyage sauvegardé')),
                    );
                    context.go('/planifier');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Sauvegarder ce voyage'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<CreateTripAiBloc>().add(
                      CreateTripAiRegenerate(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ColorName.primarySoftLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Régénérer'),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ColorName.primaryTrueDark,
        fontFamily: FontFamily.b612,
      ),
    );
  }

  Widget _chip(String label, IconData icon, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorName.primarySoftLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorName.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: ColorName.primaryTrueDark,
              fontFamily: FontFamily.b612,
            ),
          ),
        ],
      ),
    );
  }
}

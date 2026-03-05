import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/models/ai_trip_proposal.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateTripAiResultsView extends StatelessWidget {
  const CreateTripAiResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
      builder: (context, state) {
        if (state is CreateTripAiResultsLoaded) {
          return _buildResults(context, state.proposals);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildResults(BuildContext context, List<AiTripProposal> proposals) {
    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        title: const Text('Résultats IA'),
        backgroundColor: PersonalizationColors.gradientStart,
        foregroundColor: PersonalizationColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: proposals.length,
          itemBuilder: (context, index) {
            final p = proposals[index];
            return _ProposalCard(
              proposal: p,
              onTap: () {
                context.read<CreateTripAiBloc>().add(
                  CreateTripAiSelectProposal(p),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal, required this.onTap});

  final AiTripProposal proposal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: AppSpacing.onlyBottomSpace16,
        padding: AppSpacing.allEdgeInsetSpace24,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          border: Border.all(color: ColorName.primarySoftLight),
          boxShadow: [
            BoxShadow(
              color: ColorName.primary.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 6,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: ColorName.primary.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: -1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${proposal.destination}, ${proposal.destinationCountry}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primary,
                    fontFamily: FontFamily.b612,
                  ),
                ),
                Text(
                  '${proposal.priceEur}€',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorName.secondary,
                    fontFamily: FontFamily.b612,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${proposal.durationDays} jours',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorName.secondary,
                    fontFamily: FontFamily.b612,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              proposal.description,
              style: const TextStyle(
                fontSize: 14,
                color: ColorName.primaryTrueDark,
                fontFamily: FontFamily.b612,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

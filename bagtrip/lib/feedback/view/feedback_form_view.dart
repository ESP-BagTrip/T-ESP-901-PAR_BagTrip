import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/feedback/bloc/feedback_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedbackFormView extends StatefulWidget {
  final String tripId;
  final String? currentUserId;
  final List<TripFeedback> feedbacks;
  final bool showAiRating;

  const FeedbackFormView({
    super.key,
    required this.tripId,
    this.currentUserId,
    this.feedbacks = const [],
    this.showAiRating = false,
  });

  @override
  State<FeedbackFormView> createState() => _FeedbackFormViewState();
}

class _FeedbackFormViewState extends State<FeedbackFormView> {
  int _rating = 3;
  final _highlightsController = TextEditingController();
  final _lowlightsController = TextEditingController();
  bool _wouldRecommend = true;
  int _aiRating = 3;

  @override
  void dispose() {
    _highlightsController.dispose();
    _lowlightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingFeedback = widget.currentUserId != null
        ? widget.feedbacks
              .where((f) => f.userId == widget.currentUserId)
              .firstOrNull
        : null;

    if (existingFeedback != null) {
      return _ReadOnlyFeedbackView(
        feedback: existingFeedback,
        tripId: widget.tripId,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.feedbackGiveYourReview),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.allEdgeInsetSpace16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.feedbackOverallRating,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.starRating,
                    size: 36,
                  ),
                  tooltip: AppLocalizations.of(
                    context,
                  )!.starRatingTooltip(index + 1, 5),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: AppSpacing.space16),
            TextField(
              controller: _highlightsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.feedbackHighlights,
                hintText: AppLocalizations.of(context)!.feedbackHighlightsHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.space16),
            TextField(
              controller: _lowlightsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.feedbackLowlights,
                hintText: AppLocalizations.of(context)!.feedbackLowlightsHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.space16),
            SwitchListTile.adaptive(
              title: Text(AppLocalizations.of(context)!.feedbackWouldRecommend),
              value: _wouldRecommend,
              onChanged: (value) {
                setState(() {
                  _wouldRecommend = value;
                });
              },
            ),
            if (widget.showAiRating) ...[
              const SizedBox(height: AppSpacing.space16),
              Text(
                AppLocalizations.of(context)!.feedbackAiRatingLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _aiRating ? Icons.star : Icons.star_border,
                      color: AppColors.starRating,
                      size: 36,
                    ),
                    tooltip: AppLocalizations.of(
                      context,
                    )!.starRatingTooltip(index + 1, 5),
                    onPressed: () {
                      setState(() {
                        _aiRating = index + 1;
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.space24),
            BlocConsumer<FeedbackBloc, FeedbackState>(
              listener: (context, state) {
                if (state is FeedbackSubmitted) {
                  AppSnackBar.showSuccess(
                    context,
                    message: AppLocalizations.of(context)!.feedbackThanks,
                  );
                } else if (state is FeedbackError) {
                  AppSnackBar.showError(
                    context,
                    message: toUserFriendlyMessage(
                      state.error,
                      AppLocalizations.of(context)!,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is FeedbackLoading) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                return ElevatedButton.icon(
                  onPressed: () {
                    context.read<FeedbackBloc>().add(
                      SubmitFeedback(
                        tripId: widget.tripId,
                        overallRating: _rating,
                        highlights: _highlightsController.text.isNotEmpty
                            ? _highlightsController.text
                            : null,
                        lowlights: _lowlightsController.text.isNotEmpty
                            ? _lowlightsController.text
                            : null,
                        wouldRecommend: _wouldRecommend,
                        aiExperienceRating: widget.showAiRating
                            ? _aiRating
                            : null,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: Text(
                    AppLocalizations.of(context)!.feedbackSubmitButton,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.space24),
            _PostTripSuggestionSection(
              tripId: widget.tripId,
              hasSubmitted: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyFeedbackView extends StatelessWidget {
  final TripFeedback feedback;
  final String tripId;

  const _ReadOnlyFeedbackView({required this.feedback, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.allEdgeInsetSpace16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFFF0F7FF),
            child: Padding(
              padding: AppSpacing.allEdgeInsetSpace16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: AppSpacing.space8),
                      Text(
                        AppLocalizations.of(context)!.feedbackSent,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    AppLocalizations.of(context)!.feedbackOverallRating,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < feedback.overallRating
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.starRating,
                        size: 28,
                      );
                    }),
                  ),
                  if (feedback.highlights != null &&
                      feedback.highlights!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space12),
                    Text(
                      AppLocalizations.of(context)!.feedbackHighlights,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(feedback.highlights!),
                  ],
                  if (feedback.lowlights != null &&
                      feedback.lowlights!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space12),
                    Text(
                      AppLocalizations.of(context)!.feedbackLowlights,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(feedback.lowlights!),
                  ],
                  const SizedBox(height: AppSpacing.space12),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.feedbackRecommended,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        feedback.wouldRecommend
                            ? AppLocalizations.of(context)!.feedbackYesLabel
                            : AppLocalizations.of(context)!.feedbackNoLabel,
                      ),
                    ],
                  ),
                  if (feedback.aiExperienceRating != null) ...[
                    const SizedBox(height: AppSpacing.space12),
                    Text(
                      AppLocalizations.of(context)!.feedbackAiRatingLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < feedback.aiExperienceRating!
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.starRating,
                          size: 28,
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          _PostTripSuggestionSection(tripId: tripId, hasSubmitted: true),
        ],
      ),
    );
  }
}

class _PostTripSuggestionSection extends StatelessWidget {
  final String tripId;
  final bool hasSubmitted;

  const _PostTripSuggestionSection({
    required this.tripId,
    required this.hasSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackBloc, FeedbackState>(
      listenWhen: (_, current) => current is PostTripSuggestionPremiumRequired,
      listener: (context, state) {
        PremiumPaywall.show(context);
      },
      builder: (context, state) {
        final showButton =
            hasSubmitted ||
            state is FeedbackSubmitted ||
            state is PostTripSuggestionPremiumRequired;
        if (showButton) {
          return Card(
            color: const Color(0xFFF0F7FF),
            child: Padding(
              padding: AppSpacing.allEdgeInsetSpace16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppLocalizations.of(context)!.feedbackDiscoverText),
                  const SizedBox(height: AppSpacing.space12),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<FeedbackBloc>().add(
                        RequestPostTripSuggestion(),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      AppLocalizations.of(context)!.feedbackDiscoverNextTrip,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is PostTripSuggestionLoading) {
          return const Center(
            child: Padding(
              padding: AppSpacing.allEdgeInsetSpace24,
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }
        if (state is PostTripSuggestionLoaded) {
          return _PostTripSuggestionCard(suggestion: state.suggestion);
        }
        if (state is PostTripSuggestionError) {
          return Card(
            color: const Color(0xFFFFF0F0),
            child: Padding(
              padding: AppSpacing.allEdgeInsetSpace16,
              child: Column(
                children: [
                  Text(
                    toUserFriendlyMessage(
                      state.error,
                      AppLocalizations.of(context)!,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  TextButton.icon(
                    onPressed: () {
                      context.read<FeedbackBloc>().add(
                        RequestPostTripSuggestion(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.retryButton),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PostTripSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;

  const _PostTripSuggestionCard({required this.suggestion});

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

    return Card(
      color: const Color(0xFFF0F7FF),
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.starRating),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  AppLocalizations.of(context)!.postTripNextTrip,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              '$destination, $country',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: [
                Chip(label: Text('$duration jours')),
                const SizedBox(width: AppSpacing.space8),
                Chip(label: Text('$budget\u20ac')),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space8),
              Wrap(
                spacing: AppSpacing.space4,
                runSpacing: AppSpacing.space4,
                children: highlights
                    .map(
                      (h) => Chip(
                        label: Text(h, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

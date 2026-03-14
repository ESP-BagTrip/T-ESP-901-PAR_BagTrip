import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/feedback/bloc/feedback_bloc.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedbackFormView extends StatefulWidget {
  final String tripId;
  final String? currentUserId;
  final List<TripFeedback> feedbacks;

  const FeedbackFormView({
    super.key,
    required this.tripId,
    this.currentUserId,
    this.feedbacks = const [],
  });

  @override
  State<FeedbackFormView> createState() => _FeedbackFormViewState();
}

class _FeedbackFormViewState extends State<FeedbackFormView> {
  int _rating = 3;
  final _highlightsController = TextEditingController();
  final _lowlightsController = TextEditingController();
  bool _wouldRecommend = true;

  @override
  void dispose() {
    _highlightsController.dispose();
    _lowlightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingFeedback =
        widget.currentUserId != null
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
      appBar: AppBar(title: const Text('Donner votre avis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Note globale',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _highlightsController,
              decoration: const InputDecoration(
                labelText: 'Points forts',
                hintText: 'Qu\'avez-vous aime ?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lowlightsController,
              decoration: const InputDecoration(
                labelText: 'Points faibles',
                hintText: 'Qu\'est-ce qui pourrait etre ameliore ?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recommanderiez-vous ce voyage ?'),
              value: _wouldRecommend,
              onChanged: (value) {
                setState(() {
                  _wouldRecommend = value;
                });
              },
            ),
            const SizedBox(height: 24),
            BlocConsumer<FeedbackBloc, FeedbackState>(
              listener: (context, state) {
                if (state is FeedbackSubmitted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Merci pour votre avis !')),
                  );
                } else if (state is FeedbackError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is FeedbackLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ElevatedButton.icon(
                  onPressed: () {
                    context.read<FeedbackBloc>().add(
                      SubmitFeedback(
                        tripId: widget.tripId,
                        overallRating: _rating,
                        highlights:
                            _highlightsController.text.isNotEmpty
                                ? _highlightsController.text
                                : null,
                        lowlights:
                            _lowlightsController.text.isNotEmpty
                                ? _lowlightsController.text
                                : null,
                        wouldRecommend: _wouldRecommend,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer mon avis'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFFF0F7FF),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Votre avis a ete envoye',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Note globale',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < feedback.overallRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      );
                    }),
                  ),
                  if (feedback.highlights != null &&
                      feedback.highlights!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Points forts',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(feedback.highlights!),
                  ],
                  if (feedback.lowlights != null &&
                      feedback.lowlights!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Points faibles',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(feedback.lowlights!),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Recommande : ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(feedback.wouldRecommend ? 'Oui' : 'Non'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
    return BlocBuilder<FeedbackBloc, FeedbackState>(
      builder: (context, state) {
        final showButton = hasSubmitted || state is FeedbackSubmitted;
        if (showButton) {
          return Card(
            color: const Color(0xFFF0F7FF),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Decouvrez votre prochain voyage ideal base sur vos experiences.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final authService = getIt<AuthService>();
                      final user = await authService.getCurrentUser();
                      if (user != null && user.isFree) {
                        if (context.mounted) {
                          PremiumPaywall.show(context);
                        }
                        return;
                      }
                      if (context.mounted) {
                        context.read<FeedbackBloc>().add(
                          RequestPostTripSuggestion(),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Decouvrir mon prochain voyage'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is PostTripSuggestionLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      context.read<FeedbackBloc>().add(
                        RequestPostTripSuggestion(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Votre prochain voyage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$destination, $country',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(label: Text('$duration jours')),
                const SizedBox(width: 8),
                Chip(label: Text('$budget\u20ac')),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    highlights
                        .map(
                          (h) => Chip(
                            label: Text(
                              h,
                              style: const TextStyle(fontSize: 11),
                            ),
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

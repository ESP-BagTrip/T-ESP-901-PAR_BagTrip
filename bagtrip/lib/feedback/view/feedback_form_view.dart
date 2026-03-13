import 'package:bagtrip/feedback/bloc/feedback_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedbackFormView extends StatefulWidget {
  final String tripId;

  const FeedbackFormView({super.key, required this.tripId});

  @override
  State<FeedbackFormView> createState() => _FeedbackFormViewState();
}

class _FeedbackFormViewState extends State<FeedbackFormView> {
  int _rating = 0;
  bool _wouldRecommend = true;
  final _highlightsController = TextEditingController();
  final _lowlightsController = TextEditingController();

  @override
  void dispose() {
    _highlightsController.dispose();
    _lowlightsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Veuillez donner une note')));
      return;
    }
    context.read<FeedbackBloc>().add(
      SubmitFeedback(
        tripId: widget.tripId,
        overallRating: _rating,
        highlights:
            _highlightsController.text.trim().isNotEmpty
                ? _highlightsController.text.trim()
                : null,
        lowlights:
            _lowlightsController.text.trim().isNotEmpty
                ? _lowlightsController.text.trim()
                : null,
        wouldRecommend: _wouldRecommend,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Donnez votre avis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Text('Note globale', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _highlightsController,
            decoration: const InputDecoration(
              labelText: 'Points forts (optionnel)',
              border: OutlineInputBorder(),
              hintText: 'Qu\'avez-vous le plus appr\u00e9ci\u00e9 ?',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lowlightsController,
            decoration: const InputDecoration(
              labelText: '\u00c0 am\u00e9liorer (optionnel)',
              border: OutlineInputBorder(),
              hintText:
                  'Qu\'est-ce qui pourrait \u00eatre am\u00e9lior\u00e9 ?',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Je recommande ce voyage'),
            value: _wouldRecommend,
            onChanged: (value) => setState(() => _wouldRecommend = value),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handleSubmit,
            icon: const Icon(Icons.send),
            label: const Text('Envoyer mon avis'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

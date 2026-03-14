import 'package:bagtrip/feedback/bloc/feedback_bloc.dart';
import 'package:bagtrip/feedback/view/feedback_form_view.dart';
import 'package:bagtrip/feedback/view/feedback_list_view.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedbackPage extends StatelessWidget {
  final String tripId;

  const FeedbackPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FeedbackBloc()..add(LoadFeedbacks(tripId: tripId)),
      child: _FeedbackPageContent(tripId: tripId),
    );
  }
}

class _FeedbackPageContent extends StatefulWidget {
  final String tripId;

  const _FeedbackPageContent({required this.tripId});

  @override
  State<_FeedbackPageContent> createState() => _FeedbackPageContentState();
}

class _FeedbackPageContentState extends State<_FeedbackPageContent> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Avis'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Donner un avis'), Tab(text: 'Tous les avis')],
          ),
        ),
        body: BlocConsumer<FeedbackBloc, FeedbackState>(
          listener: (context, state) {
            if (state is FeedbackSubmitted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Avis envoy\u00e9 avec succ\u00e8s'),
                ),
              );
            }
            if (state is FeedbackError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final feedbacks = state is FeedbackLoaded ? state.feedbacks : [];
            final isLoading = state is FeedbackLoading;

            return TabBarView(
              children: [
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FeedbackFormView(
                      tripId: widget.tripId,
                      currentUserId: _currentUserId,
                      feedbacks: feedbacks.cast(),
                    ),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FeedbackListView(feedbacks: feedbacks.cast()),
              ],
            );
          },
        ),
      ),
    );
  }
}

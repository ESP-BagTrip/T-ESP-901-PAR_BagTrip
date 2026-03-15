import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/feedback/bloc/feedback_bloc.dart';
import 'package:bagtrip/feedback/view/feedback_form_view.dart';
import 'package:bagtrip/feedback/view/feedback_list_view.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
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
    final userResult = await getIt<AuthRepository>().getCurrentUser();
    final user = userResult.dataOrNull;
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
          title: Text(AppLocalizations.of(context)!.feedbackTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.feedbackGiveReview),
              Tab(text: AppLocalizations.of(context)!.feedbackAllReviews),
            ],
          ),
        ),
        body: BlocConsumer<FeedbackBloc, FeedbackState>(
          listener: (context, state) {
            if (state is FeedbackSubmitted) {
              AppSnackBar.showSuccess(
                context,
                message: AppLocalizations.of(context)!.feedbackSent,
              );
            }
            if (state is FeedbackError) {
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
            final feedbacks = state is FeedbackLoaded ? state.feedbacks : [];
            final isLoading = state is FeedbackLoading;

            return TabBarView(
              children: [
                isLoading
                    ? const LoadingView()
                    : FeedbackFormView(
                        tripId: widget.tripId,
                        currentUserId: _currentUserId,
                        feedbacks: feedbacks.cast(),
                      ),
                isLoading
                    ? const LoadingView()
                    : FeedbackListView(feedbacks: feedbacks.cast()),
              ],
            );
          },
        ),
      ),
    );
  }
}

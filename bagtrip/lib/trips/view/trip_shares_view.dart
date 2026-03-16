import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TripSharesView extends StatefulWidget {
  final String tripId;
  final String role;

  const TripSharesView({super.key, required this.tripId, this.role = 'OWNER'});

  @override
  State<TripSharesView> createState() => _TripSharesViewState();
}

class _TripSharesViewState extends State<TripSharesView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleInvite() {
    if (!_formKey.currentState!.validate()) return;
    context.read<TripShareBloc>().add(
      CreateShare(tripId: widget.tripId, email: _emailController.text.trim()),
    );
    _emailController.clear();
  }

  void _handleRevoke(String shareId) {
    showAdaptiveAlertDialog(
      context: context,
      title: AppLocalizations.of(context)!.sharesRevokeTitle,
      content: AppLocalizations.of(context)!.sharesRevokeConfirm,
      confirmLabel: AppLocalizations.of(context)!.sharesRevokeButton,
      cancelLabel: AppLocalizations.of(context)!.cancelButton,
      isDestructive: true,
      onConfirm: () {
        context.read<TripShareBloc>().add(
          DeleteShare(tripId: widget.tripId, shareId: shareId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharesTitle)),
      body: BlocConsumer<TripShareBloc, TripShareState>(
        listener: (context, state) {
          if (state is TripShareError) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(state.error, l10n),
            );
          }
        },
        builder: (context, state) {
          final shares = state is TripShareLoaded
              ? state.shares
              : <TripShare>[];
          final isLoading = state is TripShareLoading;

          if (isLoading) return const LoadingView();

          if (shares.isEmpty) {
            return ElegantEmptyState(
              icon: Icons.people_outline,
              title: l10n.sharesEmpty,
              subtitle: l10n.sharesEmptySubtitle,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shares.length,
            itemBuilder: (context, index) {
              final share = shares[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              share.userFullName ?? share.userEmail,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (share.userFullName != null)
                              Text(
                                share.userEmail,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            Text(
                              'Invit\u00e9 le ${DateFormat('dd/MM/yyyy').format(share.invitedAt ?? DateTime.now())}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (widget.role != 'VIEWER')
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _handleRevoke(share.id),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: widget.role != 'VIEWER'
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            hintText: 'utilisateur@exemple.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Requis';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _handleInvite,
                        icon: const Icon(Icons.person_add),
                        tooltip: l10n.sharesInviteButton,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareInviteSheet extends StatefulWidget {
  final String tripId;

  const ShareInviteSheet({super.key, required this.tripId});

  @override
  State<ShareInviteSheet> createState() => _ShareInviteSheetState();
}

class _ShareInviteSheetState extends State<ShareInviteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRole = 'VIEWER';

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final message = _messageController.text.trim();
    context.read<TripShareBloc>().add(
      CreateShare(
        tripId: widget.tripId,
        email: _emailController.text.trim(),
        message: message.isNotEmpty ? message : null,
        role: _selectedRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<TripShareBloc, TripShareState>(
      listener: (context, state) {
        if (state is TripShareInvitePending) {
          Navigator.of(context).pop();
          AppSnackBar.showSuccess(
            context,
            message: l10n.shareInvitePendingMessage,
          );
          Clipboard.setData(ClipboardData(text: state.inviteToken));
          AppSnackBar.showSuccess(context, message: l10n.shareInviteLinkCopied);
        }
        if (state is TripShareLoaded) {
          Navigator.of(context).pop();
          AppSnackBar.showSuccess(context, message: l10n.shareInviteSuccess);
        }
        if (state is TripShareError) {
          final msg = switch (state.error) {
            NotFoundError() => l10n.shareErrorUserNotFound,
            ValidationError(:final message) when message.contains('already') =>
              l10n.shareErrorAlreadyShared,
            ValidationError(:final message) when message.contains('yourself') =>
              l10n.shareErrorSelfShare,
            _ => state.error.message,
          };
          AppSnackBar.showError(context, message: msg);
        }
        if (state is TripShareQuotaExceeded) {
          AppSnackBar.showError(context, message: l10n.errorQuota);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space16,
            right: AppSpacing.space16,
            top: AppSpacing.space12,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.space24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Title
                Text(
                  l10n.shareInviteTitle,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.shareInviteEmailLabel,
                    hintText: l10n.shareInviteEmailHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.shareInviteEmailRequired;
                    }
                    if (!_emailRegex.hasMatch(value.trim())) {
                      return l10n.shareInviteEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space12),

                // Role picker
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'VIEWER',
                      label: Text(l10n.shareRoleViewer),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    ButtonSegment(
                      value: 'EDITOR',
                      label: Text(l10n.shareRoleEditor),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (roles) =>
                      setState(() => _selectedRole = roles.first),
                ),
                const SizedBox(height: AppSpacing.space12),

                // Message field
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.shareInviteMessageLabel,
                    hintText: l10n.shareInviteMessageHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.message_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Send button
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.shareInviteSendButton),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

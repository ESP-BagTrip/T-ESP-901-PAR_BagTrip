import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/design/widgets/form/micro_label_field.dart';
import 'package:bagtrip/design/widgets/form/pill_segmented_control.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareInviteSheet extends StatefulWidget {
  final String tripId;

  final void Function({
    required String email,
    required String role,
    String? message,
  })?
  onSubmit;

  const ShareInviteSheet({super.key, required this.tripId, this.onSubmit});

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
    if (widget.onSubmit != null) {
      widget.onSubmit!(
        email: _emailController.text.trim(),
        role: _selectedRole,
        message: message.isNotEmpty ? message : null,
      );
      Navigator.of(context).pop();
      return;
    }
    context.read<TripShareBloc>().add(
      CreateShare(
        tripId: widget.tripId,
        email: _emailController.text.trim(),
        message: message.isNotEmpty ? message : null,
        role: _selectedRole,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: ItemFormScaffold(
        title: l10n.shareInviteTitle,
        fields: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FormSectionHeader(
              label: l10n.shareInviteEmailLabel,
              icon: Icons.mail_outline,
            ),
            MicroLabelField(
              label: l10n.shareInviteEmailLabel,
              controller: _emailController,
              hint: l10n.shareInviteEmailHint,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 18,
                color: ColorName.hint,
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
            const SizedBox(height: AppSpacing.space24),
            FormSectionHeader(
              label: l10n.shareRoleViewer,
              icon: Icons.admin_panel_settings_outlined,
            ),
            PillSegmentedControl<String>(
              value: _selectedRole,
              onChanged: (r) => setState(() => _selectedRole = r),
              segments: [
                PillSegmentOption(
                  value: 'VIEWER',
                  label: l10n.shareRoleViewer,
                  icon: Icons.visibility_outlined,
                ),
                PillSegmentOption(
                  value: 'EDITOR',
                  label: l10n.shareRoleEditor,
                  icon: Icons.edit_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),
            FormSectionHeader(
              label: l10n.shareInviteMessageLabel,
              icon: Icons.chat_bubble_outline,
            ),
            MicroLabelField(
              label: l10n.notesLabel,
              controller: _messageController,
              hint: l10n.shareInviteMessageHint,
              maxLines: 3,
              prefixIcon: const Icon(
                Icons.message_outlined,
                size: 18,
                color: ColorName.hint,
              ),
            ),
          ],
        ),
        actions: [
          ItemFormPrimaryButton(
            label: l10n.shareInviteSendButton,
            icon: Icons.person_add,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = _buildForm(context);

    if (widget.onSubmit != null) return form;

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
          Navigator.of(context).pop();
          PremiumPaywall.show(context);
        }
      },
      child: form,
    );
  }
}

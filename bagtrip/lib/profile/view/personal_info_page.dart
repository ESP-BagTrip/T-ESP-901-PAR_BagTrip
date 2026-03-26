import 'package:bagtrip/components/adaptive/adaptive_edit_dialog.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/widgets/personal_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.personalInfoPageTitle)),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          if (state is! UserProfileLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: PersonalInfoSection(
              name: state.name,
              email: state.email,
              phone: state.phone,
              onEditName: () => _editName(context, state, l10n),
              onEditPhone: () => _editPhone(context, state, l10n),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    UserProfileLoaded state,
    AppLocalizations l10n,
  ) async {
    final currentName = state.name == state.email ? '' : state.name;
    final newName = await showAdaptiveEditDialog(
      context: context,
      title: l10n.editNameTitle,
      currentValue: currentName,
      confirmLabel: l10n.saveButton,
      cancelLabel: l10n.cancelButton,
      placeholder: l10n.nameLabel,
    );
    if (newName != null && newName.trim().isNotEmpty && context.mounted) {
      context.read<UserProfileBloc>().add(UpdateUserName(newName.trim()));
    }
  }

  Future<void> _editPhone(
    BuildContext context,
    UserProfileLoaded state,
    AppLocalizations l10n,
  ) async {
    final currentPhone = state.phone == '—' ? '' : state.phone;
    final newPhone = await showAdaptiveEditDialog(
      context: context,
      title: l10n.editPhoneTitle,
      currentValue: currentPhone,
      confirmLabel: l10n.saveButton,
      cancelLabel: l10n.cancelButton,
      placeholder: l10n.phoneLabel,
      keyboardType: TextInputType.phone,
    );
    if (newPhone != null && newPhone.trim().isNotEmpty && context.mounted) {
      context.read<UserProfileBloc>().add(UpdateUserPhone(newPhone.trim()));
    }
  }
}

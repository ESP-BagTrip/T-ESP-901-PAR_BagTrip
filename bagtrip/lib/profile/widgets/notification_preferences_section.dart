import 'package:bagtrip/components/adaptive/adaptive_indicator.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/notification_preferences.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:bagtrip/settings/cubit/notification_preferences_cubit.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Notifications preferences card for the Settings page.
///
/// Wraps its own [NotificationPreferencesCubit] (loaded on init) and renders a
/// master "push" switch plus per-channel switches. When push is off the
/// sub-toggles are disabled (greyed out).
class NotificationPreferencesSection extends StatelessWidget {
  const NotificationPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationPreferencesCubit>(
      create: (_) => NotificationPreferencesCubit()..load(),
      child: const _NotificationPreferencesView(),
    );
  }
}

class _NotificationPreferencesView extends StatelessWidget {
  const _NotificationPreferencesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<
      NotificationPreferencesCubit,
      NotificationPreferencesState
    >(
      listenWhen: (prev, curr) =>
          curr is NotificationPreferencesLoaded && curr.operationError != null,
      listener: (context, state) {
        final error = (state as NotificationPreferencesLoaded).operationError!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(toUserFriendlyMessage(error, l10n))),
        );
      },
      builder: (context, state) {
        return ProfileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: ColorName.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    l10n.notificationPrefsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              _buildBody(context, state, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationPreferencesState state,
    AppLocalizations l10n,
  ) {
    return switch (state) {
      NotificationPreferencesError() => Padding(
        padding: AppSpacing.verticalSpace16,
        child: Text(
          l10n.notificationPrefsLoadError,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
      NotificationPreferencesLoaded(:final preferences) => _buildSwitches(
        context,
        preferences,
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.space24),
        child: Center(child: AdaptiveIndicator()),
      ),
    };
  }

  Widget _buildSwitches(BuildContext context, NotificationPreferences prefs) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NotificationPreferencesCubit>();
    final subEnabled = prefs.pushEnabled;

    return Column(
      children: [
        _tile(
          context,
          label: l10n.notificationPrefsPush,
          value: prefs.pushEnabled,
          enabled: true,
          onChanged: (v) =>
              cubit.toggle(NotificationPreferenceField.pushEnabled, v),
        ),
        const Divider(height: 1),
        _tile(
          context,
          label: l10n.notificationPrefsFlightReminders,
          value: prefs.flightReminders,
          enabled: subEnabled,
          onChanged: (v) =>
              cubit.toggle(NotificationPreferenceField.flightReminders, v),
        ),
        _tile(
          context,
          label: l10n.notificationPrefsActivityReminders,
          value: prefs.activityReminders,
          enabled: subEnabled,
          onChanged: (v) =>
              cubit.toggle(NotificationPreferenceField.activityReminders, v),
        ),
        _tile(
          context,
          label: l10n.notificationPrefsTripUpdates,
          value: prefs.tripUpdates,
          enabled: subEnabled,
          onChanged: (v) =>
              cubit.toggle(NotificationPreferenceField.tripUpdates, v),
        ),
        _tile(
          context,
          label: l10n.notificationPrefsBudgetAlerts,
          value: prefs.budgetAlerts,
          enabled: subEnabled,
          onChanged: (v) =>
              cubit.toggle(NotificationPreferenceField.budgetAlerts, v),
        ),
        _tile(
          context,
          label: l10n.notificationPrefsSocial,
          value: prefs.social,
          enabled: subEnabled,
          onChanged: (v) => cubit.toggle(NotificationPreferenceField.social, v),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required String label,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: enabled ? onSurface : onSurface.withValues(alpha: 0.4),
        ),
      ),
      value: enabled && value,
      activeThumbColor: ColorName.secondary,
      onChanged: enabled ? onChanged : null,
    );
  }
}

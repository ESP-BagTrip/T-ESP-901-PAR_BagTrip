import 'package:bagtrip/components/adaptive/adaptive_indicator.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/settings/settings_style.dart';
import 'package:bagtrip/models/notification_preferences.dart';
import 'package:bagtrip/profile/widgets/profile_menu_group_card.dart';
import 'package:bagtrip/profile/widgets/settings/settings_switch_row.dart';
import 'package:bagtrip/settings/cubit/notification_preferences_cubit.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Notifications preferences card for the Settings page.
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

  static const _rowPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space16,
    vertical: AppSpacing.space12,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormSectionHeader(
              label: l10n.notificationPrefsTitle,
              icon: Icons.notifications_outlined,
            ),
            ProfileMenuGroupCard(children: _cardChildren(context, state, l10n)),
          ],
        );
      },
    );
  }

  List<Widget> _cardChildren(
    BuildContext context,
    NotificationPreferencesState state,
    AppLocalizations l10n,
  ) {
    return switch (state) {
      NotificationPreferencesError() => [
        Padding(
          padding: _rowPadding,
          child: Text(
            l10n.notificationPrefsLoadError,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
      NotificationPreferencesLoaded(:final preferences) => _switchRows(
        context,
        preferences,
      ),
      _ => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space16),
          child: Center(child: AdaptiveIndicator()),
        ),
      ],
    };
  }

  List<Widget> _switchRows(
    BuildContext context,
    NotificationPreferences prefs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NotificationPreferencesCubit>();
    final subEnabled = prefs.pushEnabled;

    return [
      SettingsSwitchRow(
        icon: Icons.notifications_outlined,
        iconColor: SettingsStyle.iconAccentSecondary(),
        title: l10n.notificationPrefsPush,
        subtitle: l10n.notificationPrefsPushSubtitle,
        value: prefs.pushEnabled,
        onChanged: (v) =>
            cubit.toggle(NotificationPreferenceField.pushEnabled, v),
      ),
      SettingsSwitchRow(
        icon: Icons.flight_outlined,
        iconColor: SettingsStyle.iconAccentSecondary(),
        title: l10n.notificationPrefsFlightReminders,
        subtitle: l10n.notificationPrefsFlightRemindersSubtitle,
        value: subEnabled && prefs.flightReminders,
        enabled: subEnabled,
        onChanged: subEnabled
            ? (v) =>
                  cubit.toggle(NotificationPreferenceField.flightReminders, v)
            : null,
      ),
      SettingsSwitchRow(
        icon: Icons.event_note_outlined,
        iconColor: SettingsStyle.iconAccentSecondary(),
        title: l10n.notificationPrefsActivityReminders,
        subtitle: l10n.notificationPrefsActivityRemindersSubtitle,
        value: subEnabled && prefs.activityReminders,
        enabled: subEnabled,
        onChanged: subEnabled
            ? (v) =>
                  cubit.toggle(NotificationPreferenceField.activityReminders, v)
            : null,
      ),
      SettingsSwitchRow(
        icon: Icons.luggage_outlined,
        iconColor: SettingsStyle.iconAccentSecondary(),
        title: l10n.notificationPrefsTripUpdates,
        subtitle: l10n.notificationPrefsTripUpdatesSubtitle,
        value: subEnabled && prefs.tripUpdates,
        enabled: subEnabled,
        onChanged: subEnabled
            ? (v) => cubit.toggle(NotificationPreferenceField.tripUpdates, v)
            : null,
      ),
      SettingsSwitchRow(
        icon: Icons.attach_money_outlined,
        iconColor: SettingsStyle.iconAccentWarning(),
        title: l10n.notificationPrefsBudgetAlerts,
        subtitle: l10n.notificationPrefsBudgetAlertsSubtitle,
        value: subEnabled && prefs.budgetAlerts,
        enabled: subEnabled,
        onChanged: subEnabled
            ? (v) => cubit.toggle(NotificationPreferenceField.budgetAlerts, v)
            : null,
      ),
      SettingsSwitchRow(
        icon: Icons.people_outline,
        iconColor: SettingsStyle.iconAccentMuted(),
        title: l10n.notificationPrefsSocial,
        subtitle: l10n.notificationPrefsSocialSubtitle,
        value: subEnabled && prefs.social,
        enabled: subEnabled,
        onChanged: subEnabled
            ? (v) => cubit.toggle(NotificationPreferenceField.social, v)
            : null,
      ),
    ];
  }
}

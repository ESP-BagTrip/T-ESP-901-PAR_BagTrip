import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/pages/travelers_page.dart';
import 'package:bagtrip/service/conversation_service.dart';
import 'package:bagtrip/service/trip_service.dart';
import 'package:bagtrip/utils/error_display.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tripService = TripService();
  final _conversationService = ConversationService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer le trip
      final trip = await _tripService.createTrip(
        title: _titleController.text.trim(),
      );

      // Préparer le titre de la conversation avant l'appel asynchrone
      if (!mounted) return;
      final localizations = AppLocalizations.of(context)!;
      final conversationTitle = localizations.planningTitle(
        trip.title ?? 'Voyage',
      );

      // Créer la conversation associée
      final conversation = await _conversationService.createConversation(
        trip.id,
        title: conversationTitle,
      );

      // Navigation vers TravelersPage
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => TravelersPage(
                  tripId: trip.id,
                  conversationId: conversation.id,
                ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        AppSnackBar.showError(context, message: toUserFriendlyMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.newTrip)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.createYourTrip,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.nameTripToStart,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.hint),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.tripNameLabel,
                    hintText: AppLocalizations.of(context)!.tripNameHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.flight_takeoff),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom pour votre voyage';
                    }
                    if (value.trim().length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(AppLocalizations.of(context)!.continueButton),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

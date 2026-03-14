import 'package:bagtrip/core/app_error.dart';

/// Returns a short, user-friendly error message suitable for the toaster.
String toUserFriendlyMessage(AppError error) {
  return switch (error) {
    NetworkError() => 'Erreur de connexion. Vérifiez votre connexion internet.',
    AuthenticationError() => 'Identifiants incorrects ou session expirée.',
    ForbiddenError() => 'Accès refusé.',
    NotFoundError() => 'Ressource non trouvée.',
    ValidationError(:final message)
        when message.isNotEmpty && message.length <= 120 =>
      message,
    ValidationError() => 'Requête invalide.',
    QuotaExceededError() => 'Limite atteinte. Passez à Premium pour continuer.',
    StaleContextError() => 'Le contexte a été mis à jour. Veuillez rafraîchir.',
    ServerError() => 'Erreur serveur. Veuillez réessayer plus tard.',
    RateLimitError() => 'Trop de requêtes. Veuillez patienter.',
    CancelledError() => 'Opération annulée.',
    UnknownError() => 'Une erreur est survenue. Veuillez réessayer.',
  };
}

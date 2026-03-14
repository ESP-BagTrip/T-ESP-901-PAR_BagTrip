import 'package:dio/dio.dart';

/// Generic message when we must hide technical details.
const String _kGenericMessage = 'Une erreur est survenue. Veuillez réessayer.';

/// Max length for user-visible error message.
const int _kMaxMessageLength = 120;

/// Technical patterns that indicate we should show the generic message.
const List<String> _kTechnicalPatterns = [
  'DioException',
  'Error during login:',
  'Error during registration:',
  'Failed to parse',
  'Exception:',
  ' at ',
  'stack trace',
  '#0 ',
  'Response data:',
];

/// HTTP status code to short user message (code + description).
int? _getStatusCodeFromDio(DioException e) {
  return e.response?.statusCode;
}

String _messageForStatusCode(int statusCode, [dynamic data]) {
  final detail = data is Map ? data['detail'] : null;
  final String detailStr = detail is String ? detail : '';
  final String short;
  switch (statusCode) {
    case 400:
      short = _isShortUserFriendly(detailStr) ? detailStr : 'Requête invalide';
      break;
    case 401:
      short = 'Identifiants incorrects';
      break;
    case 403:
      short = 'Accès refusé';
      break;
    case 404:
      short = 'Ressource non trouvée';
      break;
    case 409:
      if (data is Map && data['error'] == 'stale_context') {
        short = 'Le contexte a été mis à jour. Veuillez rafraîchir.';
      } else {
        short = _isShortUserFriendly(detailStr)
            ? detailStr
            : 'Conflit (ex. compte déjà existant)';
      }
      break;
    case 402:
      short = 'Limite atteinte. Passez à Premium pour continuer.';
      break;
    case 429:
      short = 'Trop de requêtes. Veuillez patienter.';
      break;
    case 500:
      short = 'Erreur serveur. Veuillez réessayer plus tard.';
      break;
    default:
      short = _isShortUserFriendly(detailStr)
          ? detailStr
          : 'Une erreur est survenue';
  }
  return 'Code $statusCode — $short';
}

bool _isShortUserFriendly(dynamic value) {
  if (value is! String) return false;
  if (value.length > 80) return false;
  final lower = value.toLowerCase();
  if (_kTechnicalPatterns.any((p) => lower.contains(p.toLowerCase()))) {
    return false;
  }
  return true;
}

bool _looksTechnical(String message) {
  if (message.length > _kMaxMessageLength) return true;
  final lower = message.toLowerCase();
  return _kTechnicalPatterns.any((p) => lower.contains(p.toLowerCase()));
}

String _sanitizeMessage(String message) {
  String cleaned = message.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  if (cleaned.isEmpty) return _kGenericMessage;
  if (_looksTechnical(cleaned)) return _kGenericMessage;
  if (cleaned.length > _kMaxMessageLength) {
    return '${cleaned.substring(0, _kMaxMessageLength)}…';
  }
  return cleaned;
}

/// Returns a short, user-friendly error message suitable for the toaster.
/// Hides technical details and uses "Code XXX — Description" for API errors when possible.
String toUserFriendlyMessage(Object? error) {
  if (error == null) return _kGenericMessage;

  if (error is DioException) {
    final statusCode = _getStatusCodeFromDio(error);
    if (statusCode != null) {
      final data = error.response?.data;
      return _messageForStatusCode(statusCode, data);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Code 0 — Timeout. Vérifiez votre connexion internet.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Code 0 — Erreur de connexion. Vérifiez votre connexion internet.';
    }
    final fallback = error.error?.toString();
    if (fallback != null && _isShortUserFriendly(fallback)) {
      return fallback;
    }
    return _kGenericMessage;
  }

  if (error is Exception) {
    return _sanitizeMessage(error.toString());
  }

  final str = error.toString();
  if (str.isEmpty) return _kGenericMessage;
  return _sanitizeMessage(str);
}

import 'package:dio/dio.dart';
import '../localization/generated/app_localizations.dart';

String errorMessage(Object error, AppLocalizations l) {
  if (error is DioException) {
    final body = error.response?.data;
    final detail = body is Map ? body['error'] : null;
    final code = detail is Map ? detail['code'] : null;
    return switch (code) {
      'invalid_credentials' => l.invalidCredentials,
      'email_unavailable' => l.emailUnavailable,
      'already_confirmed' => l.alreadyConfirmed,
      'review_required' => l.reviewRequired,
      'invalid_token' ||
      'authentication_required' ||
      'invalid_refresh' => l.loginRequired,
      'rate_limited' => l.rateLimited,
      'validation_error' => l.checkFields,
      'file_too_large' => l.fileTooLarge,
      'invalid_status' || 'invalid_transition' => l.invalidStatus,
      _ => error.response == null ? l.networkError : l.serverError,
    };
  }
  return l.actionError;
}

import 'package:dio/dio.dart';
import '../localization/generated/app_localizations.dart';

String publicationMessage(String code, AppLocalizations l) => switch (code) {
  'invalid_category' => l.invalidCategory,
  'idempotency_conflict' => l.publicationConflict,
  'upload_already_used' => l.uploadAlreadyUsed,
  'publication_cancelled' => l.publicationCancelled,
  'review_required' ||
  'duplicate_upload' ||
  'redaction_required' => l.checkFields,
  _ => l.publicationUnknown,
};

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
      'invalid_category' => l.invalidCategory,
      'idempotency_conflict' => l.publicationConflict,
      'upload_already_used' => l.uploadAlreadyUsed,
      'publication_cancelled' => l.publicationCancelled,
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

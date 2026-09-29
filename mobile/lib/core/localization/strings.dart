import 'package:flutter/material.dart';
import 'generated/app_localizations.dart';
export 'generated/app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  String statusLabel(String status) => switch (status) {
    'published' => l.published,
    'under_review' => l.underReview,
    'accepted' => l.accepted,
    'in_progress' => l.inProgress,
    'resolved_pending_confirmation' => l.resolvedPending,
    'resolved' => l.resolved,
    'rejected' => l.rejected,
    'still_exists' => l.stillExists,
    'partially_resolved' => l.partiallyResolved,
    _ => status,
  };
}

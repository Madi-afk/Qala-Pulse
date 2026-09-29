// Freezed forwards factory annotations to its generated implementation classes.
// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AppUser({
    required String id,
    required String email,
    required String displayName,
    @Default('ru') String preferredLanguage,
    @Default('citizen') String role,
  }) = _AppUser;
  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}

@freezed
abstract class IncidentCategory with _$IncidentCategory {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory IncidentCategory({
    required String id,
    required String code,
    required String nameRu,
    required String nameKk,
    required String description,
    required int baseSeverity,
    required String icon,
    required String color,
    @Default(true) bool isActive,
  }) = _IncidentCategory;
  factory IncidentCategory.fromJson(Map<String, dynamic> json) =>
      _$IncidentCategoryFromJson(json);
}

@freezed
abstract class Incident with _$Incident {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Incident({
    required String id,
    required String authorId,
    required String categoryId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required int severity,
    required double priorityScore,
    required String status,
    required int confirmationCount,
    required DateTime createdAt,
    @Default('') String address,
    @Default('citizen') String source,
    @Default([]) List<Map<String, dynamic>> media,
    @Default({}) Map<String, dynamic> priorityExplanation,
    double? aiConfidence,
    String? aiExplanation,
  }) = _Incident;
  factory Incident.fromJson(Map<String, dynamic> json) =>
      _$IncidentFromJson(json);
}

@freezed
abstract class IncidentDraft with _$IncidentDraft {
  const factory IncidentDraft({
    required String key,
    String? photoPath,
    String? photoBase64,
    String? uploadId,
    double? latitude,
    double? longitude,
    @Default('') String description,
    @Default('') String title,
    @Default('other') String categoryId,
    @Default(3) int severity,
    @Default('') String address,
    @Default(0) int step,
    @Default(false) bool reviewed,
    @Default(false) bool cloudConsent,
    @Default(false) bool waitingToSend,
    @Default('') String audioPath,
    String? audioUploadId,
    Map<String, dynamic>? analysis,
    Map<String, dynamic>? pendingPayload,
    String? publicationError,
  }) = _IncidentDraft;
  factory IncidentDraft.fromJson(Map<String, dynamic> json) =>
      _$IncidentDraftFromJson(json);
}
